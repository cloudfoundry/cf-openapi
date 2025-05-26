# Advanced Features Guide

This guide covers Cloud Foundry's advanced features including deployments, revisions, sidecars, tasks, application manifests, and metadata management.

## Deployments

Deployments provide controlled application updates with zero-downtime strategies.

### Deployment Strategies

#### Rolling Deployment (Default)

Gradually replaces instances:

```bash
POST /v3/deployments
```

```json
{
  "droplet": {
    "guid": "new-droplet-guid"
  },
  "strategy": "rolling",
  "options": {
    "max_in_flight": 1
  },
  "relationships": {
    "app": {
      "data": {
        "guid": "app-guid"
      }
    }
  },
  "metadata": {
    "labels": {
      "version": "2.0.0",
      "deployment-type": "feature-release"
    }
  }
}
```

**Options:**
- `max_in_flight`: Maximum instances updated simultaneously (default: 1)

**Process:**
1. Start new instance with new droplet
2. Wait for health check to pass
3. Stop old instance
4. Repeat for all instances

#### Recreate Deployment

Stops all instances before starting new ones:

```json
{
  "droplet": {
    "guid": "new-droplet-guid"
  },
  "strategy": "recreate",
  "relationships": {
    "app": {
      "data": {
        "guid": "app-guid"
      }
    }
  }
}
```

**Use cases:**
- Database schema changes
- Breaking configuration changes
- Resource constraints

#### Canary Deployment (Experimental)

Test with subset of instances:

```json
{
  "droplet": {
    "guid": "new-droplet-guid"
  },
  "strategy": "canary",
  "options": {
    "canary_instances": 1
  },
  "relationships": {
    "app": {
      "data": {
        "guid": "app-guid"
      }
    }
  }
}
```

### Deployment Lifecycle

#### States

- `DEPLOYING` - Deployment in progress
- `DEPLOYED` - Successfully completed
- `CANCELING` - Being cancelled
- `CANCELED` - Cancelled by user
- `FAILING` - Deployment failing  
- `FAILED` - Deployment failed

#### Monitoring Deployment

```bash
GET /v3/deployments/{guid}
```

Response:
```json
{
  "guid": "deployment-guid",
  "state": "DEPLOYING",
  "status": {
    "value": "ROLLING",
    "reason": "Replacing instances",
    "details": {
      "instances_processed": 2,
      "instances_total": 5
    }
  },
  "strategy": "rolling",
  "droplet": {
    "guid": "droplet-guid"
  },
  "created_at": "2025-01-26T10:00:00Z",
  "updated_at": "2025-01-26T10:05:00Z"
}
```

#### Canceling Deployment

```bash
POST /v3/deployments/{guid}/actions/cancel
```

This rolls back to the previous state.

### Deployment Best Practices

1. **Always Use Deployments for Production**
   - Ensures zero downtime
   - Provides rollback capability
   - Maintains service availability

2. **Configure Health Checks**
   ```json
   {
     "health_check": {
       "type": "http",
       "data": {
         "endpoint": "/health",
         "timeout": 60
       }
     }
   }
   ```

3. **Start with Conservative Settings**
   - `max_in_flight: 1` for critical apps
   - Increase after validating stability

## Revisions

Revisions track application code and configuration changes, enabling rollbacks.

### Enabling Revisions

```bash
PATCH /v3/apps/{guid}/features/revisions
```

```json
{
  "enabled": true
}
```

### Revision Contents

Each revision captures:
- Droplet reference
- Environment variables
- Process commands
- Process types
- Sidecar configurations
- Custom start command

### Working with Revisions

#### List Revisions

```bash
GET /v3/apps/{guid}/revisions
```

Response includes revision history:
```json
{
  "resources": [
    {
      "guid": "revision-guid",
      "version": 3,
      "description": "Rolled back to revision 1",
      "deployable": true,
      "droplet": {
        "guid": "droplet-guid"
      },
      "processes": {
        "web": {
          "command": "bundle exec rails server"
        }
      },
      "environment_variables": {
        "RAILS_ENV": "production"
      },
      "created_at": "2025-01-26T10:00:00Z"
    }
  ]
}
```

#### Deploy a Revision

Roll back to a previous revision:

```bash
POST /v3/deployments
```

