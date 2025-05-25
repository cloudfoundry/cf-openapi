.PHONY: deps deps-openapi deps-spruce deps-jq deps-java help gen-go-client

# Default target
.DEFAULT_GOAL := help

# Variables
SHELL := /bin/bash
UNAME_S := $(shell uname -s)
OPENAPI_GEN_VERSION := 7.2.0
CAPI_VERSION ?= 3.195.0

help: ## Display this help screen
	@grep -h -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

deps: deps-java deps-openapi deps-spruce deps-jq ## Install all dependencies

deps-java: ## Install Java Runtime Environment
	@echo "Checking/Installing Java..."
	@if [ "$(UNAME_S)" = "Darwin" ]; then \
		if ! command -v java &> /dev/null; then \
			if ! command -v brew &> /dev/null; then \
				echo "Homebrew is not installed. Please install it first: https://brew.sh/"; \
				exit 1; \
			fi; \
			brew install openjdk@17; \
			sudo ln -sfn $(brew --prefix)/opt/openjdk@17/libexec/openjdk.jdk /Library/Java/JavaVirtualMachines/openjdk-17.jdk; \
		fi \
	else \
		if ! command -v java &> /dev/null; then \
			if command -v apt-get &> /dev/null; then \
				sudo apt-get update && sudo apt-get install -y default-jre; \
			elif command -v yum &> /dev/null; then \
				sudo yum install -y java-17-openjdk; \
			else \
				echo "Please install Java manually: https://adoptium.net/"; \
				exit 1; \
			fi \
		fi \
	fi

deps-openapi: deps-java ## Install OpenAPI Generator CLI
	@echo "Installing OpenAPI Generator CLI..."
	@if ! command -v bun &> /dev/null; then \
		echo "bun is not installed. Please install bun first: https://bun.sh/"; \
		exit 1; \
	fi
	bun install @openapitools/openapi-generator-cli -g

deps-spruce: ## Install Spruce
	@echo "Installing Spruce..."
	@if [ "$(UNAME_S)" = "Darwin" ]; then \
		if ! command -v brew &> /dev/null; then \
			echo "Homebrew is not installed. Please install it first: https://brew.sh/"; \
			exit 1; \
		fi; \
		brew install starkandwayne/cf/spruce; \
	else \
		if ! command -v curl &> /dev/null; then \
			echo "curl is not installed. Please install it first."; \
			exit 1; \
		fi; \
		curl -sL https://github.com/geofffranks/spruce/releases/download/v1.30.2/spruce-linux-amd64 -o spruce && \
		chmod +x spruce && \
		sudo mv spruce /usr/local/bin/; \
	fi

deps-jq: ## Install jq
	@echo "Installing jq..."
	@if [ "$(UNAME_S)" = "Darwin" ]; then \
		if ! command -v brew &> /dev/null; then \
			echo "Homebrew is not installed. Please install it first: https://brew.sh/"; \
			exit 1; \
		fi; \
		brew install jq; \
	else \
		if ! command -v apt-get &> /dev/null; then \
			echo "This installation method only supports apt-based systems. Please install jq manually."; \
			exit 1; \
		fi; \
		sudo apt-get update && sudo apt-get install -y jq; \
	fi

check-deps: ## Check if all dependencies are installed
	@echo "Checking dependencies..."
	@command -v spruce >/dev/null 2>&1 || { echo "spruce is not installed. Run 'make deps-spruce'"; exit 1; }
	@command -v jq >/dev/null 2>&1 || { echo "jq is not installed. Run 'make deps-jq'"; exit 1; }
	@echo "All dependencies are installed!"

prepare: check-deps ## Prepare the OpenAPI specification
	@echo "Preparing OpenAPI specification..."
	./bin/capi-openapi prepare

gen-openapi-spec: check-deps ## Merge the CAPI OpenAPI specifications
	@echo "Merging CAPI OpenAPI specifications..."
	./bin/capi-openapi gen openapi spec

gen-go-client: check-deps gen-openapi-spec ## Generate Go client from OpenAPI spec
	@echo "Generating Go client..."
	./bin/capi-openapi gen go client

all: deps prepare gen-openapi-spec gen-go-client ## Run all steps to generate the Go client
