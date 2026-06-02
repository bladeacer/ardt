.PHONY: help all build run test prove doc api-docs clean release

.DEFAULT_GOAL := help

help:
	@echo 'Ada_CRDT - CRDT library for Ada/SPARK'
	@echo ''
	@echo 'Usage: make <target>'
	@echo ''
	@echo '  build    Build the project and tests (alr build)'
	@echo '  run      Build and run tests'
	@echo '  test     Alias for run'
	@echo '  prove    Run SPARK proofs (alr gnatprove)'
	@echo '  doc      Generate Markdown API docs (docs/api-docs/)'
	@echo '  release  Tag current version and update Alire index'
	@echo '  clean    Remove build artifacts'
	@echo '  help     Show this message'

build:
	alr build

run: build
	alr run

test: run

prove:
	alr gnatprove

doc: api-docs

api-docs:
	mkdir -p obj
	alr exec -- gnatdoc -P ada_crdt.gpr --backend=rst --output-dir=obj/gnatdoc-rst
	python3 tools/rst2md.py obj/gnatdoc-rst docs/api-docs

release:
	@if ! git diff --quiet HEAD; then echo "Error: working tree not clean"; exit 1; fi; \
	version=$$(sed -n 's/^version = "\(.*\)"/\1/p' alire.toml); \
	commit=$$(git rev-parse HEAD); \
	tag="v$$version"; \
	git tag -a "$$tag" -m "Release $$version"; \
	sed -i "s/^commit = \".*\"/commit = \"$$commit\"/" "index/ad/ada_crdt/ada_crdt-$$version.toml"; \
	echo "Tagged $$tag at $$commit"; \
	echo "Push with: git push origin $$tag"

clean:
	alr clean
	rm -rf obj/ lib/ docs/
