# Cloud Foundry CAPI and V3 API OpenAPI Specification

This repository contains a complete OpenAPI 3.0.0 specification for the Cloud Foundry Cloud Controller API (CAPI) v3.195.0, providing 100% coverage of all API endpoints, resources, and operations. It is a combination of the `capi-openapi-spec` and `cf-api-openapi-poc` repositories, including the history of both.

The rendered version can be accessed here: <https://flothinkspi.github.io/cf-api-openapi-poc/>

## Introduction

In this project, we are developing an OpenAPI Specification for the Cloud Foundry V3 API.
This is done outside the Cloud Foundry Foundation for now, but we aim to contribute the specification back to the foundation once in a usable/mature state.

The base specification is based on the [Cloud Foundry V3 API documentation](https://v3-apidocs.cloudfoundry.org/).

## Conventions

1. We use lowerCamelCase for field names and operationIds as well as other yaml tokens.

## Status

This treats the upstream Cloud Foundry API v3 as the source of truth:
<https://v3-apidocs.cloudfoundry.org/version/3.195.0/index.html#deprecated-endpoints>

The api docs are fetched from the versioned url into the ./data directory and
then processed into the OpenAPI YAML files in ./capi/3.195.0.

Currently the process of carving up the API html file into the individual YAML files is done manually,
the goal is to automate this part of the process in the future.

Once this has been parsed into the OpenAPI .yml files in ./capi/3.195.0 they are then
merged into ./capi/3.195.0.openapi.yaml and .capi/3.195.0.openapi.json files.

From there the OpenAPI specification can be used to generate client SDKs, documentation, etc...

## Overview

This repository contains a comprehensive OpenAPI specification that fully describes the Cloud Foundry v3 API. The specification is organized into modular YAML files for maintainability and can be used to:

- Generate client SDKs in multiple languages
- Create API documentation
- Perform API testing and validation
- Build developer tools and integrations

## Features

- ✅ **Complete API Coverage**: All 44 resource types and their endpoints
- ✅ **Modular Architecture**: Organized into separate YAML files per resource
- ✅ **Advanced Querying**: Label selectors, timestamp operators, field selection
- ✅ **Experimental Features**: Marked with `x-experimental` extension
- ✅ **Comprehensive Schemas**: Full request/response schemas with examples
- ✅ **Metadata Support**: Labels and annotations on all resources
- ✅ **Async Operations**: Job tracking for long-running operations
- ✅ **Error Handling**: Detailed error schemas and status codes

## Quick Start

New to CAPI OpenAPI? Check out our **[Quick Start Guide](docs/quickstart.md)** for a complete working example.

### Prerequisites

- Make
- Perl 5.20+
- Go (for oapi-codegen)
- Node.js (for API documentation)
- Your preferred programming language for client generation

### Complete Working Example

```bash
# 1. Clone the repository
git clone https://github.com/cloudfoundry-community/capi-openapi-spec.git
cd capi-openapi-spec

# 2. Install dependencies
make install-deps

# 3. Generate OpenAPI specification (JSON is default to avoid Unicode issues)
./bin/gen spec --version=3.195.0

# 4. Generate Go SDK using oapi-codegen (default for Go)
./bin/gen sdk --version=3.195.0 --language=go

# SDK will be created in: sdk/3.195.0/go/capiclient/
```

### Basic Usage

1. **Generate the OpenAPI specification**

   ```bash
   make spec
   ```

   This creates `capi/3.195.0/openapi.json` with automatic type fixes and enhancements

2. **Generate a client SDK**

   ```bash
   # Generate Go SDK (uses oapi-codegen by default)
   make sdk
   
   # Generate SDKs for other languages
   make sdk-python
   make sdk-java
   make sdk-typescript
   
   # Generate all major SDKs
   make sdk-all
   ```

3. **Generate API documentation**

   ```bash
   # Generate Redocly documentation
   make docs
   
   # Serve documentation locally
   make docs-serve
   ```

### Common Commands

```bash
# Show all available commands with descriptions
make

# Generate everything (spec, SDK, docs) and run tests
make all

# Generate spec for a specific version
make spec VERSION=3.196.0

# Run all validation tests
make test

# View generated reports
make reports
make view-report REPORT=enhancement

# Compare two API versions
make diff FROM=3.194.0 TO=3.195.0

# Clean all generated files
make clean

# Clean only test-generated SDK files
make clean-test
```

## Development workflows

### Start a local development server

With below comand you can start a local development server that serves the OpenAPI Specification.
It supports hot reloading, so you can make changes to the `openapi.yaml` and see the changes immediately.

```bash
  yarn global add @lyra-network/openapi-dev-tool @redocly/cli
  # Linter
  redocly lint openapi.yaml 
  # Life reloading webui generated of the openapi.yaml(automatically restart on crash with while loop)
  while true; do openapi-dev-tool serve -c .openapi-dev-tool.config.json; done
```

### AI

To get a good query (to much tokens only usable with gemini-1.5-pro) for ai you can use the following command:

```bash
  cat ai/context.txt ai/CFV3Docu.txt openapi.yaml ai/command.txt | pbcopy
```

Then copy the resulting yaml to `tmp.yaml`
To merge snippets of OpenAPI Spec from `tmp.yaml` into `openapi.yaml`, run following command to merge it:

```bash
echo "$(yq eval '(.x-components) as $i ireduce({}; setpath($i | path; $i))' openapi.yaml | cat - tmp.yaml)" > tmp.yaml  && yq eval-all -i '. as $item ireduce ({}; . *+ $item)' openapi.yaml tmp.yaml &&  yq e -i '(... | select(type == "!!seq")) |= unique' openapi.yaml && echo "" > tmp.yaml && sed -i 's/!!merge //g' openapi.yaml
```

## SDK Generation

The `bin/gen` script provides a flexible way to generate SDKs for different languages and CAPI versions.

### Usage

```bash
# Generate SDK
./bin/gen --version=VERSION --language=LANGUAGE [--output=PATH] [--generator=GENERATOR]

# Prepare specifications (download and create YAML files)
./bin/gen prepare --version=VERSION

# Merge YAML files into unified OpenAPI spec
./bin/gen merge --version=VERSION
```

### Generator Options

The script supports multiple code generators:

- **oapi-codegen** (default for Go) - Generates a single, clean Go file with types and client
- **openapi-generator** (default for other languages) - Full-featured generator with many customization options

### Examples

#### Generate Go SDK for latest CAPI version (3.195.0)

```bash
# Using default oapi-codegen generator (creates single client.go file)
./bin/gen --version=3.195.0 --language=go
# Output: ./sdk/3.195.0/go/capiclient/client.go

# Using openapi-generator (creates multiple files)
./bin/gen --version=3.195.0 --language=go --generator=openapi-generator
# Output: ./sdk/3.195.0/go/
```

#### Generate Ruby SDK for latest CAPI version

```bash
./bin/gen --version=3.195.0 --language=ruby
# Output: ./sdk/3.195.0/ruby/
```

#### Generate Python SDK with custom output path

```bash
./bin/gen --version=3.195.0 --language=python --output=/path/to/my-sdk
```

#### Generate SDKs for older CAPI version

```bash
# Go SDK for CAPI 3.181.0
./bin/gen --version=3.181.0 --language=go

# Ruby SDK for CAPI 3.181.0
./bin/gen --version=3.181.0 --language=ruby
```

### Supported Languages

The generator supports all languages provided by OpenAPI Generator, including:

- **go** - Go client library
- **ruby** - Ruby gem
- **python** - Python package
- **java** - Java library
- **javascript** - JavaScript/Node.js
- **typescript-node** - TypeScript for Node.js
- **csharp** - C# / .NET
- **php** - PHP library
- **rust** - Rust crate
- **swift5** - Swift 5
- **kotlin** - Kotlin
- And many more...

Run `./bin/gen --help` to see the full list of supported languages.

### Post-Generation Steps

After generating an SDK, you may need to:

1. **Go**:
   - With oapi-codegen: `go.mod` is automatically created and `go mod tidy` is run
   - With openapi-generator: Run `go mod tidy` in the generated directory
2. **Ruby**: Build the gem with `gem build *.gemspec`
3. **Python**: Install with `pip install -e .`
4. **Java**: Build with Maven or Gradle

## Publishing Go Client

The repository includes an automated workflow for publishing the Go client to a separate repository for easy consumption.

### Manual Publishing

```bash
# Generate the Go client
./bin/gen --version=3.195.0 --language=go

# Publish to github.com/cloudfoundry-community/capi-openapi-go-client
./bin/publish --version=3.195.0

# Dry run to preview what will be published
./bin/publish --version=3.195.0 --dry-run

# Force overwrite if tag already exists
./bin/publish --version=3.195.0 --force
```

### Automated Publishing via GitHub Actions

1. Go to the [Actions tab](../../actions)
2. Select "Publish Go Client" workflow
3. Click "Run workflow"
4. Enter the CAPI version (e.g., 3.195.0)
5. Optionally check "Force" to overwrite existing tags

The published Go module will be available at:

```go
import "github.com/cloudfoundry-community/capi-openapi-go-client/capiclient/v3"
```

### Publishing Requirements

- **SSH Deploy Key**: The GitHub Actions workflow requires a deploy key secret (`CAPI_GO_CLIENT_DEPLOY_KEY`) with write access to the target repository
- **Target Repository**: `github.com/cloudfoundry-community/capi-openapi-go-client` must exist and be configured to accept the deploy key

## Version Information

| Component | Version |
|-----------|---------|
| CAPI API Version | v3.195.0 |
| OpenAPI Specification | 3.0.0 |
| Last Updated | January 2025 |

## Documentation

Comprehensive documentation is available in the `docs/` directory:

- **[Quick Start Guide](docs/quickstart.md)** - Complete working example with solutions to common issues
- [Getting Started Guide](docs/getting-started.md) - Introduction and quick examples
- [API Overview](docs/api-overview.md) - REST principles, pagination, errors
- [Core Resources Guide](docs/core-resources.md) - Apps, processes, builds, packages
- [Services Guide](docs/services.md) - Service instances, bindings, brokers
- [Query Parameters Guide](docs/query-parameters.md) - Advanced filtering and selection
- [Client SDK Guide](docs/client-sdks.md) - Generating and using client libraries

## Supported Resources

The specification covers all Cloud Foundry v3 resources:

### Core Application Resources

- Applications, Processes, Builds, Droplets, Packages
- Revisions, Deployments, Tasks, Sidecars

### Routing & Networking

- Routes, Domains, Route Destinations
- Security Groups, Route Mappings (deprecated)

### Organizations & Spaces

- Organizations, Spaces, Roles
- Organization Quotas, Space Quotas
- Isolation Segments, Space Features

### Services

- Service Instances, Service Bindings
- Service Brokers, Service Plans, Service Offerings
- Service Route Bindings (experimental)

### Platform Features

- Jobs (async operations), Manifests
- Feature Flags, Environment Variable Groups
- Audit Events, Usage Events

## Experimental Features

Features marked as experimental using the `x-experimental` extension:

- Route sharing between spaces
- Application manifest diff
- Service route bindings

## Development

### Project Structure

```
capi/
├── 3.195.0/
│   ├── apps.yml
│   ├── processes.yml
│   ├── services.yml
│   └── ... (41 resource files)
├── 3.195.0.openapi.yaml  (generated)
└── 3.195.0.openapi.json  (generated)
bin/
├── gen           (main processing script for prepare, merge, and SDK generation)
├── publish       (publishes Go client to separate repository)
└── validate      (OpenAPI spec validation script)
sdk/
└── VERSION/
    └── LANGUAGE/ (generated SDKs)
.github/
└── workflows/
    └── publish-go-client.yml (automated publishing workflow)
```

### Validation

Validate the OpenAPI specification:

```bash
# Using openapi-generator
openapi-generator validate -i capi/3.195.0.openapi.yaml

# Using swagger-cli
swagger-cli validate capi/3.195.0.openapi.yaml
```

### Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes to the appropriate YAML files
4. Ensure validation passes
5. Submit a pull request

## Resources

- [CAPI v3.195.0 Documentation](https://v3-apidocs.cloudfoundry.org/version/3.195.0/index.html)
- [OpenAPI Specification](https://spec.openapis.org/oas/v3.0.0)
- [Cloud Foundry Community](https://www.cloudfoundry.org/community/)

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Cloud Foundry Foundation
- Cloud Foundry CAPI Team
- OpenAPI Initiative
- Community Contributors
