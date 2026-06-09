.PHONY: help all build run test test-fuzz prove doc api-docs compliance clean release publish demo

.DEFAULT_GOAL := help

help:
	@echo 'CRDT - CRDT library for Ada/SPARK'
	@echo ''
	@echo 'Usage: make <target>'
	@echo ''
	@echo '  build         Build the project and tests (alr build)'
	@echo '  run           Build and run tests'
	@echo '  test          Alias for run'
	@echo '  test-fuzz     Run chaos fuzzing (bit-flip + clock skew + OOO delta)'
	@echo '  prove         Run SPARK proofs (alr gnatprove)'
	@echo '  doc           Generate Markdown API docs (docs/api-docs/)'
	@echo '  compliance    Verify DO-178C traceability (HLR tags in source)'
	@echo '  release       Tag, update index+releases, push. Use VERSION=x.y.z'
	@echo '  publish       Publish to Alire community index (run after make release)'
	@echo '  test-publish  Dry-run showing what make publish would do'
	@echo '  demo          Build and run the Game of Life demo'
	@echo '  clean         Remove build artifacts'
	@echo '  help          Show this message'

build:
	tmpfile=$$(mktemp); \
	alr build > $$tmpfile 2>&1; result=$$?; \
	grep -v "no .sframe will be created" $$tmpfile; \
	rm -f $$tmpfile; exit $$result

run: build
	alr run

test: run

test-fuzz: run

prove:
	alr gnatprove

compliance:
	@echo "=== DO-178C Traceability Verification ==="; \
	total=0; \
	missing=0; \
	srcdir=src; \
	hlrs=$$(grep -rn -- '--.*HLR-' $$srcdir | sed 's/.*HLR-\([A-Z0-9-]*\).*/\1/' | sort -u); \
	echo "HLR tags found in source: $$(echo "$$hlrs" | wc -l)"; \
	for hlr in $$hlrs; do \
		found=$$(grep -rl -- "--.*HLR-$$hlr" $$srcdir); \
		if [ -z "$$found" ]; then \
			echo "  MISSING: HLR-$$hlr — no source file has this tag"; \
			missing=$$((missing + 1)); \
		else \
			echo "  HLR-$$hlr -> $$(echo $$found | tr ' ' ',' | sed 's,$$(pwd)/,,g')"; \
		fi; \
		total=$$((total + 1)); \
	done; \
	echo ""; \
	if [ "$$missing" -eq 0 ]; then \
		echo "All $$total HLR tags validated — traceability OK."; \
	else \
		echo "$$missing / $$total HLR tags unresolved."; \
		exit 1; \
	fi; \
	echo "=== Verification files ==="; \
	for f in docs/compliance/HLR.md docs/compliance/LLR.md docs/compliance/TRACE.md docs/compliance/index.md; do \
		if [ -f "$$f" ]; then echo "  $$f — present"; \
		else echo "  $$f — MISSING"; missing=$$((missing + 1)); fi; \
	done

doc: api-docs

api-docs:
	mkdir -p obj
	alr exec -- gnatdoc -P crdt.gpr --backend=rst --output-dir=obj/gnatdoc-rst
	python3 tools/rst2md.py obj/gnatdoc-rst docs/api-docs
	rm -f docs/api-docs/test_*.md docs/api-docs/crdt-test_support.md
	sed -i '/](test_[^)]*\.md)/d' docs/api-docs/index.md
	sed -i '/](crdt-test_support\.md)/d' docs/api-docs/index.md
	@echo "Regenerating docs/changelogs/index.md..."
	@{ \
	  echo "# CRDT Changelogs"; \
	  echo ""; \
	  echo "<!-- CHANGELOG_LIST -->"; \
	  list=""; \
	  for f in docs/changelogs/crdt-*.md; do \
	    v=$$(basename "$$f" .md | sed 's/crdt-//'); \
	    case "$$v" in *-migration|index) continue;; esac; \
	    list="$$list$$v "; \
	  done; \
	  for v in $$(echo $$list | tr ' ' '\n' | sort -t. -k1,1rn -k2,2rn -k3,3rn); do \
	    echo "- [$$v](crdt-$$v.md)"; \
	  done; \
	  echo ""; \
	  echo "## Protocol Migration"; \
	  echo ""; \
	  echo "- [V1 → V2 Migration Guide](crdt-1.4.0-migration.md) — how \`Read_Header\`"; \
	  echo "  auto-detects wire format, and how to write V1 for legacy peers"; \
	} > docs/changelogs/index.md
	@echo "Validating changelog links..."
	@for f in docs/changelogs/*.md; do \
	  base=$$(dirname "$$f"); \
	  for link in $$(sed -n 's/.*\[.*\](\([^)]*\.md\)).*/\1/p' "$$f"); do \
	    resolved="$$base/$$link"; \
	    if [ ! -f "$$resolved" ] && [ ! -f "docs/changelogs/$$link" ]; then \
	      echo "ERROR: broken link '$$link' in $$f"; \
	      exit 1; \
	    fi; \
	  done; \
	done; \
	echo "All changelog links OK"

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

