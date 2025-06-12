# CAPI Release Monitoring System

## Overview

The CAPI Release Monitoring System continuously watches for new Cloud Foundry CAPI releases and automatically triggers the OpenAPI specification update process. This ensures our specifications stay synchronized with the latest CAPI versions.

## Components

### 1. Release Monitor Script

**Location**: `bin/monitor-releases`

**Features**:
- Monitors multiple sources for CAPI releases
- Detects version changes
- Sends notifications through various channels
- Creates GitHub issues for tracking
- Triggers update workflows

**Data Sources**:
1. **GitHub Releases API**: Official CAPI releases
2. **RSS/Atom Feed**: Release announcements
3. **Documentation Page**: Version updates

### 2. GitHub Actions Workflow

**Location**: `.github/workflows/monitor-releases.yml`

**Schedule**: Runs hourly (configurable)

**Actions**:
1. Check for new releases
2. Create tracking issues
3. Trigger generation workflow
4. Send notifications
5. Cache monitoring state

### 3. Notification Channels

#### GitHub Issues
- Automatically created for each new version
- Tagged with `capi-update` and `automated`
- Includes release details and action items

#### Slack Integration
- Real-time notifications to team channels
- Rich formatting with version details
- Direct links to releases

#### Webhooks
- Custom webhook support for integrations
- JSON payload with update details
- Configurable endpoints

#### Email Notifications
- Optional email alerts
- Summary of changes
- Links to documentation

## Configuration

### Local Configuration

Create `.monitoring/config.json`:
```json
{
    "github_token": "ghp_xxxxxxxxxxxx",
    "github_repo": "cloudfoundry-community/capi-openapi-spec",
    "create_issues": true,
    "monitoring_interval": 3600,
    "slack_channel": "#capi-updates",
    "notification_emails": ["team@example.com"]
}
```

### Environment Variables

```bash
# GitHub authentication
export GITHUB_TOKEN="ghp_xxxxxxxxxxxx"

# Slack webhook URL
export SLACK_WEBHOOK="https://hooks.slack.com/services/xxx/yyy/zzz"

# Custom webhook endpoint
export WEBHOOK_URL="https://example.com/capi-webhook"
```

### GitHub Secrets

Required for GitHub Actions:
- `GITHUB_TOKEN`: Repository access (provided by GitHub)
- `SLACK_WEBHOOK`: Slack notification URL (optional)
- `WEBHOOK_URL`: Custom webhook endpoint (optional)

## Usage

### Manual Monitoring

```bash
# Check for updates
./bin/monitor-releases

# Check without saving state or sending notifications
./bin/monitor-releases --check-only

# Verbose output
./bin/monitor-releases --verbose

# JSON output for scripting
./bin/monitor-releases --json
```

### Automated Monitoring

The GitHub Actions workflow runs automatically every hour. You can also trigger it manually:

1. Go to Actions tab in GitHub
2. Select "Monitor CAPI Releases"
3. Click "Run workflow"
4. Choose options (check only, etc.)

### Custom Notifications

```bash
# With Slack webhook
./bin/monitor-releases --slack=https://hooks.slack.com/services/xxx

# With custom webhook
./bin/monitor-releases --webhook=https://example.com/webhook

# With email notification
./bin/monitor-releases --email=team@example.com
```

## Monitoring State

### State File

Location: `.monitoring/state.json`

Contains:
- Last checked versions
- Last check timestamps
- Update history

Example:
```json
{
    "CAPI GitHub Releases": {
        "last_version": "3.195.0",
        "last_check": 1641234567,
        "last_update": 1641234567
    },
    "CAPI RSS Feed": {
        "last_version": "3.195.0",
        "last_check": 1641234567,
        "last_update": 1641234567
    }
}
```

### State Management

```bash
# View current state
cat .monitoring/state.json | jq

# Reset state (force re-check)
rm .monitoring/state.json

# Backup state
cp .monitoring/state.json .monitoring/state.backup.json
```

## Workflow Integration

### Automatic Trigger Chain

1. **Monitor detects new release** → 
2. **Creates GitHub issue** → 
3. **Triggers generation workflow** → 
4. **Generation creates PR** → 
5. **PR validation runs** → 
6. **Auto-merge if passing**

### Manual Intervention Points

- Review generated specification
- Approve PR for breaking changes
- Update migration guides
- Communicate with community

## Notifications

### GitHub Issue Format

```markdown
## CAPI Updates Detected

### CAPI GitHub Releases
- **Version**: 3.196.0
- **URL**: https://github.com/cloudfoundry/cloud_controller_ng/releases/tag/3.196.0
- **Changes**: [Release notes content]

## Action Required

1. Review the changes in the new CAPI version
2. Run the OpenAPI generation pipeline
3. Validate the generated specification
4. Create a PR with the updates

*This issue was automatically created by the CAPI monitoring system.*
```

### Slack Message Format

```
🚀 CAPI Update Detected: v3.196.0

A new version of Cloud Foundry CAPI has been released.

Version: v3.196.0
Repository: cloudfoundry-community/capi-openapi-spec

An automated workflow has been triggered to update the OpenAPI specification.
```

## Troubleshooting

### Common Issues

#### No Updates Detected
- Check network connectivity
- Verify GitHub token is valid
- Ensure state file isn't corrupted
- Check source URLs are accessible

#### Notifications Not Sending
- Verify webhook URLs are correct
- Check Slack webhook is active
- Ensure proper permissions
- Review webhook response codes

#### Workflow Not Triggering
- Check GitHub Actions is enabled
- Verify workflow file syntax
- Ensure proper repository permissions
- Review workflow run history

### Debug Mode

```bash
# Enable verbose logging
./bin/monitor-releases --verbose

# Check specific source
./bin/monitor-releases --check-only --verbose

# Test notification without state update
./bin/monitor-releases --check-only --slack=$SLACK_WEBHOOK
```

### Logs and Diagnostics

```bash
# View recent workflow runs
gh run list --workflow=monitor-releases.yml

# View workflow logs
gh run view <run-id> --log

# Download artifacts
gh run download <run-id>
```

## Best Practices

1. **Regular Monitoring**: Keep hourly schedule for timely updates
2. **State Backup**: Periodically backup monitoring state
3. **Notification Testing**: Test webhooks monthly
4. **Issue Management**: Close completed update issues
5. **Version Tracking**: Maintain version history
6. **Community Communication**: Announce major updates

## Security Considerations

1. **Token Management**:
   - Use GitHub secrets for sensitive data
   - Rotate tokens periodically
   - Limit token permissions

2. **Webhook Security**:
   - Use HTTPS endpoints only
   - Implement webhook signatures
   - Validate payloads

3. **Access Control**:
   - Limit who can trigger workflows
   - Review automation permissions
   - Audit access logs

## Metrics and Reporting

### Key Metrics
- Detection latency: Time from release to detection
- Update frequency: Releases per month
- Success rate: Successful updates vs failures
- Response time: Detection to PR creation

### Monitoring Dashboard

Track:
- Last check timestamp
- Current CAPI version
- Pending updates
- Update history
- Notification status

## Future Enhancements

1. **Multi-Version Support**: Track multiple CAPI versions
2. **Changelog Analysis**: Parse and summarize changes
3. **Dependency Updates**: Monitor related projects
4. **Custom Alerts**: Configurable alert rules
5. **Dashboard UI**: Web interface for monitoring

## Support

For issues or questions:
1. Check troubleshooting guide
2. Review GitHub Actions logs
3. Open an issue in the repository
4. Contact maintainers

Remember: The monitoring system is designed to be autonomous but may require manual intervention for complex updates or breaking changes.