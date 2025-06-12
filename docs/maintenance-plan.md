# CAPI OpenAPI Specification Maintenance Plan

## Overview

This document outlines the maintenance strategy for keeping the CAPI OpenAPI specification synchronized with the official Cloud Foundry CAPI documentation. The plan ensures timely updates, minimal manual intervention, and consistent quality.

## Maintenance Components

### 1. Change Detection System

#### HTML Diff Detection
- **Tool**: `bin/detect-changes`
- **Purpose**: Monitor CAPI documentation for updates
- **Methods**:
  - SHA-256 hash comparison for quick change detection
  - Content diff analysis for detailed change reports
  - Version comparison between CAPI releases

#### Usage
```bash
# Monitor current version for changes
./bin/detect-changes --check-url=https://v3-apidocs.cloudfoundry.org/version/3.195.0/index.html

# Compare two versions
./bin/detect-changes --old-version=3.195.0 --new-version=3.196.0

# Generate JSON output for automation
./bin/detect-changes --old-version=3.195.0 --new-version=3.196.0 --json
```

### 2. Automated Update Process

#### Pull Request Automation
- **Tool**: `bin/create-update-pr`
- **Purpose**: Automatically create PRs for specification updates
- **Features**:
  - Branch creation and management
  - OpenAPI generation pipeline execution
  - Automated commit messages
  - PR creation with detailed descriptions
  - Optional auto-merge for non-breaking changes

#### Usage
```bash
# Create update PR
./bin/create-update-pr --version=3.196.0

# Create draft PR with changes report
./bin/create-update-pr --version=3.196.0 --draft \
    --changes-file=change-reports/changes-3.195.0-to-3.196.0.md

# Enable auto-merge for simple updates
./bin/create-update-pr --version=3.196.0 --auto-merge
```

### 3. Update Workflow

#### Daily Monitoring
1. **GitHub Action**: `check-updates.yml` runs daily at 3 AM UTC
2. **Process**:
   ```
   Check for changes → Detect differences → Create issue → Trigger update
   ```

#### Weekly Generation
1. **GitHub Action**: `generate-spec.yml` runs weekly on Mondays
2. **Process**:
   ```
   Generate spec → Validate → Create PR → Run tests → Request review
   ```

### 4. Change Impact Analysis

#### Breaking Change Detection
- Removed endpoints
- Changed required parameters
- Modified response structures
- Authentication changes

#### Non-Breaking Changes
- New endpoints
- Additional optional parameters
- Enhanced descriptions
- New examples

#### Classification Process
1. Run diff analysis
2. Categorize changes
3. Determine version bump needed
4. Create appropriate documentation

### 5. Update Procedures

#### Routine Updates (Non-Breaking)
1. **Detection**: Automated monitoring detects changes
2. **Generation**: CI/CD runs generation pipeline
3. **Validation**: Automated tests verify specification
4. **Review**: Quick review for non-breaking changes
5. **Merge**: Auto-merge if all checks pass

#### Breaking Change Updates
1. **Detection**: Manual review of breaking changes
2. **Migration Guide**: Create before proceeding
3. **Generation**: Run with special handling
4. **Testing**: Extended validation including SDK tests
5. **Review**: Thorough review by maintainers
6. **Communication**: Announce to community
7. **Merge**: Coordinated release

### 6. Quality Assurance

#### Pre-Merge Checks
- Spectral linting (OpenAPI best practices)
- Example validation (schema compliance)
- Contract testing (API compatibility)
- SDK generation (multiple languages)
- Regression testing (no functionality loss)

#### Post-Merge Actions
- Tag release
- Update version references
- Publish to distribution channels
- Update documentation
- Notify stakeholders

### 7. Rollback Procedures

#### When to Rollback
- Critical generation errors
- Breaking changes without migration path
- Significant regression in quality
- Community-reported issues

#### Rollback Process
```bash
# Quick rollback to previous version
./bin/gen rollback --version=3.195.0

# Manual rollback steps
git checkout main
git pull origin main
git revert <commit-hash>
git push origin main
```

### 8. Maintenance Schedule

#### Daily Tasks
- Monitor CAPI documentation for changes
- Check CI/CD pipeline health
- Review automated issue creation

#### Weekly Tasks
- Run full generation pipeline
- Review and merge routine updates
- Update dependencies if needed

#### Monthly Tasks
- Review maintenance procedures
- Analyze update metrics
- Plan for upcoming CAPI releases
- Community feedback review

#### Quarterly Tasks
- Full system audit
- Performance optimization
- Tool updates and improvements
- Documentation review

### 9. Escalation Procedures

#### Level 1: Automated Handling
- Non-breaking changes
- Successful validation
- No manual intervention needed

#### Level 2: Maintainer Review
- Breaking changes detected
- Validation warnings
- SDK generation issues

#### Level 3: Community Discussion
- Major API changes
- Significant breaking changes
- Architecture decisions needed

### 10. Metrics and Monitoring

#### Key Metrics
- Time to detect changes: < 24 hours
- Time to generate update: < 30 minutes
- Time to merge (non-breaking): < 48 hours
- Time to merge (breaking): < 1 week
- Specification accuracy: > 99%
- Test coverage: > 95%

#### Monitoring Dashboard
- Update frequency
- Change types distribution
- Generation success rate
- Validation pass rate
- Community engagement

## Tools and Scripts

### Core Maintenance Tools
```bash
# Change detection
./bin/detect-changes --check-url=<url>

# Create update PR
./bin/create-update-pr --version=<version>

# Full generation pipeline
./bin/gen generate --version=<version>

# Validation suite
make validate VERSION=<version>

# Rollback changes
./bin/gen rollback --version=<version>
```

### GitHub Actions
- `.github/workflows/check-updates.yml` - Daily monitoring
- `.github/workflows/generate-spec.yml` - Weekly generation
- `.github/workflows/validate-pr.yml` - PR validation
- `.github/workflows/test-sdks.yml` - SDK testing

## Best Practices

1. **Automate Everything**: Minimize manual intervention
2. **Fail Fast**: Detect issues early in the pipeline
3. **Document Changes**: Clear commit messages and PR descriptions
4. **Test Thoroughly**: Multiple validation layers
5. **Communicate Clearly**: Keep community informed
6. **Monitor Continuously**: Track metrics and improve

## Troubleshooting

### Common Issues

#### Generation Failures
- Check HTML structure changes
- Verify parser compatibility
- Review error logs
- Run in verbose mode

#### Validation Errors
- Check for schema violations
- Verify example compliance
- Review breaking changes
- Update edge case handlers

#### PR Creation Issues
- Verify GitHub permissions
- Check branch conflicts
- Review CI/CD logs
- Ensure clean working tree

## Success Criteria

- **Accuracy**: 100% endpoint coverage
- **Timeliness**: Updates within 48 hours
- **Quality**: All validations passing
- **Automation**: < 10% manual intervention
- **Reliability**: > 99% uptime for automation

## Continuous Improvement

- Regular review of maintenance procedures
- Community feedback integration
- Tool enhancement based on usage
- Process optimization for efficiency
- Documentation updates as needed

By following this maintenance plan, we ensure the CAPI OpenAPI specification remains accurate, up-to-date, and valuable for the Cloud Foundry community.