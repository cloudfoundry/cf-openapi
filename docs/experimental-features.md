# Experimental Features Guide

This guide covers Cloud Foundry features marked as experimental in the API. These features are subject to change and not recommended for production use without careful consideration.

## Overview

Experimental features are marked with `x-experimental: true` in the OpenAPI specification. They provide early access to new functionality but may:

- Change without notice
- Have incomplete implementations
- Lack full documentation
- Experience breaking changes
- Be removed in future versions

## Identifying Experimental Features

### In OpenAPI Spec

```yaml
paths:
  /v3/routes/{guid}/relationships/shared_spaces:
    post:
      summary: Share a route with other spaces
      x-experimental: true
```

### In API Responses

Some endpoints include experimental flags in responses:

```json
{
  "experimental": true,
  "supported": true,
  "description": "This feature is experimental and may change"
}
```

## Current Experimental Features

### 1. Route Sharing Between Spaces

Share routes across multiple spaces within an organization.

#### Enable Route Sharing

```bash
POST /v3/routes/{guid}/relationships/shared_spaces
```

```json
{
  "data": [
    { "guid": "space-guid-1" },
    { "guid": "space-guid-2" }
  ]
}
```

#### List Shared Spaces

```bash
GET /v3/routes/{guid}/relationships/shared_spaces
```

Response:
```json
{
  "data": [
    {
      "guid": "space-guid-1"
    },
    {
      "guid": "space-guid-2"
    }
  ],
  "links": {
    "self": {
      "href": "/v3/routes/{guid}/relationships/shared_spaces"
    }
  }
}
```

#### Unshare Route

```bash
DELETE /v3/routes/{guid}/relationships/shared_spaces/{space-guid}
```

#### Use Cases

1. **Microservices Architecture**
   - Share internal routes between service spaces
   - Maintain single route for multiple implementations

2. **Multi-Environment Setup**
   - Share routes between staging/production
   - Gradual traffic migration

3. **Team Collaboration**
   - Multiple teams sharing API endpoints
   - Centralized route management

#### Limitations

- Routes can only be shared within same organization
- Requires appropriate permissions in all spaces
- May have performance implications
- Route ownership remains with original space

### 2. Application Manifest Diff

Compare manifest changes before applying them.

#### Generate Diff

```bash
POST /v3/spaces/{guid}/manifest_diff
```

Request body contains manifest YAML:
```yaml
applications:
- name: my-app
  memory: 2G
  instances: 5
  env:
    NEW_VAR: new-value
```

#### Diff Response

```json
{
  "diff": [
    {
      "op": "replace",
      "path": "/applications/0/memory",
      "was": "1G",
      "value": "2G"
    },
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

#### Diff Operations

- `add` - New configuration added
- `remove` - Configuration removed
- `replace` - Value changed
- `move` - Configuration relocated
- `copy` - Configuration duplicated

#### Use Cases

1. **Change Validation**
   - Preview changes before applying
   - Catch unintended modifications
   - Validate CI/CD changes

2. **Audit Trail**
   - Document what will change
   - Review before production deployment
   - Compliance requirements

3. **Automation Safety**
   - Verify automated manifest updates
   - Prevent destructive changes
   - Rollback planning

### 3. Service Route Bindings

Bind route services to specific routes for request processing.

#### Create Route Service Binding

```bash
POST /v3/service_route_bindings
```

```json
{
  "relationships": {
    "route": {
      "data": {
        "guid": "route-guid"
      }
    },
    "service_instance": {
      "data": {
        "guid": "service-instance-guid"
      }
    }
  },
  "parameters": {
    "rate_limit": "1000/hour",
    "log_level": "debug"
  }
}
```

#### Route Service Flow

```
Client Request → Router → Route Service → Router → Application
                            ↓
                    (Process/Transform)
