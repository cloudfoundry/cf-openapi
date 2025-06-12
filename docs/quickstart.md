# CAPI OpenAPI Quick Start Guide

## Complete Working Example

Generate a CAPI OpenAPI specification and Go SDK:

```bash
# 1. Generate OpenAPI specification (JSON is now the default format)
# This automatically fixes type issues and deduplicates parameters
./bin/gen spec --version=3.195.0

# 2. Generate Go SDK using oapi-codegen (default for Go)
./bin/gen sdk --version=3.195.0 --language=go

# Or use openapi-generator if preferred
./bin/gen sdk --version=3.195.0 --language=go --generator=openapi-generator

# SDK will be created in: sdk/3.195.0/go/capiclient/
```

## Directory Structure

After generation, you'll have:
```
capi/3.195.0/
  openapi.json              # Enhanced OpenAPI specification
  openapi.yaml              # YAML version (may have Unicode issues)
  generation-report.md      # HTML parsing report
  enhancement-report.md     # Enhancement statistics
  final-report.md          # Overall generation report

sdk/3.195.0/go/capiclient/
  go.mod                   # Go module file
  client.go                # Main client
  api_overview.go          # All API methods
  model_*.go              # Data models
  docs/                    # API documentation
```

## Known Issues & Solutions

### 1. Unicode/Control Characters
**Problem**: YAML parsing fails with "control characters are not allowed"
**Solution**: JSON is now the default format. To explicitly use YAML:
```bash
./bin/gen spec --version=3.195.0 --format=yaml
```
Note: JSON format is recommended to avoid Unicode issues.

### 2. Boolean Type Errors
**Problem**: SDK generation fails with "cannot unmarshal string into field of type bool"
**Solution**: This is now automatically fixed during spec generation. If you still encounter issues:
```bash
./bin/fix-spec-types --input=capi/3.195.0/openapi.json
```

### 3. Duplicate Parameter Errors (oapi-codegen)
**Problem**: oapi-codegen fails with "duplicate local parameter"
**Solution**: This is now automatically fixed during spec enhancement. The spec generation process deduplicates parameters.

## Using the Generated Go SDK

```go
package main

import (
    "context"
    "fmt"
    capiclient "github.com/cloudfoundry-community/capi-openapi-go-client/capiclient"
)

func main() {
    // Create configuration
    cfg := capiclient.NewConfiguration()
    cfg.Host = "api.cf.example.com"
    cfg.Scheme = "https"
    
    // Create client
    client := capiclient.NewAPIClient(cfg)
    
    // Example: List organizations
    orgs, _, err := client.OverviewApi.GetOrganizations(context.Background()).Execute()
    if err != nil {
        panic(err)
    }
    
    fmt.Printf("Found %d organizations\n", len(orgs.Resources))
}
```

## Other Language SDKs

Generate SDKs for other languages:
```bash
# Python
./bin/gen sdk --version=3.195.0 --language=python

# Java
./bin/gen sdk --version=3.195.0 --language=java

# Ruby
./bin/gen sdk --version=3.195.0 --language=ruby

# TypeScript
./bin/gen sdk --version=3.195.0 --language=typescript-fetch
```

## Validation (Optional)

The spec will have validation warnings but still works:
```bash
# Run Spectral validation (expect warnings about string vs boolean types)
./bin/validate-spec --version=3.195.0

# Test examples
./bin/validate-examples capi/3.195.0/openapi.json
```

## Tips

1. **JSON is now the default format** to avoid Unicode issues
2. **Type fixes are automatic** during spec generation
3. **oapi-codegen is now the default** for Go SDK generation
4. **Check the generation reports** for any issues
5. **Backup files are created** with .backup-* suffix during enhancement

## Complete One-Liner

```bash
# Using oapi-codegen (default for Go)
./bin/gen spec --version=3.195.0 && \
./bin/gen sdk --version=3.195.0 --language=go

# Or using openapi-generator
./bin/gen spec --version=3.195.0 && \
./bin/gen sdk --version=3.195.0 --language=go --generator=openapi-generator
```