# Cloud Foundry CAPI OpenAPI Specification

A complete OpenAPI 3.0.0 specification for the Cloud Foundry Cloud Controller API (CAPI) v3.195.0, providing 100% coverage of all API endpoints, resources, and operations.

## Status

This treats the upstream Cloud Foundry API v3 as the source of truth:
https://v3-apidocs.cloudfoundry.org/version/3.195.0/index.html#deprecated-endpoints

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

### Prerequisites
- Make
- OpenAPI tools (optional, for validation)
- Your preferred programming language for client generation

### Basic Usage

1. **Clone the repository**
   ```bash
   git clone https://github.com/cloudfoundry-community/capi-openapi-spec.git
   cd capi-openapi-spec
   ```

2. **Install dependencies**
   ```bash
   make deps
   ```

3. **Generate the unified OpenAPI specification**
   ```bash
   make gen-openapi-spec
   ```
   This creates `capi/3.195.0.openapi.yaml` and `capi/3.195.0.openapi.json`

4. **Generate a client SDK** (example for Go)
   ```bash
   make gen-go-client
   # Or for any language:
   make gen-sdk LANGUAGE=python VERSION=3.195.0
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

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Cloud Foundry Foundation
- Cloud Foundry CAPI Team
- OpenAPI Initiative
- Community Contributors
