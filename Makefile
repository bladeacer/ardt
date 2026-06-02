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
	@echo '  release  Tag, update Alire index, and push. Use VERSION=x.y.z to set custom version'
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
	@if [ -n "$(VERSION)" ]; then \
		version="$(VERSION)"; \
		sed -i 's/^version = ".*"/version = "'$$version'"/' alire.toml; \
		commit=$$(git rev-parse HEAD); \
		index_file="index/ad/ada_crdt/ada_crdt-$$version.toml"; \
		if [ ! -f "$$index_file" ]; then \
			cp index/ad/ada_crdt/ada_crdt-0.1.0-dev.toml "$$index_file"; \
		fi; \
		sed -i 's/^version = ".*"/version = "'$$version'"/' "$$index_file"; \
		sed -i 's/^commit = ".*"/commit = "'$$commit'"/' "$$index_file"; \
		git add alire.toml "$$index_file"; \
		git commit -m "Release $$version"; \
		git tag -a "v$$version" -m "Release $$version"; \
		echo "Tagged v$$version at $$commit"; \
	else \
		if ! git diff --quiet HEAD; then echo "Error: working tree not clean"; exit 1; fi; \
		version=$$(sed -n 's/^version = "\(.*\)"/\1/p' alire.toml); \
		commit=$$(git rev-parse HEAD); \
		git tag -a "v$$version" -m "Release $$version"; \
		echo "Tagged v$$version at $$commit"; \
	fi; \
	git push origin --tags; \
	echo "Pushed all tags to origin"

clean:
	alr clean
	rm -rf obj/ lib/ docs/