```json
{
  "revision": {
    "guid": "revision-guid"
  },
  "strategy": "rolling",
  "relationships": {
    "app": {
      "data": {
        "guid": "app-guid"
      }
    }
  }
}
```

### Revision Metadata

Add deployment information:

```bash
PATCH /v3/revisions/{guid}
```

```json
{
  "metadata": {
    "labels": {
      "commit": "abc123",
      "branch": "main"
    },
    "annotations": {
      "deployment-reason": "Fix critical bug #123",
      "deployed-by": "CI/CD Pipeline"
    }
  }
}
```

### Revision Limits

- Default: 100 revisions per app
- Oldest revisions automatically pruned
- Configurable per deployment

## Sidecars

Sidecars are additional processes that run alongside your main application.

### Creating Sidecars

```bash
POST /v3/apps/{guid}/sidecars
```

```json
{
  "name": "envoy-proxy",
  "command": "/usr/local/bin/envoy -c /etc/envoy/config.yaml",
  "process_types": ["web"],
  "memory_in_mb": 256,
  "environment_variables": {
    "ENVOY_LOG_LEVEL": "info"
  }
}
```

### Sidecar Properties

- **name**: Unique identifier within app
- **command**: Executable command
- **process_types**: Which processes to attach to
- **memory_in_mb**: Memory allocation
- **environment_variables**: Sidecar-specific env vars

### Common Sidecar Patterns

#### 1. Proxy Sidecar (Envoy)

```json
{
  "name": "envoy",
  "command": "envoy -c /etc/envoy/envoy.yaml",
  "process_types": ["web"],
  "memory_in_mb": 128
}
```

#### 2. Log Collector

```json
{
  "name": "fluentd",
  "command": "fluentd -c /fluentd/etc/fluent.conf",
  "process_types": ["web", "worker"],
  "memory_in_mb": 64,
  "environment_variables": {
    "FLUENT_ELASTICSEARCH_HOST": "logs.example.com"
  }
}
```

#### 3. Monitoring Agent

```json
{
  "name": "datadog-agent",
  "command": "/opt/datadog-agent/bin/agent run",
  "process_types": ["web"],
  "memory_in_mb": 128,
  "environment_variables": {
    "DD_API_KEY": "((datadog-api-key))"
  }
}
```

### Managing Sidecars

#### Update Sidecar

```bash
PATCH /v3/sidecars/{guid}
```

```json
{
  "command": "/usr/local/bin/envoy -c /etc/envoy/config-v2.yaml",
  "memory_in_mb": 512
}
```

#### Delete Sidecar

```bash
DELETE /v3/sidecars/{guid}
```

### Sidecar Lifecycle

- Start with main process
- Share process namespace
- Restart if crashed
- Stop with main process

## Tasks

Tasks are one-off processes for administrative or scheduled work.

### Creating Tasks

```bash
POST /v3/tasks
```

```json
{
  "name": "database-migration",
  "command": "rake db:migrate",
  "memory_in_mb": 1024,
  "disk_in_mb": 2048,
  "log_rate_limit_in_bytes_per_second": 1048576,
  "metadata": {
    "labels": {
      "task-type": "migration",
      "version": "2.0.0"
    }
  },
  "relationships": {
    "app": {
      "data": {
        "guid": "app-guid"
      }
    }
  }
}
```

### Task Properties

- **command**: Shell command to execute
- **name**: Human-readable identifier
- **memory_in_mb**: Memory allocation
- **disk_in_mb**: Disk allocation
- **log_rate_limit**: Log output limit

### Task States

- `PENDING` - Waiting to be scheduled
- `RUNNING` - Currently executing
- `SUCCEEDED` - Completed successfully
- `FAILED` - Task failed
- `CANCELING` - Being cancelled

### Common Task Patterns

#### Database Migrations

```json
{
  "name": "db-migrate-v2",
  "command": "bundle exec rake db:migrate VERSION=20250126",
  "memory_in_mb": 512
}
```

#### Data Processing

```json
{
  "name": "nightly-report",
  "command": "python generate_reports.py --date yesterday",
  "memory_in_mb": 2048,
  "disk_in_mb": 4096
}
```

#### Cleanup Tasks

```json
{
  "name": "cleanup-old-files",
  "command": "find /tmp -mtime +7 -delete",
  "disk_in_mb": 1024
}
```

### Managing Tasks

