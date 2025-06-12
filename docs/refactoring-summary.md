# Refactoring Summary: Simplified Directory Structure

## Overview

The CAPI OpenAPI specification generation pipeline has been refactored to use a simplified directory structure that eliminates the `generated/` and `enhanced/` subdirectories. All artifacts are now generated directly into `capi/<version>/`.

## Changes Made

### 1. Directory Structure

**Before:**
```
capi/
  3.195.0/
    generated/
      openapi.json
      openapi.yaml
      generation-report.md
    enhanced/
      openapi.json
      openapi.yaml
      enhancement-report.md
      validation-reports...
```

**After:**
```
capi/
  3.195.0/
    openapi.json          # Final enhanced specification
    openapi.yaml          # Final enhanced specification
    generation-report.md  # HTML parsing report
    enhancement-report.md # Enhancement statistics
    final-report.md       # Overall generation report
    *.backup-*            # Backup files when enhanced in-place
```

### 2. Command Changes

**Renamed commands for clarity:**
- `./bin/gen generate` → `./bin/gen spec` (generates OpenAPI specification)
- `./bin/gen --version=X --language=Y` → `./bin/gen sdk --version=X --language=Y` (generates SDK)

### 3. Script Updates

#### bin/gen
- `parse_html_to_openapi()`: Now outputs directly to `capi/<version>/`
- `enhance_spec()`: Uses `--inplace` flag to enhance files in the same directory
- `validate_spec()`: Looks for files in `capi/<version>/`
- `generate_final_report()`: Saves report in `capi/<version>/`
- `generate_sdk()`: Reads spec from `capi/<version>/openapi.json`

#### bin/enhance-spec
- Added `--inplace` option for in-place enhancement
- Creates backup files before overwriting (`.backup-<timestamp>`)
- Auto-detects output directory as input directory when `--inplace` is used

#### bin/validate-spec
- Removed `--type` parameter (no longer needed)
- Always looks in `capi/<version>/` for the specification

### 4. Workflow

The new workflow is simpler and more intuitive:

```bash
# Generate complete OpenAPI specification
./bin/gen spec --version=3.195.0

# Generate SDK from the specification
./bin/gen sdk --version=3.195.0 --language=go

# Individual steps still available:
./bin/gen parse --version=3.195.0    # Parse HTML only
./bin/gen validate --version=3.195.0 # Validate only
```

### 5. Benefits

1. **Simpler directory structure**: Easier to understand and navigate
2. **In-place enhancement**: Reduces file duplication
3. **Clearer commands**: `spec` and `sdk` are more intuitive than `generate`
4. **Consistent output location**: All files in one directory per version
5. **Backup safety**: Original files backed up during enhancement

### 6. Migration

For existing installations:
1. The old structure (`generated/` and `enhanced/` subdirectories) still works
2. New generations will use the simplified structure
3. Old directories can be safely removed after verification

### 7. Testing

To test the new structure:
```bash
# Dry run to see what would happen
./bin/gen spec --version=3.195.0 --dry-run --verbose

# Full generation
./bin/gen spec --version=3.195.0

# SDK generation
./bin/gen sdk --version=3.195.0 --language=python
```

## Summary

This refactoring simplifies the CAPI OpenAPI generation process by consolidating all outputs into a single directory per version, making the tool easier to use and understand while maintaining all functionality.