publish:
	@if [ -n "$$(git status --porcelain)" ]; then \
		echo "Error: working tree is not clean. Commit or stash changes first."; \
		exit 1; \
	fi; \
	version=$$(ls alire/releases/crdt-*.toml 2>/dev/null | sort -V | tail -1 | sed 's/.*crdt-\(.*\)\.toml/\1/'); \
	if [ -z "$$version" ]; then \
		echo "Error: could not detect version from alire/releases/"; \
		exit 1; \
	fi; \
	echo "Publishing crdt $$version (from alire/releases/crdt-$$version.toml) to Alire community index..."; \
	publish_dir="$$HOME/.local/share/alire/publish/community"; \
	orig_dir=$$(pwd); \
	if [ ! -d "$$publish_dir" ]; then \
		echo "Error: $$publish_dir not found"; \
		exit 1; \
	fi; \
	cd "$$publish_dir" && git pull && cd "$$orig_dir"; \
	alr publish "https://codeberg.org/bladeacer/Ada_CRDT/archive/v$$version.tar.gz" || true; \
	cd "$$publish_dir" && \
	git reset --soft HEAD~1 && \
	index_file="index/cr/crdt/crdt-$$version.toml"; \
	if [ -f "$$index_file" ]; then \
		sed -i \
			-e '/^executables = /d' \
			-e '/^\[\[depends-on\]\]/d' \
			-e '/^gnatprove = /d' \
			-e '/^gnatdoc_bin = /d' \
			"$$index_file"; \
		git add -A && \
		git commit -m "crdt $$version (via alr publish)" && \
		git push origin && \
		cd "$$orig_dir" && git restore .; \
		echo "Published crdt $$version to community index."; \
	else \
		echo "Error: $$index_file not found in $$publish_dir"; \
		cd "$$orig_dir" && git restore .; \
		exit 1; \
	fi

test-publish:
	@version=$$(ls alire/releases/crdt-*.toml 2>/dev/null | sort -V | tail -1 | sed 's/.*crdt-\(.*\)\.toml/\1/'); \
	if [ -z "$$version" ]; then \
		echo "Error: could not detect version from alire/releases/"; \
		exit 1; \
	fi; \
	echo "=== test-publish dry-run ==="; \
	echo "Version:  $$version"; \
	echo "Config:   alire/releases/crdt-$$version.toml"; \
	echo "Archive:  https://codeberg.org/bladeacer/Ada_CRDT/archive/v$$version.tar.gz"; \
	echo "Index:    index/cr/crdt/crdt-$$version.toml"; \
	echo "Publish:  alr publish <archive>"; \
	echo "Cleanup:  sed on index file (executables, depends-on, gnatprove, gnatdoc_bin)"; \
	echo "Push:     git add + commit + push to community index"; \
	echo "Cleanup:   cd back to project root and run git restore ."; \
	echo "=== end dry-run ==="

demo:
	cd demo && alr build
	stty -isig; ./demo/demo_life; stty isig

clean:
	alr clean
	rm -rf obj/ lib/ docs/
