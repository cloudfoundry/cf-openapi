# Core Resources Guide

This guide covers the fundamental resources in Cloud Foundry that are essential for application deployment and management.

## Applications

Applications are the central resource in Cloud Foundry, representing your deployed code.

### Key Concepts

- **Application**: The logical container for your code
- **Process**: A runnable component of an application (web, worker, etc.)
- **Package**: Your application's source code or Docker image
- **Droplet**: A staged, runnable artifact created from a package
- **Build**: The process of creating a droplet from a package

### Application Lifecycle

```
Package Upload → Build (Staging) → Droplet → Start App → Running Processes
```

### Creating an Application

```bash
POST /v3/apps
```

```json
{
  "name": "my-app",
  "relationships": {
    "space": {
      "data": {
        "guid": "space-guid"
      }
    }
  },
  "lifecycle": {
    "type": "buildpack",
    "data": {
      "buildpacks": ["nodejs_buildpack"],
      "stack": "cflinuxfs3"
    }
  },
  "environment_variables": {
    "CUSTOM_ENV": "value"
  },
  "metadata": {
    "labels": {
      "team": "backend"
    }
  }
}
```

### Application States

- `STOPPED` - Application is not running
- `STARTED` - Application should be running

### Managing Environment Variables

```bash
# Update environment variables
PATCH /v3/apps/{guid}/environment_variables
```

```json
{
  "var1": "value1",
  "var2": "value2"
}
```

### Application Features

Each app can have multiple:
- **Processes** - Different process types (web, worker, clock)
- **Routes** - HTTP endpoints for accessing the app
- **Service Bindings** - Connections to databases, message queues, etc.
- **Tasks** - One-off or scheduled jobs
- **Sidecars** - Additional processes running alongside the main app

## Processes

Processes represent the runnable components of an application.

### Process Types

- `web` - Handles HTTP traffic (special handling for routing)
- `worker` - Background jobs
- Custom types for specialized workloads

### Scaling Processes

```bash
# Scale instances and resources
PATCH /v3/processes/{guid}/actions/scale
```

```json
{
  "instances": 5,
  "memory_in_mb": 512,
  "disk_in_mb": 1024
}
```

### Health Checks

Configure how Cloud Foundry monitors process health:

```bash
PATCH /v3/processes/{guid}
```

```json
{
  "health_check": {
    "type": "http",
    "data": {
      "timeout": 60,
      "endpoint": "/health",
      "invocation_timeout": 10
    }
  }
}
```

Health check types:
- `port` - TCP port check (default)
- `process` - Process running check
- `http` - HTTP endpoint check

### Process Statistics

Get real-time statistics for running instances:

```bash
GET /v3/processes/{guid}/stats
```

Response includes CPU, memory, disk usage, and uptime for each instance.

## Packages

Packages contain your application's source code or Docker image reference.

### Package Types

#### Bits Package (Source Code)
```bash
POST /v3/packages
```

```json
{
  "type": "bits",
  "relationships": {
    "app": {
      "data": {
        "guid": "app-guid"
      }
    }
  }
}
```

Then upload the code:
```bash
POST /v3/packages/{guid}/upload
Content-Type: multipart/form-data

bits=@app.zip
```

#### Docker Package
```bash
POST /v3/packages
```

