# CAPI OpenAPI Specification Generation Process

This document provides a comprehensive guide for generating the Cloud Foundry CAPI v3 OpenAPI specification from the official HTML documentation.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Quick Start](#quick-start)
3. [Step-by-Step Generation Guide](#step-by-step-generation-guide)
4. [Validation Procedures](#validation-procedures)
5. [Troubleshooting Guide](#troubleshooting-guide)
6. [FAQ](#faq)
7. [Architecture Overview](#architecture-overview)
8. [Advanced Topics](#advanced-topics)

## Prerequisites

### System Requirements

- **Operating System**: macOS, Linux (Windows via WSL)
- **Perl**: Version 5.10 or higher
- **Node.js**: Version 14 or higher (for validation tools)
- **Java**: JDK 8 or higher (for OpenAPI Generator)
- **Git**: For version control

### Required Tools

Install the following tools before beginning:

```bash
# Install Perl dependencies
cpanm --installdeps .

# Install Node.js dependencies
bun install  # or npm install

# Install system dependencies
make deps
```

### Verify Installation

```bash
# Check all dependencies
make check-deps

# Test Perl modules
perl -MMojolicious -e 'print "Mojolicious installed\n"'
perl -MJSON::XS -e 'print "JSON::XS installed\n"'
perl -MYAML::XS -e 'print "YAML::XS installed\n"'

# Test Node.js tools
bunx spectral --version
```

## Quick Start

For experienced users, here's the fastest way to generate the specification:

```bash
# 1. Download CAPI HTML documentation
./bin/gen prepare --version=3.195.0

# 2. Generate OpenAPI specification from HTML
./bin/parse-html specs/capi/3.195.0.html > capi/3.195.0/generated/openapi.yaml

# 3. Apply enhancements and best practices
./bin/enhance-spec capi/3.195.0/generated/openapi.yaml

# 4. Validate the specification
./bin/validate-spec 3.195.0

# 5. Run all tests
./bin/test-schemas
./bin/validate-examples
./bin/test-common-issues
```

## Step-by-Step Generation Guide

### Step 1: Download CAPI Documentation

The first step is to download the official CAPI HTML documentation:

```bash
./bin/gen prepare --version=3.195.0
```

This command:
- Downloads the CAPI HTML documentation to `specs/capi/3.195.0.html`
- Creates the necessary directory structure
- Prepares the environment for parsing

**Verify**: Check that `specs/capi/3.195.0.html` exists and contains the full documentation.

### Step 2: Parse HTML to OpenAPI Structure

Use the HTML parser to extract the API specification:

```bash
./bin/parse-html specs/capi/3.195.0.html > capi/3.195.0/generated/openapi.yaml
```

The parser will:
- Extract all 240 endpoints from the documentation
- Infer JSON schemas from examples
- Handle edge cases (polymorphic types, custom headers)
- Generate a valid OpenAPI 3.0.3 structure

**What happens during parsing:**
1. **Endpoint Extraction**: Finds all API endpoints using CSS selectors
2. **Parameter Detection**: Extracts path, query, and header parameters
3. **Schema Inference**: Analyzes JSON examples to create schemas
4. **Edge Case Handling**: Applies special rules for known patterns
5. **Component Creation**: Builds reusable schemas and parameters

**Common parsing patterns:**
- Endpoint definitions: `<h4 id="definition">` followed by method and path
- Parameters: Tables with Name, Type, Description columns
- Examples: JSON blocks in `<pre>` tags
- Security: "Permitted roles" sections

### Step 3: Review Generated Specification

Before enhancement, review the generated specification:

```bash
# Check structure and endpoint count
grep -c "operationId" capi/3.195.0/generated/openapi.yaml

# Validate basic structure
bunx spectral lint capi/3.195.0/generated/openapi.yaml

# Review specific endpoints
less capi/3.195.0/generated/openapi.yaml
```

**What to look for:**
- All expected endpoints are present
- Parameters are correctly typed
- Request/response bodies have schemas
- Polymorphic types use oneOf
- Special headers are included

### Step 4: Enhance the Specification

Apply OpenAPI best practices and improvements:

```bash
./bin/enhance-spec capi/3.195.0/generated/openapi.yaml
```

This enhancement process:
1. **Improves Operation IDs**: Creates SDK-friendly names
2. **Adds Descriptions**: Enhances parameters and responses
3. **Includes Examples**: Adds realistic examples for parameters
4. **Organizes Tags**: Groups endpoints by resource type
5. **Standardizes Responses**: Adds common headers and error formats
6. **Updates Metadata**: Adds contact, license, and documentation links

**Output files:**
- `capi/3.195.0/enhanced/openapi.yaml` - Enhanced YAML specification
- `capi/3.195.0/enhanced/openapi.json` - JSON format
- `capi/3.195.0/enhanced/enhancement-report.md` - Summary of changes

### Step 5: Validate the Specification

Run comprehensive validation tests:

```bash
# 1. Spectral linting with custom CAPI rules
./bin/validate-spec 3.195.0

# 2. Validate all examples against schemas
./bin/validate-examples

# 3. Check for common issues
./bin/test-common-issues

# 4. Test schema definitions
./bin/test-schemas
```

**Expected results:**
- Spectral: Some warnings about missing examples (normal)
- Examples: 100% pass rate
- Common issues: ~86% pass rate (GUID format warnings are known)
- Schemas: All component schemas valid

### Step 6: Generate Client SDKs (Optional)

Test the specification by generating client libraries:

```bash
# Generate Go client
./bin/gen --version=3.195.0 --language=go

# Generate Python client
./bin/gen --version=3.195.0 --language=python

# Test SDK generation for multiple languages
./bin/integration-test
```

### Step 7: Test Against Live API (Optional)

If you have access to a Cloud Foundry instance:

```bash
# Configure CF credentials
cf login
cf target -o your-org -s your-space

# Run live API tests
./bin/test-live-api-curl --cf-config=~/cf/config.json

# Test application lifecycle
./bin/test-app-lifecycle
```

## Validation Procedures

### Required Validations

1. **Structural Validation**
   ```bash
   ./bin/validate-spec 3.195.0
   ```
   - Checks OpenAPI structure compliance
   - Validates CAPI-specific rules
   - Ensures consistent naming

2. **Example Validation**
   ```bash
   ./bin/validate-examples
   ```
   - Tests all examples against schemas
   - Validates parameter examples
   - Checks response examples

3. **Schema Validation**
   ```bash
   ./bin/test-schemas
   ```
   - Validates component schemas
   - Tests schema references
   - Checks for circular references

### Optional Validations

1. **Common Issues Check**
   ```bash
   ./bin/test-common-issues
   ```
   - Data type consistency
   - Required field validation
   - Naming convention compliance

2. **Contract Testing**
   ```bash
   ./bin/contract-test --dry-run
   ```
   - Tests endpoint structure
   - Validates request/response format
   - Checks authentication flows

3. **SDK Validation**
   ```bash
   ./bin/integration-test
   ```
   - Tests SDK generation
   - Validates compilation
   - Basic functionality tests

### Interpreting Validation Results

**Spectral Output:**
- ❌ Errors: Must be fixed (e.g., invalid OpenAPI structure)
- ⚠️  Warnings: Should be reviewed (e.g., missing examples)
- ℹ️  Info: Best practice suggestions

**Common Known Issues:**
1. **GUID Format**: Parameters may lack UUID format specification
2. **Response Codes**: Some standard HTTP codes may be missing
3. **Root Paths**: / and /v3 don't follow /v3/* pattern (by design)

## Troubleshooting Guide

### Common Issues and Solutions

#### 1. Unicode/Character Encoding Errors

**Problem**: YAML generation fails with "Wide character" errors

**Solution**:
```bash
# Use JSON format instead
./bin/parse-html specs/capi/3.195.0.html --format=json > capi/3.195.0/generated/openapi.json

# Or ensure proper encoding
export PERL_UNICODE=SDA
```

#### 2. Missing Endpoints

**Problem**: Some endpoints are missing from the generated spec

**Solution**:
1. Check HTML structure hasn't changed:
   ```bash
   grep -A5 "definition.*POST.*apps" specs/capi/3.195.0.html
   ```
2. Review parser selectors in `bin/lib/CAPI/HTMLParser.pm`
3. Add debug output:
   ```bash
   ./bin/parse-html specs/capi/3.195.0.html --verbose
   ```

#### 3. Schema Validation Failures

**Problem**: Examples don't validate against schemas

**Solution**:
1. Check for schema inference issues:
   ```bash
   ./bin/validate-examples --verbose
   ```
2. Manually review the problematic schema
3. Update edge case handling if needed

#### 4. Perl Module Issues

**Problem**: Can't locate module errors

**Solution**:
```bash
# Reinstall dependencies
cpanm --installdeps . --force

# Check module installation
perl -MMojolicious -e 'print $Mojolicious::VERSION'
```

### Debug Mode

Enable verbose output for detailed debugging:

```bash
# Parser debugging
CAPI_DEBUG=1 ./bin/parse-html specs/capi/3.195.0.html

# Validation debugging
./bin/validate-examples --verbose
./bin/test-common-issues --verbose

# Enhancement debugging
./bin/enhance-spec capi/3.195.0/generated/openapi.yaml --verbose
```

## FAQ

### Q: How long does the generation process take?

A: The complete process typically takes:
- HTML parsing: 2-3 minutes
- Enhancement: 1-2 minutes
- Validation: 3-5 minutes
- Total: ~10 minutes

### Q: Can I update just specific endpoints?

A: Currently, the process regenerates the entire specification. For minor updates, you can manually edit the enhanced specification.

### Q: How do I handle CAPI documentation updates?

A: When CAPI releases a new version:
1. Download the new HTML documentation
2. Run the generation process with the new version
3. Compare with the previous version using diff tools
4. Review and validate changes

### Q: What if the HTML structure changes?

A: If CAPI changes their documentation format:
1. Update CSS selectors in `bin/lib/CAPI/HTMLParser.pm`
2. Adjust edge case handlers as needed
3. Re-run the generation process
4. Update this documentation

### Q: Can I customize the generation?

A: Yes, you can:
1. Modify edge case rules in `bin/lib/CAPI/EdgeCaseHandler.pm`
2. Adjust enhancement rules in `bin/enhance-spec`
3. Add custom Spectral rules in `config/.spectral.yml`
4. Create additional validation scripts

## Architecture Overview

### Component Structure

```
┌─────────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│   CAPI HTML Docs   │────▶│   HTML Parser    │────▶│ OpenAPI Struct  │
└─────────────────────┘     └──────────────────┘     └─────────────────┘
                                     │                         │
                                     ▼                         ▼
                            ┌──────────────────┐     ┌─────────────────┐
                            │ Edge Case Handler│     │    Enhancer     │
                            └──────────────────┘     └─────────────────┘
                                                              │
                                                              ▼
                                                     ┌─────────────────┐
                                                     │ Enhanced Spec   │
                                                     └─────────────────┘
```

### Key Modules

1. **HTMLParser.pm**: Core parsing logic using Mojo::DOM
2. **SchemaExtractor.pm**: Advanced schema inference
3. **EdgeCaseHandler.pm**: Special case handling
4. **enhance-spec**: Best practices application
5. **Validation Suite**: Multiple validation tools

### Data Flow

1. **Input**: HTML documentation with embedded examples
2. **Parsing**: CSS selector-based extraction
3. **Transformation**: HTML elements to OpenAPI components
4. **Enhancement**: Apply best practices and standards
5. **Output**: Valid OpenAPI 3.0.3 specification

## Advanced Topics

### Custom Edge Case Handling

To add a new edge case:

1. Identify the pattern in the HTML
2. Add detection logic to `EdgeCaseHandler.pm`
3. Implement the transformation
4. Add tests for the edge case

Example:
```perl
sub handle_new_edge_case {
    my ($self, $endpoint, $spec) = @_;
    
    if ($endpoint->{path} =~ /special_pattern/) {
        # Apply custom transformation
        $endpoint->{requestBody} = $self->create_special_body();
    }
}
```

### Extending the Parser

To extract additional information:

1. Add new methods to `HTMLParser.pm`
2. Update the main parsing loop
3. Include in the OpenAPI output
4. Update validation tests

### Performance Optimization

For large documentation files:

1. Use streaming parsing (experimental)
2. Parallelize endpoint processing
3. Cache parsed results
4. Optimize regex patterns

### Integration with CI/CD

See the [CI/CD setup guide](.github/workflows/README.md) for:
- Automated generation on schedule
- PR validation workflows
- Version comparison reports
- Deployment automation

## Maintenance

### Regular Tasks

1. **Weekly**: Check for CAPI updates
2. **Monthly**: Review and update edge cases
3. **Quarterly**: Update dependencies and tools
4. **Yearly**: Major process review

### Version Updates

When updating to a new CAPI version:

1. Download new documentation
2. Run generation process
3. Compare with previous version
4. Document any breaking changes
5. Update SDK examples
6. Notify users of changes

### Contributing

To contribute improvements:

1. Fork the repository
2. Create a feature branch
3. Add tests for changes
4. Update documentation
5. Submit a pull request

## Support

For issues or questions:

1. Check this documentation
2. Review [troubleshooting](#troubleshooting-guide)
3. Search existing GitHub issues
4. Create a new issue with:
   - CAPI version
   - Error messages
   - Steps to reproduce
   - Expected vs actual behavior

## Appendix

### Useful Commands Reference

```bash
# Full regeneration
make all VERSION=3.195.0

# Parse only
./bin/parse-html specs/capi/3.195.0.html

# Enhance only
./bin/enhance-spec capi/3.195.0/generated/openapi.yaml

# Validate everything
./bin/validate-spec 3.195.0 && ./bin/validate-examples && ./bin/test-schemas

# Generate specific SDK
./bin/gen --version=3.195.0 --language=go

# Compare versions
diff -u capi/3.194.0/enhanced/openapi.yaml capi/3.195.0/enhanced/openapi.yaml

# Extract specific endpoint
yq '.paths./v3/apps.get' capi/3.195.0/enhanced/openapi.yaml
```

### File Structure Reference

```
capi-openapi-spec/
├── bin/                      # Executable scripts
│   ├── parse-html           # Main parser
│   ├── enhance-spec         # Enhancement script
│   ├── validate-spec        # Validation runner
│   └── lib/                 # Perl modules
│       └── CAPI/           # CAPI-specific modules
├── capi/                    # Generated specifications
│   └── 3.195.0/
│       ├── generated/       # Raw parsed output
│       └── enhanced/        # Enhanced specification
├── specs/                   # Source documentation
│   └── capi/
│       └── 3.195.0.html    # CAPI HTML docs
├── docs/                    # Documentation
├── test/                    # Test files
└── config/                  # Configuration files
    ├── .spectral.yml       # Validation rules
    ├── openapi-generator-config.yml
    ├── openapitools.json
    └── dredd.yml
```