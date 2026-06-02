.PHONY: help all build run test prove doc clean

.DEFAULT_GOAL := help

help:
	@echo 'Ada_CRDT - CRDT library for Ada/SPARK'
	@echo ''
	@echo 'Usage: make <target>'
	@echo ''
	@echo '  build   Build the project and tests (alr build)'
	@echo '  run     Build and run tests'
	@echo '  test    Alias for run'
	@echo '  prove   Run SPARK proofs (alr gnatprove)'
	@echo '  doc     Generate HTML documentation (gnatdoc)'
	@echo '  clean   Remove build artifacts'
	@echo '  help    Show this message'

build:
	alr build

run: build
	alr run

test: run

prove:
	alr gnatprove

doc:
	gnatdoc -P ada_crdt.gpr --output-dir=docs --front-end

clean:
	alr clean
	rm -rf obj/ docs/