```json
{
  "type": "docker",
  "data": {
    "image": "nginx:latest",
    "username": "dockeruser",
    "password": "dockerpass"
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

### Package States

- `AWAITING_UPLOAD` - Ready for bits upload
- `PROCESSING_UPLOAD` - Upload in progress
- `READY` - Available for staging
- `FAILED` - Upload or processing failed
- `COPYING` - Being copied from another package
- `EXPIRED` - No longer available

## Builds

Builds transform packages into runnable droplets using buildpacks or CNB lifecycle.

### Creating a Build

```bash
POST /v3/builds
```

```json
{
  "package": {
    "guid": "package-guid"
  },
  "lifecycle": {
    "type": "buildpack",
    "data": {
      "buildpacks": ["nodejs_buildpack"],
      "stack": "cflinuxfs3"
    }
  },
  "metadata": {
    "labels": {
      "version": "1.2.3"
    }
  }
}
```

### Build States

- `STAGING` - Build in progress
- `STAGED` - Successfully created droplet
- `FAILED` - Build failed

### Staging Logs

Stream logs during staging:
```bash
GET /v3/builds/{guid}/logs
```

## Droplets

Droplets are staged, executable versions of your application packages.

### Current Droplet

Set the droplet an app should use:

```bash
PATCH /v3/apps/{guid}/relationships/current_droplet
```

```json
{
  "data": {
    "guid": "droplet-guid"
  }
}
```

### Droplet Information

Droplets contain:
- Detected buildpack(s)
- Execution command
- Process types
- Stack
- Runtime dependencies

### Copying Droplets

Copy a droplet to another app:

```bash
POST /v3/droplets/{guid}/actions/copy
```

```json
{
  "relationships": {
    "app": {
      "data": {
        "guid": "target-app-guid"
      }
    }
  }
}
```

## Deployments

Deployments provide controlled application updates with strategies like rolling deployments.

### Creating a Deployment

```bash
POST /v3/deployments
```

```json
{
  "strategy": "rolling",
  "droplet": {
    "guid": "new-droplet-guid"
  },
  "relationships": {
    "app": {
      "data": {
        "guid": "app-guid"
      }
    }
  },
  "options": {
    "max_in_flight": 1
  }
}
```

### Deployment Strategies

- `rolling` - Gradually replace instances (default)
- `recreate` - Stop all, then start all
- `canary` - Deploy to subset first (experimental)

### Deployment States

- `DEPLOYING` - In progress
- `DEPLOYED` - Successfully completed
- `CANCELING` - Being cancelled
- `CANCELED` - Cancelled by user
- `FAILING` - Deployment failing
- `FAILED` - Deployment failed

### Canceling a Deployment

```bash
POST /v3/deployments/{guid}/actions/cancel
```

## Revisions

Revisions track changes to an application's code and configuration.

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
- Droplet GUID
- Environment variables
- Process commands and types
- Sidecar configurations

### Rolling Back

Deploy a previous revision:

```bash
POST /v3/deployments
```

```json
{
  "revision": {
    "guid": "revision-guid"
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

## Tasks

Tasks are one-off processes that run independently of an app's main processes.

### Creating a Task

```bash
POST /v3/tasks
```

```json
{
  "name": "db-migrate",
  "command": "rake db:migrate",
  "memory_in_mb": 512,
  "disk_in_mb": 1024,
  "relationships": {
    "app": {
      "data": {
        "guid": "app-guid"
      }
    }
  }
}
```

### Task States

- `PENDING` - Waiting to run
- `RUNNING` - Currently executing
- `SUCCEEDED` - Completed successfully
- `FAILED` - Task failed
- `CANCELING` - Being cancelled

### Canceling a Task

```bash
POST /v3/tasks/{guid}/actions/cancel
```

## Sidecars

Sidecars are additional processes that run alongside your application.

### Creating a Sidecar

```bash
POST /v3/apps/{guid}/sidecars
```

```json
{
  "name": "config-server",
  "command": "./config-server",
  "process_types": ["web"],
  "memory_in_mb": 128
}
```

### Sidecar Use Cases

- Proxy servers (Envoy, nginx)
- Log collectors
- Monitoring agents
- Configuration services

## Best Practices

### Application Structure

1. **One App, Multiple Processes**: Use process types for different workloads
2. **Twelve-Factor Apps**: Follow cloud-native principles
3. **Stateless Design**: Store state in services, not local disk
4. **Health Checks**: Configure appropriate health monitoring
5. **Resource Limits**: Set memory/disk limits appropriately

### Deployment Patterns

1. **Blue-Green Deployments**: Use separate apps and route switching
2. **Rolling Updates**: Use deployment resources for zero-downtime
3. **Canary Releases**: Test with small traffic percentage first
4. **Feature Flags**: Control feature rollout independently

### Performance Optimization

1. **Right-size Instances**: Monitor and adjust memory/CPU
2. **Horizontal Scaling**: Scale instances rather than resources
3. **Caching**: Use Redis/Memcached for session/data caching
4. **Async Processing**: Use worker processes for background jobs

### Troubleshooting

1. **Check Logs**: 
   ```bash
   GET /v3/apps/{guid}/processes/{type}/instances/{index}/logs
   ```

2. **Process Stats**:
   ```bash
   GET /v3/processes/{guid}/stats
   ```

3. **Events**:
   ```bash
   GET /v3/apps/{guid}/events
   ```

4. **Environment**:
   ```bash
   GET /v3/apps/{guid}/env
   ```

## Related Resources

- [Routing & Domains](routing-domains.md) - Configure app routing
- [Services Guide](services.md) - Connect to backing services
- [Advanced Features](advanced-features.md) - Deployments, revisions, manifests