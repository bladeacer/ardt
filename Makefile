.PHONY: help all build run test prove clean

.DEFAULT_GOAL := help

help:
	@echo 'ardt - CRDT library for Ada/SPARK'
	@echo ''
	@echo 'Usage: make <target>'
	@echo ''
	@echo '  build   Build the project and tests (alr build)'
	@echo '  run     Build and run tests'
	@echo '  test    Alias for run'
	@echo '  prove   Run SPARK proofs (alr gnatprove)'
	@echo '  clean   Remove build artifacts'
	@echo '  help    Show this message'

build:
	alr build

run: build
	alr run

test: run

prove:
	alr gnatprove

clean:
	alr clean
	rm -rf obj/
