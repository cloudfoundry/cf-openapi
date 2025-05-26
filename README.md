# Cloud Foundry CAPI OpenAPI Specification

A complete OpenAPI 3.0.0 specification for the Cloud Foundry Cloud Controller API (CAPI) v3.195.0, providing 100% coverage of all API endpoints, resources, and operations.

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

2. **Generate the unified OpenAPI specification**
   ```bash
   make gen-openapi-spec
   ```
   This creates `capi/3.181.0.openapi.yaml` and `capi/3.181.0.openapi.json`

3. **Generate a client SDK** (example for Go)
   ```bash
   make gen-go-client
   ```

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
├── 3.181.0/
│   ├── apps.yml
│   ├── processes.yml
│   ├── services.yml
│   └── ... (44 resource files)
├── 3.181.0.openapi.yaml  (generated)
└── 3.181.0.openapi.json  (generated)
```

### Validation

Validate the OpenAPI specification:
```bash
# Using openapi-generator
openapi-generator validate -i capi/3.181.0.openapi.yaml

# Using swagger-cli
swagger-cli validate capi/3.181.0.openapi.yaml
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