```

#### Headers Added by Router

- `X-CF-Forwarded-Url` - Original request URL
- `X-CF-Proxy-Signature` - Request signature
- `X-CF-Proxy-Metadata` - Additional metadata

#### Use Cases

1. **Authentication Services**
   ```json
   {
     "parameters": {
       "auth_type": "oauth2",
       "required_scopes": ["read", "write"]
     }
   }
   ```

2. **Rate Limiting**
   ```json
   {
     "parameters": {
       "requests_per_minute": 60,
       "burst_size": 100
     }
   }
   ```

3. **Request Transformation**
   ```json
   {
     "parameters": {
       "add_headers": {
         "X-Request-ID": "{{uuid}}",
         "X-Timestamp": "{{timestamp}}"
       }
     }
   }
   ```

### 4. Canary Deployments

Deploy to a subset of instances for testing.

#### Create Canary Deployment

```bash
POST /v3/deployments
```

```json
{
  "droplet": {
    "guid": "new-droplet-guid"
  },
  "strategy": "canary",
  "options": {
    "canary_instances": 1,
    "canary_duration": 300
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

#### Canary Options

- `canary_instances` - Number of canary instances
- `canary_duration` - Time before full rollout (seconds)
- `canary_metrics` - Metrics to monitor

#### Promote or Rollback

```bash
# Promote canary to full deployment
POST /v3/deployments/{guid}/actions/promote

# Rollback canary deployment
POST /v3/deployments/{guid}/actions/rollback
```

### 5. Zero-Downtime App Restarts

Restart apps without dropping requests.

```bash
POST /v3/apps/{guid}/actions/restart
```

```json
{
  "strategy": "rolling",
  "options": {
    "max_in_flight": 1,
    "pause_between_instances": 5
  }
}
```

## Feature Flags for Experimental Features

Some experimental features are controlled by feature flags.

### Check Feature Flag Status

```bash
GET /v3/feature_flags/{name}
```

Response:
```json
{
  "name": "route_sharing",
  "enabled": false,
  "custom_error_message": "Route sharing is currently in beta",
  "links": {
    "self": {
      "href": "/v3/feature_flags/route_sharing"
    }
  }
}
```

### Common Experimental Feature Flags

1. **route_sharing** - Cross-space route sharing
2. **service_route_bindings** - Route service bindings
3. **rolling_app_restarts** - Zero-downtime restarts
4. **canary_deployments** - Canary deployment strategy

## Using Experimental Features Safely

### 1. Test Thoroughly

```bash
# Test in isolated environment
cf target -o sandbox-org -s experimental-space

# Enable feature flag
cf enable-feature-flag route_sharing

# Test functionality
./run-experimental-tests.sh
```

### 2. Monitor Closely

```javascript
// Monitor experimental feature usage
const monitorExperimental = async (featureName) => {
  const metrics = await collectMetrics(featureName);
  
  if (metrics.errorRate > 0.05) {
    await disableFeature(featureName);
    await notifyTeam('Experimental feature disabled due to errors');
  }
};
```

### 3. Have Rollback Plans

```yaml
# Document rollback procedures
experimental_features:
  route_sharing:
    rollback_steps:
      - Unshare all routes
      - Disable feature flag
      - Restart affected applications
    data_backup:
      - Export route configurations
      - Document space relationships
```

### 4. Version Lock Compatibility

```json
{
  "api_version": "3.195.0",
  "experimental_features": {
    "route_sharing": {
      "min_version": "3.180.0",
      "breaking_change_version": "3.200.0"
    }
  }
}
```

## Providing Feedback

Help improve experimental features:

### 1. Report Issues

```bash
# Include in bug reports:
- CF API version
- Feature flag status
- Exact API calls made
- Error responses
- Expected vs actual behavior
```

### 2. Usage Metrics

Share anonymized usage data:
- Frequency of use
- Performance impact
- Error rates
- Use case descriptions

### 3. Feature Requests

Suggest improvements:
- API ergonomics
- Missing functionality
- Performance optimizations
- Documentation needs

## Migration Strategies

### When Features Graduate

1. **API Changes**
   - Experimental endpoints may move
   - Parameters might change
   - Response formats could update

2. **Update Clients**
   ```bash
   # Before: experimental endpoint
   POST /v3/experimental/routes/{guid}/share
   
   # After: stable endpoint
   POST /v3/routes/{guid}/relationships/shared_spaces
   ```

3. **Remove Feature Flags**
   ```bash
   # Feature becomes default behavior
   cf disable-feature-flag route_sharing_experimental
   cf enable-feature-flag route_sharing
   ```

## Risk Assessment

### Low Risk Experimental Features

- Read-only operations
- Additive changes
- Isolated functionality
- Client-side only changes

### High Risk Experimental Features

- Data model changes
- Breaking API changes
- Cross-cutting concerns
- Performance impacts

### Risk Mitigation

1. **Gradual Rollout**
   ```javascript
   const enableForPercentage = (feature, percentage) => {
     const random = Math.random() * 100;
     return random < percentage;
   };
   
   if (enableForPercentage('new_feature', 10)) {
     // Use experimental feature for 10% of requests
   }
   ```

2. **Circuit Breakers**
   ```javascript
   const circuitBreaker = new CircuitBreaker(experimentalApi, {
     timeout: 3000,
     errorThresholdPercentage: 50,
     resetTimeout: 30000
   });
   
   circuitBreaker.fallback(() => {
     // Use stable API as fallback
     return stableApi.call();
   });
   ```

## Future Experimental Features

Potential upcoming experimental features:

1. **Multi-Region Deployments**
   - Cross-region app replication
   - Geo-routing capabilities
   - Regional failover

2. **Advanced Autoscaling**
   - Custom metrics support
   - Predictive scaling
   - Cost-based scaling

3. **Native Service Mesh**
   - Built-in service discovery
   - Advanced traffic management
   - Observability integration

4. **Enhanced Security**
   - Runtime security policies
   - Automated vulnerability scanning
   - Secret rotation

## Best Practices

### 1. Documentation

Always document experimental feature usage:

```yaml
# .cf/experimental-features.yml
features_in_use:
  - name: route_sharing
    reason: "Share API routes between microservices"
    spaces: ["service-a", "service-b"]
    rollback_tested: true
    
  - name: manifest_diff
    reason: "Validate CI/CD manifest changes"
    automation: true
    monitoring: true
```

### 2. Testing Strategy

```bash
#!/bin/bash
# test-experimental.sh

# Run tests with feature enabled
cf enable-feature-flag $FEATURE
run_tests "with_feature"

# Run tests with feature disabled
cf disable-feature-flag $FEATURE
run_tests "without_feature"

# Compare results
compare_test_results
```

### 3. Monitoring

```javascript
// Track experimental feature performance
const experimentalMetrics = {
  feature: 'route_sharing',
  requests: 0,
  errors: 0,
  latency: [],
  
  record(success, duration) {
    this.requests++;
    if (!success) this.errors++;
    this.latency.push(duration);
  },
  
  report() {
    return {
      errorRate: this.errors / this.requests,
      avgLatency: average(this.latency),
      p99Latency: percentile(this.latency, 99)
    };
  }
};
```

## Related Documentation

- [Advanced Features Guide](advanced-features.md) - Stable advanced features
- [API Overview](api-overview.md) - API conventions
- [Troubleshooting Guide](troubleshooting.md) - Debug experimental features