#### Monitor Task Status

```bash
GET /v3/tasks/{guid}
```

#### Cancel Running Task

```bash
POST /v3/tasks/{guid}/actions/cancel
```

#### List App Tasks

```bash
GET /v3/apps/{guid}/tasks?states=RUNNING,PENDING
```

## Application Manifests

Manifests provide declarative application configuration.

### Manifest Structure

```yaml
---
applications:
- name: my-app
  memory: 1G
  instances: 3
  buildpacks:
  - nodejs_buildpack
  stack: cflinuxfs3
  
  routes:
  - route: myapp.example.com
  - route: api.example.com/v2
  
  services:
  - my-database
  - my-cache
  
  env:
    NODE_ENV: production
    LOG_LEVEL: info
  
  processes:
  - type: web
    memory: 512M
    instances: 3
    command: npm start
  - type: worker  
    memory: 256M
    instances: 1
    command: npm run worker
    
  sidecars:
  - name: envoy
    process_types: [web]
    command: envoy -c /etc/envoy.yaml
    memory: 128M
```

### Applying Manifests

```bash
POST /v3/spaces/{guid}/actions/apply_manifest
```

With the manifest content in the request body.

### Manifest Variables

Use variables for environment-specific values:

```yaml
applications:
- name: ((app_name))
  memory: ((memory))
  instances: ((instances))
  env:
    DATABASE_URL: ((database_url))
    API_KEY: ((api_key))
```

Apply with variable substitution:
```bash
POST /v3/spaces/{guid}/actions/apply_manifest
```

With variables in request:
```json
{
  "var": {
    "app_name": "production-api",
    "memory": "2G",
    "instances": 5,
    "database_url": "postgres://..."
  }
}
```

### Manifest Diff (Experimental)

Compare manifest with current state:

```bash
POST /v3/spaces/{guid}/manifest_diff
```

Response shows differences:
```json
{
  "diff": [
    {
      "op": "replace",
      "path": "/applications/0/instances",
      "was": 3,
      "value": 5
    },
    {
      "op": "add",
      "path": "/applications/0/env/NEW_VAR",
      "value": "new-value"
    }
  ]
}
```

### Getting Current Manifest

Export app configuration as manifest:

```bash
GET /v3/apps/{guid}/manifest
```

## Metadata (Labels and Annotations)

Metadata provides a way to attach arbitrary information to resources.

### Labels

Key-value pairs for organizing and selecting resources:

```bash
PATCH /v3/apps/{guid}
```

```json
{
  "metadata": {
    "labels": {
      "environment": "production",
      "team": "backend",
      "cost-center": "engineering",
      "version": "2.1.0"
    }
  }
}
```

#### Label Constraints

- **Key**: Max 63 chars (prefix/name format)
- **Prefix**: Max 253 chars, DNS subdomain
- **Name**: Max 63 chars, alphanumeric + `-_`
- **Value**: Max 63 chars, alphanumeric + `-_.`

#### Label Selectors

Query resources by labels:

```bash
# Single label
GET /v3/apps?label_selector=environment=production

# Multiple labels (AND)
GET /v3/apps?label_selector=environment=production,team=backend

# Set membership
GET /v3/apps?label_selector=environment in (production,staging)

# Existence check
GET /v3/apps?label_selector=monitored

# Complex queries
GET /v3/apps?label_selector=environment=production,version!=1.0.0,!deprecated
```

### Annotations

Key-value pairs for storing additional information:

```json
{
  "metadata": {
    "annotations": {
      "contact": "backend-team@example.com",
      "documentation": "https://wiki.example.com/backend-api",
      "compliance": "pci-dss-v3.2.1",
      "last-security-review": "2025-01-15"
    }
  }
}
```

#### Annotation Constraints

- **Key**: Max 63 chars (prefix/name format)
- **Value**: Max 5000 chars

### Metadata Best Practices

1. **Consistent Naming**
   ```json
   {
     "labels": {
       "app.kubernetes.io/name": "backend-api",
       "app.kubernetes.io/version": "2.1.0",
       "app.kubernetes.io/component": "api",
       "app.kubernetes.io/part-of": "platform"
     }
   }
   ```

2. **Environment Tagging**
   ```json
   {
     "labels": {
       "env": "prod",
       "region": "us-east",
       "tier": "web"
     }
   }
   ```

