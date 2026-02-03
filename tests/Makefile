# Makefile for Omada Ansible Test Suite

.PHONY: help setup test test-all teardown clean

help:
	@echo "Omada Ansible Test Suite"
	@echo ""
	@echo "Available targets:"
	@echo "  make setup     - Start test environment"
	@echo "  make test      - Run all tests"
	@echo "  make test-01   - Run controller auth test"
	@echo "  make test-02   - Run VLAN test"
	@echo "  make test-03   - Run DHCP test"
	@echo "  make test-04   - Run WiFi test"
	@echo "  make test-05   - Run IP Groups test"
	@echo "  make test-06   - Run Firewall test"
	@echo "  make test-07   - Run mDNS test"
	@echo "  make test-08   - Run Port Forward test"
	@echo "  make test-99   - Run full integration test"
	@echo "  make teardown  - Stop test environment"
	@echo "  make clean     - Stop and remove all data"
	@echo ""

setup:
	./setup-test-env.sh

test: test-all

test-all:
	./run-all-tests.sh

test-01:
	./run-test.sh 01

test-02:
	./run-test.sh 02

test-03:
	./run-test.sh 03

test-04:
	./run-test.sh 04

test-05:
	./run-test.sh 05

test-06:
	./run-test.sh 06

test-07:
	./run-test.sh 07

test-08:
	./run-test.sh 08

test-99:
	./run-test.sh 99

teardown:
	./teardown-test-env.sh

clean:
	./teardown-test-env.sh --clean

logs:
	docker-compose logs -f omada-controller
