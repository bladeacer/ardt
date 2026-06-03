.PHONY: help all build run test prove doc api-docs clean release demo

.DEFAULT_GOAL := help

help:
	@echo 'CRDT - CRDT library for Ada/SPARK'
	@echo ''
	@echo 'Usage: make <target>'
	@echo ''
	@echo '  build    Build the project and tests (alr build)'
	@echo '  run      Build and run tests'
	@echo '  test     Alias for run'
	@echo '  prove    Run SPARK proofs (alr gnatprove)'
	@echo '  doc      Generate Markdown API docs (docs/api-docs/)'
	@echo '  release  Tag, update index+releases (Codeberg URL), push. Use VERSION=x.y.z'
	@echo '  demo     Build and run the Game of Life demo'
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
	alr exec -- gnatdoc -P crdt.gpr --backend=rst --output-dir=obj/gnatdoc-rst
	python3 tools/rst2md.py obj/gnatdoc-rst docs/api-docs

release:
	@if [ -n "$(VERSION)" ]; then \
		version="$(VERSION)"; \
		sed -i 's/^version = ".*"/version = "'$$version'"/' alire.toml; \
	else \
		version=$$(sed -n 's/^version = "\(.*\)"/\1/p' alire.toml); \
	fi; \
	commit=$$(git rev-parse HEAD); \
	index_file="index/ad/crdt/crdt-$$version.toml"; \
	if [ ! -f "$$index_file" ]; then \
		cp index/ad/crdt/crdt-0.1.0-dev.toml "$$index_file"; \
	fi; \
	sed -i 's/^version = ".*"/version = "'$$version'"/' "$$index_file"; \
	release_file="alire/releases/crdt-$$version.toml"; \
	if [ ! -f "$$release_file" ]; then \
		sed 's/^version = ".*"/version = "'$$version'"/' alire/releases/crdt-0.0.0.toml > "$$release_file"; \
	fi; \
	sed -i 's/^version = ".*"/version = "'$$version'"/' "$$release_file"; \
	sed -i '/^\[origin\]/,$$d' "$$release_file" 2>/dev/null || true; \
	sed -i '$${/^$$/d}' "$$release_file" 2>/dev/null || true; \
	printf '[origin]\nurl = "https://codeberg.org/bladeacer/Ada_CRDT/archive/v%s.tar.gz"\n' "$$version" >> "$$release_file"; \
	if git rev-parse "v$$version" >/dev/null 2>&1; then \
		git tag -d "v$$version" >/dev/null 2>&1 || true; \
		git push origin :refs/tags/"v$$version" >/dev/null 2>&1 || true; \
		echo "  Replaced existing tag v$$version"; \
	fi; \
	git add -A; \
	git commit -m "Release $$version" || true; \
	git tag -a "v$$version" -m "Release $$version"; \
	echo "Tagged v$$version at $$commit"; \
	git push origin HEAD && git push origin "v$$version"; \
	echo "Pushed commit and tag v$$version"

demo:
	alr exec -- gprbuild -Pdemo/demo.gpr
	./demo/demo_life

clean:
	alr clean
	rm -rf obj/ lib/ docs/
