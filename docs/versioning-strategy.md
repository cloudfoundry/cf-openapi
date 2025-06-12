# CAPI OpenAPI Specification Versioning Strategy

## Overview

This document defines the versioning strategy for the Cloud Foundry CAPI OpenAPI specifications. The strategy ensures consistent versioning, clear communication of changes, and smooth migration paths for API consumers.

## Version Alignment

### Primary Version Numbering
The OpenAPI specification version directly aligns with the CAPI API version:
- **Format**: `{capi_major}.{capi_minor}.{capi_patch}`
- **Example**: CAPI v3.195.0 → OpenAPI spec v3.195.0
- **Rationale**: Direct correlation makes it easy to identify which spec version corresponds to which API version

### Specification Revision Numbering
When the OpenAPI spec needs updates without a corresponding CAPI version change:
- **Format**: `{capi_version}-{revision}`
- **Example**: v3.195.0-1, v3.195.0-2
- **Use cases**:
  - Bug fixes in the spec generation
  - Enhancement of descriptions or examples
  - Addition of missing documentation
  - Schema refinements

## Semantic Versioning for Changes

### Breaking Changes
Changes that require client code modifications:
- Removal of endpoints
- Changes to required parameters
- Modifications to response structures
- Authentication mechanism changes
- **Action**: Major version bump in CAPI (unlikely in v3)

### Minor Changes
Backward-compatible functionality additions:
- New endpoints
- New optional parameters
- Additional response fields
- New enum values
- **Action**: Minor version bump (e.g., 3.195.0 → 3.196.0)

### Patch Changes
Backward-compatible fixes:
- Documentation corrections
- Example improvements
- Schema clarifications
- Bug fixes in spec generation
- **Action**: Patch version bump or revision increment

## Change Detection and Classification

### Automated Detection
The CI/CD pipeline automatically detects and classifies changes:

```bash
# Compare two versions
./bin/gen diff --old-version=3.194.0 --new-version=3.195.0
```

### Change Categories
1. **Endpoints**:
   - Added: New paths or methods
   - Removed: Deleted paths or methods (breaking)
   - Modified: Changed parameters or responses

2. **Schemas**:
   - Property additions (usually non-breaking)
   - Property removals (breaking)
   - Type changes (breaking)
   - Constraint modifications

3. **Parameters**:
   - New required parameters (breaking)
   - New optional parameters (non-breaking)
   - Parameter removals (breaking)

4. **Security**:
   - New authentication requirements (potentially breaking)
   - Modified scopes or permissions

## Changelog Generation

### Automated Changelog
Generated automatically from spec differences:

```markdown
# Changelog for v3.195.0

## Breaking Changes
- None

## New Features
- Added `/v3/app_features` endpoint for feature flag management
- New optional parameter `include` for `/v3/apps` endpoint

## Improvements
- Enhanced descriptions for service binding operations
- Added examples for pagination parameters

## Bug Fixes
- Fixed schema for docker package credentials
- Corrected required fields in update operations
```

### Manual Changelog Entries
For context and migration guidance:
- Explanation of breaking changes
- Migration examples
- Deprecation notices
- Links to relevant documentation

## Migration Guides

### Structure
Each breaking change requires a migration guide:

```markdown
# Migration Guide: v3.194.0 to v3.195.0

## Breaking Changes

### 1. Package Upload Endpoint Changes
**What changed**: The `/v3/packages/{guid}/upload` endpoint now requires Content-Type header

**Before**:
```bash
curl -X POST "/v3/packages/{guid}/upload" \
  -F bits=@app.zip
```

**After**:
```bash
curl -X POST "/v3/packages/{guid}/upload" \
  -H "Content-Type: multipart/form-data" \
  -F bits=@app.zip
```

**SDK Impact**: Update client code to include Content-Type header
```

### Location
Migration guides are stored in:
- `docs/migrations/v{old}_to_v{new}.md`
- Linked from main CHANGELOG.md
- Referenced in release notes

## Deprecation Handling

### Deprecation Process
1. **Mark as deprecated** in OpenAPI spec:
   ```yaml
   /v3/apps/{guid}/restage:
     post:
       deprecated: true
       x-deprecation-version: "3.195.0"
       x-removal-version: "3.200.0"
       description: "Deprecated. Use deployments for zero-downtime updates."
   ```

2. **Add deprecation notice** to operation description
3. **Include migration path** in documentation
4. **Set removal timeline** (minimum 3 minor versions)

### Deprecation Warnings
- Generated SDKs should emit deprecation warnings
- API responses include deprecation headers
- Documentation clearly marks deprecated features

## Version Publishing

### Release Process
1. **Generate new version**:
   ```bash
   ./bin/gen generate --version=3.195.0
   ```

2. **Run validation suite**:
   ```bash
   make validate VERSION=3.195.0
   ```

3. **Generate changelog**:
   ```bash
   ./bin/gen changelog --from=3.194.0 --to=3.195.0
   ```

4. **Create release**:
   - Git tag: `v3.195.0`
   - GitHub release with changelog
   - Update latest symlink

### Distribution Channels
- **GitHub Releases**: Primary distribution with changelog
- **npm Package**: `@cloudfoundry/capi-openapi-spec`
- **Direct URLs**: 
  - Latest: `https://api.github.com/repos/cloudfoundry-community/capi-openapi-spec/contents/capi/latest/openapi.yaml`
  - Specific: `https://api.github.com/repos/cloudfoundry-community/capi-openapi-spec/contents/capi/3.195.0/openapi.yaml`

## Backward Compatibility

### Compatibility Guarantee
- Minor and patch versions maintain backward compatibility
- Breaking changes only in major versions (rare for v3)
- Deprecation warnings provided at least 3 versions in advance

### Compatibility Testing
- SDK generation tests for previous 3 versions
- Contract tests against multiple CAPI versions
- Regression test suite for common use cases

## Version Support Policy

### Supported Versions
- **Latest**: Full support with updates
- **Latest - 1**: Security and critical bug fixes
- **Latest - 2**: Security fixes only
- **Older**: Best effort, community support

### End of Life (EOL)
- Announced 6 months in advance
- Migration guide to latest version
- Archived but still accessible

## Implementation Checklist

- [ ] Version comparison tool (`bin/gen diff`)
- [ ] Changelog generator (`bin/gen changelog`)
- [ ] Migration guide template
- [ ] Deprecation marking in parser
- [ ] Version support matrix documentation
- [ ] Automated compatibility testing

## Best Practices

1. **Communicate Early**: Announce deprecations as soon as planned
2. **Provide Examples**: Include code examples in migration guides
3. **Test Thoroughly**: Validate changes across multiple SDK languages
4. **Document Clearly**: Explain the why, not just the what
5. **Support Gracefully**: Maintain compatibility where possible

## Tools and Scripts

### Version Management Commands
```bash
# Compare versions
./bin/gen diff --old=3.194.0 --new=3.195.0

# Generate changelog
./bin/gen changelog --from=3.194.0 --to=3.195.0

# Check compatibility
./bin/gen check-compatibility --version=3.195.0

# List deprecated features
./bin/gen list-deprecations --version=3.195.0
```

### CI/CD Integration
The GitHub Actions workflow automatically:
- Detects version changes
- Generates changelogs
- Creates migration guides (if needed)
- Updates version references
- Publishes releases

## Summary

This versioning strategy ensures:
- Clear version alignment with CAPI
- Predictable change communication
- Smooth migration paths
- Long-term maintainability
- Developer-friendly updates

By following this strategy, we maintain a stable, reliable OpenAPI specification that evolves with the CAPI API while minimizing disruption for API consumers.