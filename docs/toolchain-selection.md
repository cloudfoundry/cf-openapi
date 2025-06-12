# Toolchain Selection for CAPI OpenAPI Generation

## Executive Summary

After thorough evaluation, the selected toolchain for generating OpenAPI specifications from CAPI HTML documentation consists of:

1. **HTML Parser**: Mojo::DOM (Perl)
2. **YAML Processing**: Existing Spruce tool
3. **JSON Schema Generation**: JSON::Schema::Draft07 (Perl)
4. **OpenAPI Generation**: OpenAPI Generator CLI (existing)
5. **Validation**: Spectral (Node.js)
6. **Testing**: Custom Perl test harness + Dredd

## Detailed Tool Selection

### 1. HTML Parsing: Mojo::DOM

**Selected**: Mojo::DOM from Mojolicious framework

**Justification**:
- **Native Perl**: Seamless integration with existing `bin/gen` script
- **Modern API**: jQuery-like selectors for intuitive parsing
- **Performance**: C-based parser handles 3MB+ HTML files efficiently
- **JSON Support**: Built-in JSON parsing for embedded examples
- **Active Maintenance**: Part of well-maintained Mojolicious project
- **CSS Selectors**: Full support for complex selections needed for CAPI

**Installation**:
```bash
cpan Mojolicious
# or
cpanm Mojolicious
```

### 2. YAML Processing: Spruce (Existing)

**Retained**: Current Spruce implementation

**Justification**:
- Already integrated and working well
- Handles YAML merging requirements
- No need to change what works

### 3. JSON Schema Generation: JSON::Schema::Draft07

**Selected**: JSON::Schema::Draft07 module

**Justification**:
- **Perl Native**: Maintains language consistency
- **Schema Inference**: Can generate schemas from JSON examples
- **OpenAPI Compatible**: Outputs Draft-07 schemas compatible with OpenAPI 3.0
- **Validation**: Built-in validation capabilities

**Alternative**: JSON::Schema::Modern (if Draft07 has issues)

### 4. OpenAPI Structure Generation: Custom Perl Implementation

**Approach**: Build OpenAPI structure in Perl using hash references

**Justification**:
- Full control over output structure
- Direct mapping from parsed HTML
- Easy handling of edge cases
- No external dependencies

**Libraries**:
- `YAML::XS` for YAML output
- `JSON::XS` for JSON output
- `Data::Dumper` for debugging

### 5. Validation: Spectral

**Selected**: Spectral CLI (Node.js-based)

**Justification**:
- Industry standard for OpenAPI linting
- Extensive built-in rules
- Custom rule support for CAPI-specific requirements
- CI/CD friendly
- Already used in many OpenAPI workflows

**Installation**:
```bash
npm install -g @stoplight/spectral-cli
```

### 6. Contract Testing: Dredd + Custom Tests

**Primary**: Custom Perl test harness
**Secondary**: Dredd for contract testing

**Justification**:
- Custom tests for CAPI-specific validations
- Dredd for standard contract testing
- Perl tests integrate with generation pipeline
- Can mock CAPI responses for testing

## Toolchain Architecture

```
┌─────────────────────┐
│  CAPI HTML Doc     │
│ (3.195.0.html)     │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  Mojo::DOM Parser   │ ← Perl
│  (Extract Content)  │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  Schema Generator   │ ← JSON::Schema::Draft07
│  (From Examples)    │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  OpenAPI Builder    │ ← Custom Perl
│  (Structure Gen)    │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  YAML/JSON Output   │ ← YAML::XS / JSON::XS
│  (File Generation)  │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  Validation Suite   │
├─────────────────────┤
│ • Spectral Linting  │ ← Node.js
│ • Schema Validation │ ← Perl
│ • Contract Tests    │ ← Dredd
└─────────────────────┘
```

## Implementation Strategy

### Phase 1: Core Parser Development
1. Implement Mojo::DOM parser for endpoint extraction
2. Build parameter table parser
3. Create JSON example extractor
4. Generate basic OpenAPI structure

### Phase 2: Schema Generation
1. Implement JSON to JSON Schema converter
2. Handle nested objects and arrays
3. Add type inference logic
4. Generate reusable component schemas

### Phase 3: Edge Case Handling
1. Implement polymorphic type handlers
2. Add conditional parameter logic
3. Handle shared path endpoints
4. Process special query parameters

### Phase 4: Validation Layer
1. Set up Spectral with custom rules
2. Implement schema validation tests
3. Add example validation
4. Create contract test suite

## Dependencies Summary

### Perl Modules (via CPAN)
```
Mojolicious
JSON::Schema::Draft07
YAML::XS
JSON::XS
Test::More
Test::Deep
```

### System Dependencies
```
perl >= 5.20
node >= 14 (for Spectral)
java (for OpenAPI Generator CLI)
```

### Development Tools
```
cpanm (for Perl module installation)
npm (for Node.js tools)
make (existing)
```

## Risk Mitigation

1. **Mojolicious Too Heavy**: Fall back to Web::Scraper
2. **Schema Generation Issues**: Use online schema inference as backup
3. **Performance Problems**: Implement streaming parser
4. **Validation Failures**: Progressive validation with detailed logging

## Maintenance Considerations

1. **Version Pinning**: Lock all tool versions in requirements
2. **Docker Option**: Create Docker image with all dependencies
3. **Documentation**: Maintain setup guides for all platforms
4. **Testing**: Comprehensive test suite for parser components

## Conclusion

This toolchain provides:
- **Consistency**: Primarily Perl-based matching existing tools
- **Power**: Modern parsing and schema generation
- **Reliability**: Well-maintained dependencies
- **Flexibility**: Handles all CAPI edge cases
- **Validation**: Comprehensive testing capabilities

The selection prioritizes minimal disruption to the existing workflow while adding powerful parsing and generation capabilities necessary for accurate OpenAPI specification generation.