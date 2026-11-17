# Managed by the template (00-CEREBRO, copier) - do not edit.
# Project settings and extra targets go in project.mk; update with
# `copier update --trust`. Targets: 01-CONVENCIONES/04-PROYECTOS-Y-REPOS/02-MAKEFILE.md.

KIND := r
SHELL := bash
.SHELLFLAGS := -eu -o pipefail -c
.DEFAULT_GOAL := help
.PHONY: help setup format lint test check docs build clean release

# project.mk may set any *_CMD below (empty = "no aplica") and add targets
-include project.mk

ifeq ($(KIND),python)
SETUP_CMD   ?= uv sync
FORMAT_CMD  ?= uv run ruff format . && uv run ruff check --fix .
LINT_CMD    ?= uv run ruff format --check . && uv run ruff check .
TEST_CMD    ?= uv run pytest -q
BUILD_CMD   ?= uv build
CLEAN_CMD   ?= rm -rf dist build .pytest_cache .ruff_cache && \
               find . -name __pycache__ -prune -not -path './.venv/*' \
               -exec rm -rf {} +
VERSION_CMD ?= uv version $(VERSION)
endif
ifeq ($(KIND),r)
R := Rscript -e
SETUP_CMD   ?= $(R) 'if (file.exists("renv.lock")) renv::restore() else \
               remotes::install_deps(dependencies = TRUE)'
FORMAT_CMD  ?= $(R) 'styler::style_pkg()'
LINT_CMD    ?= $(R) 'l <- lintr::lint_package(); print(l); \
               quit(status = length(l) > 0)'
TEST_CMD    ?= $(R) 'devtools::test(stop_on_failure = TRUE)'
CHECK_CMD   ?= $(R) 'devtools::check(args = "--as-cran", \
               error_on = "warning")'
DOCS_CMD    ?= $(R) 'devtools::document()'
BUILD_CMD   ?= $(R) 'devtools::build()'
CLEAN_CMD   ?= rm -rf *.Rcheck ..Rcheck *.tar.gz
VERSION_CMD ?= $(R) 'desc::desc_set_version("$(VERSION)")'
endif
ifeq ($(KIND),quarto)
LINT_CMD    ?= python3 scripts/cabecera_qmd.py   # cabecera de los .qmd (04-QUARTO)
DOCS_CMD    ?= quarto render
BUILD_CMD   ?= quarto render
CLEAN_CMD   ?= rm -rf _book _site .quarto
endif
ifeq ($(KIND),latex)
MAIN        ?= main.tex
LINT_CMD    ?= chktex -q $(MAIN)
BUILD_CMD   ?= latexmk -pdf -interaction=nonstopmode $(MAIN)
CLEAN_CMD   ?= latexmk -C $(MAIN)
endif

# $(call step,NAME,VAR): run the command in VAR, or say it does not apply
# (the variable name is passed, not the command: commands contain commas)
define step
	@$(if $(strip $($(2))),echo "→ $(1)" && $($(2)),echo "$(1): no aplica en este proyecto")
endef

help: ## List the targets
	@echo "$(notdir $(CURDIR)) ($(KIND))"
	@grep -hE '^[a-zA-Z0-9_-]+:.*## ' $(MAKEFILE_LIST) | \
		awk -F ':.*## ' '{printf "  make %-10s %s\n", $$1, $$2}'

setup: ## Create the environment (and pre-commit, if configured)
	$(call step,setup,SETUP_CMD)
	@if [ -f .pre-commit-config.yaml ]; then uvx pre-commit install; fi

format: ## Format the code
	$(call step,format,FORMAT_CMD)

lint: ## Static checks; changes nothing
	$(call step,lint,LINT_CMD)

test: ## Run the tests
	$(call step,test,TEST_CMD)

check: lint test ## lint + test (+ R CMD check --as-cran in R)
	@$(if $(strip $(CHECK_CMD)),echo "→ check" && $(CHECK_CMD),:)

docs: ## Build the documentation
	$(call step,docs,DOCS_CMD)

build: ## Build the package, book or PDF
	$(call step,build,BUILD_CMD)

clean: ## Remove what can be regenerated
	$(call step,clean,CLEAN_CMD)

release: ## make release VERSION=x.y.z: check, version, commit and tag
	@[ -n "$(VERSION)" ] || { echo "Uso: make release VERSION=x.y.z"; exit 1; }
	@git diff --quiet && git diff --cached --quiet || \
		{ echo "Hay cambios sin commit"; exit 1; }
	@grep -qs "$(VERSION)" CHANGELOG.md NEWS.md || { echo \
		"Añade $(VERSION) a CHANGELOG.md (o NEWS.md), haz commit y repite"; \
		exit 1; }
	@$(MAKE) --no-print-directory check
	$(call step,version,VERSION_CMD)
	git add -A && git commit -m "Release $(VERSION)" && \
		git tag -a "v$(VERSION)" -m "v$(VERSION)"
	@echo "Etiqueta v$(VERSION) creada; sube con: git push --follow-tags"
