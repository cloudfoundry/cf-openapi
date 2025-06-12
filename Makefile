# CAPI OpenAPI Specification Makefile
# Default version can be overridden: make VERSION=3.196.0 <target>
VERSION ?= 3.195.0

# Colors for output
GREEN := \033[0;32m
CYAN := \033[0;36m
YELLOW := \033[0;33m
RED := \033[0;31m
NC := \033[0m # No Color

# Column width for alignment
COL_WIDTH := 25

# Default target - show help
.DEFAULT_GOAL := help

# Phony targets
.PHONY: all help clean clean-test spec sdk test docs prepare validate integration-test

#=============================================================================
# Main Targets
#=============================================================================

all: spec sdk docs test ## Generate everything (spec, SDK, docs) and run tests

clean: ## Clean all generated files for current version
	@echo "$(YELLOW)Cleaning generated files for version $(VERSION)...$(NC)"
	@rm -rf capi/$(VERSION)/openapi.* 
	@rm -rf capi/$(VERSION)/*.backup-*
	@rm -rf capi/$(VERSION)/*-report.md
	@rm -rf sdk/$(VERSION)/
	@rm -rf test/sdk-integration/*/
	@echo "$(GREEN)✓ Clean complete$(NC)"

#=============================================================================
# OpenAPI Specification Generation
#=============================================================================

prepare: ## Download HTML documentation
	@echo "$(YELLOW)Downloading HTML documentation...$(NC)"
	@./bin/gen prepare --version=$(VERSION)
	@echo "$(GREEN)✓ HTML documentation ready$(NC)"

spec: ## Generate OpenAPI specification (JSON format)
	@echo "$(YELLOW)Generating OpenAPI specification for version $(VERSION)...$(NC)"
	@./bin/gen spec --version=$(VERSION)
	@echo "$(GREEN)✓ OpenAPI spec generated at: capi/$(VERSION)/openapi.json$(NC)"

spec-yaml: ## Generate OpenAPI specification (YAML format)
	@echo "$(YELLOW)Generating OpenAPI specification in YAML format...$(NC)"
	@./bin/gen spec --version=$(VERSION) --format=yaml
	@echo "$(GREEN)✓ OpenAPI spec generated at: capi/$(VERSION)/openapi.yaml$(NC)"

spec-quick: ## Generate spec without enhancement/validation (faster)
	@echo "$(YELLOW)Generating OpenAPI spec (quick mode)...$(NC)"
	@./bin/gen spec --version=$(VERSION) --skip-enhancement --skip-validation
	@echo "$(GREEN)✓ Quick spec generation complete$(NC)"

#=============================================================================
# SDK Generation
#=============================================================================

sdk: sdk-go ## Generate Go SDK (default)

sdk-go: ## Generate Go SDK using oapi-codegen
	@echo "$(YELLOW)Generating Go SDK...$(NC)"
	@./bin/gen sdk --version=$(VERSION) --language=go
	@echo "$(GREEN)✓ Go SDK generated at: sdk/$(VERSION)/go/capiclient/$(NC)"

sdk-go-openapi: ## Generate Go SDK using openapi-generator
	@echo "$(YELLOW)Generating Go SDK with openapi-generator...$(NC)"
	@./bin/gen sdk --version=$(VERSION) --language=go --generator=openapi-generator
	@echo "$(GREEN)✓ Go SDK generated at: sdk/$(VERSION)/go/$(NC)"

sdk-python: ## Generate Python SDK
	@echo "$(YELLOW)Generating Python SDK...$(NC)"
	@./bin/gen sdk --version=$(VERSION) --language=python
	@echo "$(GREEN)✓ Python SDK generated at: sdk/$(VERSION)/python/$(NC)"

sdk-java: ## Generate Java SDK
	@echo "$(YELLOW)Generating Java SDK...$(NC)"
	@./bin/gen sdk --version=$(VERSION) --language=java
	@echo "$(GREEN)✓ Java SDK generated at: sdk/$(VERSION)/java/$(NC)"

sdk-typescript: ## Generate TypeScript SDK
	@echo "$(YELLOW)Generating TypeScript SDK...$(NC)"
	@./bin/gen sdk --version=$(VERSION) --language=typescript-fetch
	@echo "$(GREEN)✓ TypeScript SDK generated at: sdk/$(VERSION)/typescript-fetch/$(NC)"

sdk-all: sdk-go sdk-python sdk-java sdk-typescript ## Generate SDKs for all major languages

#=============================================================================
# Testing & Validation
#=============================================================================

validate: ## Validate OpenAPI specification
	@echo "$(YELLOW)Validating OpenAPI specification...$(NC)"
	@./bin/validate-spec --version=$(VERSION)
	@echo "$(GREEN)✓ Validation complete$(NC)"

test-examples: ## Validate examples in the spec
	@echo "$(YELLOW)Validating examples...$(NC)"
	@./bin/validate-examples capi/$(VERSION)/openapi.json
	@echo "$(GREEN)✓ Example validation complete$(NC)"

test-schemas: ## Test schemas
	@echo "$(YELLOW)Testing schemas...$(NC)"
	@./bin/test-schemas --version=$(VERSION)
	@echo "$(GREEN)✓ Schema tests complete$(NC)"

test: validate test-examples test-schemas ## Run all validation tests

test-sdk: ## Test SDK against live CF API (requires cf login)
	@echo "$(YELLOW)Testing SDK against live API...$(NC)"
	@./bin/test-cf-sdk --version=$(VERSION)
	@echo "$(GREEN)✓ SDK tests complete$(NC)"

integration-test: ## Run full integration test suite
	@echo "$(YELLOW)Running integration tests...$(NC)"
	@./bin/test-integration $(VERSION)
	@echo "$(GREEN)✓ Integration tests complete$(NC)"

clean-test: ## Clean test-generated SDK files
	@echo "$(YELLOW)Cleaning test SDK integration files...$(NC)"
	@rm -rf test/sdk-integration/*/
	@echo "$(GREEN)✓ Test cleanup complete$(NC)"

#=============================================================================
# Documentation
#=============================================================================

docs: docs-redocly ## Generate API documentation (default: Redocly)

docs-redocly: ## Generate Redocly API documentation
	@echo "$(YELLOW)Generating Redocly documentation...$(NC)"
	@if ! command -v redocly &> /dev/null; then \
		echo "$(RED)Error: redocly CLI not found. Install with: bun install -g @redocly/cli$(NC)"; \
		exit 1; \
	fi
	@mkdir -p capi/$(VERSION)/docs
	@redocly build-docs capi/$(VERSION)/openapi.json -o capi/$(VERSION)/docs/index.html
	@echo "$(GREEN)✓ Redocly docs generated at: capi/$(VERSION)/docs/index.html$(NC)"

docs-swagger: ## Generate Swagger UI documentation
	@echo "$(YELLOW)Generating Swagger UI documentation...$(NC)"
	@if ! command -v swagger-ui &> /dev/null; then \
		echo "Installing swagger-ui-dist..."; \
		bun install -g swagger-ui-dist; \
	fi
	@mkdir -p capi/$(VERSION)/docs/swagger
	@cp -r $$(bunx pm ls -g | grep swagger-ui-dist | awk '{print $$2}')/swagger-ui-dist/* capi/$(VERSION)/docs/swagger/
	@sed -i.bak 's|https://petstore.swagger.io/v2/swagger.json|../../openapi.json|g' capi/$(VERSION)/docs/swagger/index.html
	@rm capi/$(VERSION)/docs/swagger/index.html.bak
	@echo "$(GREEN)✓ Swagger UI docs generated at: capi/$(VERSION)/docs/swagger/index.html$(NC)"

docs-serve: ## Serve API documentation locally (port 8080)
	@echo "$(YELLOW)Starting documentation server on http://localhost:8080...$(NC)"
	@cd capi/$(VERSION)/docs && python3 -m http.server 8080

#=============================================================================
# Utility Targets
#=============================================================================

show-versions: ## List all available CAPI versions
	@echo "$(CYAN)Available CAPI versions:$(NC)"
	@ls -1 capi/ | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$$' | sort -V

diff: ## Compare two versions (usage: make diff FROM=3.194.0 TO=3.195.0)
	@if [ -z "$(FROM)" ] || [ -z "$(TO)" ]; then \
		echo "$(RED)Error: Please specify FROM and TO versions$(NC)"; \
		echo "Usage: make diff FROM=3.194.0 TO=3.195.0"; \
		exit 1; \
	fi
	@echo "$(YELLOW)Comparing version $(FROM) with $(TO)...$(NC)"
	@./bin/gen diff $(FROM) $(TO)

reports: ## Show all reports for current version
	@echo "$(CYAN)Reports for version $(VERSION):$(NC)"
	@for report in capi/$(VERSION)/*-report.md; do \
		if [ -f "$$report" ]; then \
			echo "  • $$(basename $$report)"; \
		fi \
	done

view-report: ## View a specific report (usage: make view-report REPORT=enhancement)
	@if [ -z "$(REPORT)" ]; then \
		echo "$(RED)Error: Please specify REPORT name$(NC)"; \
		echo "Usage: make view-report REPORT=enhancement"; \
		echo "Available reports:"; \
		@make reports; \
		exit 1; \
	fi
	@cat capi/$(VERSION)/$(REPORT)-report.md

#=============================================================================
# Development Helpers
#=============================================================================

install-deps: ## Install all required dependencies
	@echo "$(YELLOW)Installing dependencies...$(NC)"
	@# Perl modules
	@cpanm --quiet --notest JSON::XS YAML::XS Mojo::DOM Mojo::JSON File::Slurp LWP::Simple || true
	@# Node tools
	@bun install -g @redocly/cli @openapitools/openapi-generator-cli || true
	@# Go tools
	@go install github.com/deepmap/oapi-codegen/cmd/oapi-codegen@latest || true
	@echo "$(GREEN)✓ Dependencies installed$(NC)"

check-deps: ## Check if all dependencies are installed
	@echo "$(CYAN)Checking dependencies...$(NC)"
	@EXIT_CODE=0; \
	for cmd in perl jq spruce oapi-codegen openapi-generator redocly; do \
		if command -v $$cmd &> /dev/null; then \
			echo "$(GREEN)✓$(NC) $$cmd"; \
		else \
			echo "$(RED)✗$(NC) $$cmd"; \
			EXIT_CODE=1; \
		fi \
	done; \
	exit $$EXIT_CODE

#=============================================================================
# Help Target
#=============================================================================

help: ## Show this help message
	@echo "$(GREEN)CAPI OpenAPI Specification Generator$(NC)"
	@echo ""
	@echo "Usage: make [target] [VERSION=x.x.x]"
	@echo "Default version: $(VERSION)"
	@echo ""
	@echo "$(GREEN)━━━ Main Targets ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)"
	@grep -E '^all|^clean|^spec[^-]|^sdk[^-]|^test[^-]|^docs[^-]' $(MAKEFILE_LIST) | \
		awk -F ':.*?## ' '/^[a-zA-Z_-]+:.*?## / {printf "$(CYAN)%-$(COL_WIDTH)s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(GREEN)━━━ OpenAPI Specification ━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)"
	@grep -E '^prepare|^spec-' $(MAKEFILE_LIST) | \
		awk -F ':.*?## ' '/^[a-zA-Z_-]+:.*?## / {printf "$(CYAN)%-$(COL_WIDTH)s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(GREEN)━━━ SDK Generation ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)"
	@grep -E '^sdk-' $(MAKEFILE_LIST) | \
		awk -F ':.*?## ' '/^[a-zA-Z_-]+:.*?## / {printf "$(CYAN)%-$(COL_WIDTH)s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(GREEN)━━━ Testing & Validation ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)"
	@grep -E '^validate|^test-|^integration-test' $(MAKEFILE_LIST) | \
		awk -F ':.*?## ' '/^[a-zA-Z_-]+:.*?## / {printf "$(CYAN)%-$(COL_WIDTH)s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(GREEN)━━━ Documentation ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)"
	@grep -E '^docs-' $(MAKEFILE_LIST) | \
		awk -F ':.*?## ' '/^[a-zA-Z_-]+:.*?## / {printf "$(CYAN)%-$(COL_WIDTH)s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(GREEN)━━━ Utilities ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)"
	@grep -E '^show-versions|^diff|^reports|^view-report' $(MAKEFILE_LIST) | \
		awk -F ':.*?## ' '/^[a-zA-Z_-]+:.*?## / {printf "$(CYAN)%-$(COL_WIDTH)s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(GREEN)━━━ Development ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)"
	@grep -E '^install-deps|^check-deps' $(MAKEFILE_LIST) | \
		awk -F ':.*?## ' '/^[a-zA-Z_-]+:.*?## / {printf "$(CYAN)%-$(COL_WIDTH)s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "Examples:"
	@echo "  make                    # Show this help"
	@echo "  make all                # Generate everything"
	@echo "  make spec               # Generate OpenAPI spec"
	@echo "  make sdk                # Generate Go SDK"
	@echo "  make sdk-python         # Generate Python SDK"
	@echo "  make test               # Run validation tests"
	@echo "  make docs               # Generate API documentation"
	@echo "  make VERSION=3.196.0 spec  # Generate spec for different version"