3. **Cost Tracking**
   ```json
   {
     "labels": {
       "cost-center": "eng-123",
       "project": "customer-api",
       "owner": "backend-team"
     }
   }
   ```

## Jobs (Asynchronous Operations)

Jobs track long-running asynchronous operations.

### Job Structure

```json
{
  "guid": "job-guid",
  "created_at": "2025-01-26T10:00:00Z",
  "updated_at": "2025-01-26T10:05:00Z",
  "operation": "service_instance.create",
  "state": "PROCESSING",
  "links": {
    "self": {
      "href": "/v3/jobs/job-guid"
    }
  },
  "errors": [],
  "warnings": []
}
```

### Job States

- `PROCESSING` - Operation in progress
- `COMPLETE` - Finished successfully
- `FAILED` - Operation failed
- `POLLING` - Polling external system

### Polling Pattern

```javascript
async function pollJob(jobGuid) {
  let job;
  do {
    const response = await fetch(`/v3/jobs/${jobGuid}`);
    job = await response.json();
    
    if (job.state === 'FAILED') {
      throw new Error(job.errors[0].detail);
    }
    
    if (job.state === 'PROCESSING' || job.state === 'POLLING') {
      await sleep(2000); // Wait 2 seconds
    }
  } while (job.state !== 'COMPLETE');
  
  return job;
}
```

### Job Warnings

Non-fatal issues during operation:

```json
{
  "state": "COMPLETE",
  "warnings": [
    {
      "code": 20003,
      "title": "ServiceInstanceNameTaken",
      "detail": "Service instance name already exists in another space"
    }
  ]
}
```

## Advanced Patterns

### Blue-Green Deployment with Revisions

```bash
# 1. Deploy new version to green app
POST /v3/apps
{ "name": "my-app-green" }

# 2. Deploy same droplet
POST /v3/deployments
{
  "droplet": { "guid": "new-droplet-guid" },
  "relationships": {
    "app": { "data": { "guid": "green-app-guid" } }
  }
}

# 3. Switch routes
POST /v3/routes/{route-guid}/destinations
{
  "destinations": [{
    "app": { "guid": "green-app-guid" },
    "weight": 100
  }]
}

# 4. Keep blue app as revision for rollback
```

### Scheduled Tasks with External Scheduler

```bash
# Cron job calls CF API
0 2 * * * curl -X POST https://api.cf.example.com/v3/tasks \
  -H "Authorization: bearer $CF_TOKEN" \
  -d '{"name":"nightly-backup","command":"backup.sh"}'
```

### Canary Analysis

```javascript
// Monitor canary deployment
async function analyzeCanary(deploymentGuid) {
  const metrics = await getMetrics();
  const errorRate = metrics.errors / metrics.requests;
  
  if (errorRate > 0.05) { // 5% error threshold
    // Cancel deployment
    await fetch(`/v3/deployments/${deploymentGuid}/actions/cancel`, {
      method: 'POST'
    });
    throw new Error('Canary failed with high error rate');
  }
}
```

## Best Practices

### Deployment Strategy Selection

1. **Use Rolling for Most Cases**
   - Safe default
   - Zero downtime
   - Automatic rollback

2. **Use Recreate When**
   - Database migrations required
   - Singleton services
   - Resource constraints

3. **Use Canary When**
   - High-risk changes
   - Performance concerns
   - Gradual rollout needed

### Revision Management

1. **Always Enable for Production**
   - Instant rollback capability
   - Change tracking
   - Audit trail

2. **Tag Revisions**
   ```json
   {
     "metadata": {
       "labels": {
         "git-commit": "abc123",
         "ci-build": "1234"
       }
     }
   }
   ```

3. **Test Rollback Procedures**
   - Regular drills
   - Automated testing
   - Document process

### Task Patterns

1. **Idempotent Tasks**
   - Can be retried safely
   - Check before modifying
   - Log all actions

2. **Task Monitoring**
   - Set appropriate timeouts
   - Monitor resource usage
   - Alert on failures

3. **Task Scheduling**
   - Use external schedulers
   - Implement retry logic
   - Track execution history

## Related Documentation

- [Core Resources Guide](core-resources.md) - Basic app management
- [Services Guide](services.md) - Service integration
- [Query Parameters Guide](query-parameters.md) - Metadata queries