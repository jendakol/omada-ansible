#!/bin/bash
# Run all enhanced tests (02-08) with optional random order and iterations
#
# Usage:
#   ./run-all-tests.sh                    # Run tests in order once
#   ./run-all-tests.sh --random           # Run tests in random order once
#   ./run-all-tests.sh --random --iterations 3   # Run tests in random order 3 times

# Don't use set -e - we want to handle errors explicitly
set -u  # Exit on undefined variables
set -o pipefail  # Catch errors in pipes

cd "$(dirname "$0")/.."

# Default values
RANDOM_ORDER=false
ITERATIONS=1
VERBOSE=false
LOG_FILE=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -r|--random)
            RANDOM_ORDER=true
            shift
            ;;
        -i|--iterations)
            ITERATIONS="$2"
            shift 2
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -l|--log)
            LOG_FILE="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Run all enhanced tests with optional random order."
            echo ""
            echo "Options:"
            echo "  -r, --random              Run tests in random order"
            echo "  -i, --iterations N        Run tests N times (default: 1)"
            echo "  -v, --verbose             Show test output"
            echo "  -l, --log FILE            Write detailed log to FILE"
            echo "  -h, --help                Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0                        # Run tests in order once"
            echo "  $0 --random               # Run tests in random order once"
            echo "  $0 --random -i 3          # Run tests in random order 3 times"
            echo "  $0 --log test.log         # Save detailed log to file"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Test suite
# Note: DHCP test removed - reservations now auto-generated from infra_devices.yml
TESTS=(infra_networks wireless_ssids security_ip_groups security_firewall services_multicast nat_port_forward)

# Setup logging
if [ -n "$LOG_FILE" ]; then
    exec > >(tee -a "$LOG_FILE") 2>&1
    echo "=== Test run started at $(date) ===" >> "$LOG_FILE"
fi

echo "=========================================="
echo "Enhanced Test Runner"
echo "=========================================="
echo "Tests: ${TESTS[*]}"
echo "Order: $([ "$RANDOM_ORDER" = true ] && echo "RANDOM" || echo "SEQUENTIAL")"
echo "Iterations: $ITERATIONS"
if [ -n "$LOG_FILE" ]; then
    echo "Log file: $LOG_FILE"
fi
echo "=========================================="
echo ""

# Track results
declare -a ALL_FAILED_TESTS
declare -a ALL_FAILED_ITERATIONS
TOTAL_TESTS=0
TOTAL_PASSED=0
TOTAL_FAILED=0

# Run iterations
for iteration in $(seq 1 $ITERATIONS); do
    if [ $ITERATIONS -gt 1 ]; then
        echo "=========================================="
        echo "ITERATION $iteration/$ITERATIONS"
        echo "=========================================="
    fi

    # Get test order
    if [ "$RANDOM_ORDER" = true ]; then
        TEST_ORDER=($(printf '%s\n' "${TESTS[@]}" | shuf))
        echo "Order: ${TEST_ORDER[*]}"
    else
        TEST_ORDER=("${TESTS[@]}")
    fi
    echo ""

    # Run each test
    for test in "${TEST_ORDER[@]}"; do
        echo -n "Test $test: "
        TOTAL_TESTS=$((TOTAL_TESTS + 1))

        # Cleanup and setup before each test
        if [ "$VERBOSE" = true ]; then
            echo ""
            echo "  Cleaning up test site..."
            echo "yes" | ./tests/cleanup-test-site.sh || echo "  Warning: Cleanup failed (may be expected if site doesn't exist)"
            echo "  Setting up test site..."
            ./tests/setup-test-site.sh || { echo "  ERROR: Setup failed!"; exit 1; }
            echo "  Running test..."
        else
            echo "yes" | ./tests/cleanup-test-site.sh >/dev/null 2>&1 || true  # Ignore cleanup failures
            ./tests/setup-test-site.sh >/dev/null 2>&1 || { echo " ❌ SETUP FAILED"; TOTAL_FAILED=$((TOTAL_FAILED + 1)); ALL_FAILED_TESTS+=("$test (setup)"); ALL_FAILED_ITERATIONS+=("$iteration"); continue; }
        fi

        # Run test with timeout
        if [ "$VERBOSE" = true ] || [ -n "$LOG_FILE" ]; then
            timeout 600 ./tests/run-test.sh $test
            exit_code=$?
        else
            timeout 600 ./tests/run-test.sh $test >/dev/null 2>&1
            exit_code=$?
        fi

        if [ $exit_code -eq 0 ]; then
            echo "✅ PASSED"
            TOTAL_PASSED=$((TOTAL_PASSED + 1))
        elif [ $exit_code -eq 124 ]; then
            echo "❌ FAILED (TIMEOUT after 600s)"
            TOTAL_FAILED=$((TOTAL_FAILED + 1))
            ALL_FAILED_TESTS+=("$test")
            ALL_FAILED_ITERATIONS+=("$iteration")
        elif [ $exit_code -eq 130 ]; then
            echo "❌ INTERRUPTED (Ctrl+C)"
            echo "Test run interrupted by user"
            exit 130
        else
            echo "❌ FAILED (exit code: $exit_code)"
            TOTAL_FAILED=$((TOTAL_FAILED + 1))
            ALL_FAILED_TESTS+=("$test")
            ALL_FAILED_ITERATIONS+=("$iteration")

            # Try to show last error if not verbose
            if [ "$VERBOSE" = false ] && [ -z "$LOG_FILE" ]; then
                echo "  Tip: Run with --verbose or --log to see detailed error output"
            fi
        fi
    done

    if [ $ITERATIONS -gt 1 ]; then
        echo ""
    fi
done

echo "=========================================="
echo "FINAL RESULTS"
echo "=========================================="
echo "Total executions: $TOTAL_TESTS"
echo "Passed: $TOTAL_PASSED ✅"
echo "Failed: $TOTAL_FAILED ❌"
echo "Success rate: $(awk "BEGIN {printf \"%.1f\", ($TOTAL_PASSED/$TOTAL_TESTS)*100}")%"
echo ""

if [ $TOTAL_FAILED -eq 0 ]; then
    if [ $ITERATIONS -gt 1 ]; then
        echo "✅ ALL TESTS PASSED in all $ITERATIONS iterations!"
        echo "Tests are truly independent and idempotent."
    else
        echo "✅ ALL TESTS PASSED!"
    fi
    exit 0
else
    echo "❌ FAILURES DETECTED:"
    for i in "${!ALL_FAILED_TESTS[@]}"; do
        if [ $ITERATIONS -gt 1 ]; then
            echo "  - Test ${ALL_FAILED_TESTS[$i]} failed in iteration ${ALL_FAILED_ITERATIONS[$i]}"
        else
            echo "  - Test ${ALL_FAILED_TESTS[$i]}"
        fi
    done
    exit 1
fi
