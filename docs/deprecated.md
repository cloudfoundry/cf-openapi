# Deprecated Features Guide

This guide covers deprecated features in the Cloud Foundry API, migration strategies, and timelines for removal.

## Overview

Deprecated features are marked with `deprecated: true` in the OpenAPI specification. They remain functional but:

- Should not be used for new development
- Will be removed in future versions
- Have recommended replacements
- May lack new feature support
- Could have security or performance issues

## Deprecation Policy

Cloud Foundry follows a deprecation policy:

1. **Announcement** - Feature marked as deprecated
2. **Migration Period** - Both old and new APIs available
3. **Warning Period** - Deprecation warnings in responses
4. **Removal** - Feature removed in major version

Minimum deprecation period: 6 months (typically 1 year)

## Currently Deprecated Features

### 1. Route Mappings

**Status**: Deprecated since v3.150.0  
**Removal**: Planned for v4.0.0  
**Replacement**: Route Destinations

#### Deprecated Endpoints

```
POST   /v3/route_mappings
GET    /v3/route_mappings
GET    /v3/route_mappings/{guid}
PATCH  /v3/route_mappings/{guid}
DELETE /v3/route_mappings/{guid}
```

#### Why Deprecated

- Limited to single app mapping
- No traffic splitting support
- Inconsistent with other resource patterns
- Poor performance with many mappings

#### Migration Example

**Old Way (Route Mappings):**
```bash
# Create route mapping
POST /v3/route_mappings
```

```json
{
  "relationships": {
    "app": {
      "data": {
        "guid": "app-guid"
      }
    },
    "route": {
      "data": {
        "guid": "route-guid"
      }
    }
  },
  "weight": 100
}
```

**New Way (Route Destinations):**
```bash
# Add destination to route
POST /v3/routes/{route-guid}/destinations
```

```json
{
  "destinations": [
    {
      "app": {
        "guid": "app-guid"
      },
      "weight": 100,
      "port": 8080,
      "protocol": "http1"
    }
  ]
}
```

#### Key Differences

1. **Multiple Destinations**
   ```json
   {
     "destinations": [
       {
         "app": { "guid": "app-v1" },
         "weight": 80
       },
       {
         "app": { "guid": "app-v2" },
         "weight": 20
       }
     ]
   }
   ```

2. **Protocol Support**
   - Route mappings: HTTP only
   - Route destinations: HTTP1, HTTP2, TCP

3. **Port Configuration**
   - Route mappings: Default port only
   - Route destinations: Custom ports

#### Migration Script

```bash
#!/bin/bash
# Migrate route mappings to destinations

# Get all route mappings
mappings=$(cf curl /v3/route_mappings)

# Process each mapping
echo "$mappings" | jq -r '.resources[] | @base64' | while read -r mapping; do
  decoded=$(echo "$mapping" | base64 -d)
  
  route_guid=$(echo "$decoded" | jq -r '.relationships.route.data.guid')
  app_guid=$(echo "$decoded" | jq -r '.relationships.app.data.guid')
  weight=$(echo "$decoded" | jq -r '.weight // 100')
  
  # Create destination
  cf curl -X POST "/v3/routes/$route_guid/destinations" -d "{
    \"destinations\": [{
      \"app\": { \"guid\": \"$app_guid\" },
      \"weight\": $weight
    }]
  }"
  
  # Delete old mapping
  mapping_guid=$(echo "$decoded" | jq -r '.guid')
  cf curl -X DELETE "/v3/route_mappings/$mapping_guid"
done
```

### 2. Process Stats Endpoint

**Status**: Deprecated since v3.180.0  
**Removal**: Planned for v4.0.0  
**Replacement**: Process instances endpoint

#### Deprecated Endpoint

```
GET /v3/processes/{guid}/stats
```

#### Replacement Endpoint

```
GET /v3/processes/{guid}/instances
```

#### Migration Example

**Old Response (stats):**
```json
{
  "resources": [
    {
      "type": "web",
      "index": 0,
      "state": "RUNNING",
      "usage": {
        "time": "2025-01-26T10:00:00Z",
        "cpu": 0.25,
        "mem": 268435456,
        "disk": 134217728
      },
      "host": "cell-1",
      "uptime": 3600,
      "mem_quota": 536870912,
      "disk_quota": 1073741824,
      "fds_quota": 16384
    }
  ]
}
```

**New Response (instances):**
```json
{
  "resources": [
    {
      "index": 0,
      "state": "RUNNING",
      "uptime": 3600,
      "isolation_segment": "default",
      "details": {
        "cpu": 0.25,
        "cpu_entitlement": 0.5,
        "memory_bytes": 268435456,
        "memory_bytes_quota": 536870912,
        "disk_bytes": 134217728,
        "disk_bytes_quota": 1073741824,
        "log_rate_bytes_per_second": 1024,
        "log_rate_limit_bytes_per_second": 1048576
      }
    }
  ]
}
```

#### Key Improvements

1. **Consistent Naming**
   - `mem` → `memory_bytes`
   - `disk` → `disk_bytes`
   - Clear units in names

2. **Additional Metrics**
   - CPU entitlement
   - Log rate metrics
   - Isolation segment info

3. **Better Structure**
   - Grouped under `details`
   - Clearer quotas
   - Consistent types

### 3. Legacy Buildpack APIs

Certain buildpack API patterns are deprecated in favor of Cloud Native Buildpacks.

#### Deprecated Patterns

1. **Git URL Buildpacks**
   ```json
   {
     "buildpack": "https://github.com/cloudfoundry/nodejs-buildpack"
   }
   ```

2. **Buildpack Locks**
   ```json
   {
     "locked": true,
     "buildpack": "nodejs_buildpack_v1.7.0"
   }
   ```

#### Modern Approach

Use buildpack names or lifecycle configuration:

```json
{
  "lifecycle": {
    "type": "buildpack",
    "data": {
      "buildpacks": ["nodejs_buildpack"],
      "stack": "cflinuxfs3"
    }
  }
}
```

## Features with Deprecation Warnings

Some features show deprecation warnings but aren't fully deprecated:

### Response Headers

```http
HTTP/1.1 200 OK
X-CF-Warnings: Endpoint deprecated. Use /v3/routes/{guid}/destinations instead.
Deprecation: true
Sunset: 2026-01-01T00:00:00Z
```

### Response Body Warnings

```json
{
  "guid": "mapping-guid",
  "_deprecated": true,
  "_deprecation_notice": "Route mappings are deprecated. Use route destinations.",
  "_migration_guide": "https://docs.cloudfoundry.org/migrate-route-mappings"
}
```

## Migration Strategies

### 1. Gradual Migration

Migrate resources incrementally:

```javascript
class RouteManager {
  constructor(useNewApi = false) {
    this.useNewApi = useNewApi;
  }
  
  async mapRoute(routeGuid, appGuid) {
    if (this.useNewApi) {
      // Use new destinations API
      return await this.addDestination(routeGuid, appGuid);
    } else {
      // Use deprecated mappings API
      console.warn('Using deprecated route mappings API');
      return await this.createMapping(routeGuid, appGuid);
    }
  }
  
  async addDestination(routeGuid, appGuid) {
    const response = await fetch(`/v3/routes/${routeGuid}/destinations`, {
      method: 'POST',
      body: JSON.stringify({
        destinations: [{ app: { guid: appGuid }, weight: 100 }]
      })
    });
    return response.json();
  }
  
  async createMapping(routeGuid, appGuid) {
    const response = await fetch('/v3/route_mappings', {
      method: 'POST',
      body: JSON.stringify({
        relationships: {
          route: { data: { guid: routeGuid } },
          app: { data: { guid: appGuid } }
        }
      })
    });
    return response.json();
  }
}
```

### 2. Feature Detection

Check API capabilities:

```javascript
async function detectFeatures() {
  try {
    // Try new API
    const response = await fetch('/v3/routes/test/destinations');
    if (response.status !== 404) {
      return { useDestinations: true };
    }
  } catch (error) {
    // Fall back to old API
    return { useDestinations: false };
  }
}
```

### 3. Dual-Write Strategy

Write to both APIs during transition:

```javascript
async function mapRouteCompat(routeGuid, appGuid) {
  const results = await Promise.allSettled([
    // Write to new API
    addDestination(routeGuid, appGuid),
    // Write to old API
    createMapping(routeGuid, appGuid)
  ]);
  
  // Log any failures
  results.forEach((result, index) => {
    if (result.status === 'rejected') {
      console.error(`API ${index} failed:`, result.reason);
    }
  });
  
  // Return new API result if successful
  if (results[0].status === 'fulfilled') {
    return results[0].value;
  }
  
  // Fall back to old API result
  return results[1].value;
}
```

## Version Compatibility Matrix

| Feature | Deprecated | Removed | Replacement Available |
|---------|------------|---------|---------------------|
| Route Mappings | v3.150.0 | v4.0.0 | v3.150.0 |
| Process Stats | v3.180.0 | v4.0.0 | v3.180.0 |
| Git Buildpacks | v3.100.0 | v3.200.0 | v3.0.0 |
| V2 API | v3.0.0 | N/A | v3.0.0 |

## Handling Deprecations in Client Code

### 1. Warning Detection

```javascript
class CFClient {
  async request(url, options) {
    const response = await fetch(url, options);
    
    // Check for deprecation warnings
    if (response.headers.get('X-CF-Warnings')) {
      console.warn('API Warning:', response.headers.get('X-CF-Warnings'));
    }
    
    if (response.headers.get('Deprecation') === 'true') {
      const sunset = response.headers.get('Sunset');
      console.warn(`Endpoint deprecated. Removal date: ${sunset}`);
      
      // Notify monitoring
      this.notifyDeprecation(url, sunset);
    }
    
    return response;
  }
  
  notifyDeprecation(endpoint, sunset) {
    // Send to monitoring system
    metrics.increment('api.deprecated_usage', {
      endpoint,
      sunset,
      app: 'my-app'
    });
  }
}
```

### 2. Automatic Migration

```javascript
class AutoMigratingClient {
  constructor() {
    this.migrations = {
      '/v3/route_mappings': this.migrateRouteMappings,
      '/v3/processes/{guid}/stats': this.migrateProcessStats
    };
  }
  
  async request(url, options) {
    // Check if URL needs migration
    for (const [pattern, migrator] of Object.entries(this.migrations)) {
      if (url.includes(pattern)) {
        console.warn(`Migrating deprecated endpoint: ${pattern}`);
        return await migrator.call(this, url, options);
      }
    }
    
    // Use original URL
    return await fetch(url, options);
  }
  
  async migrateRouteMappings(url, options) {
    if (options.method === 'POST') {
      // Transform request to new format
      const body = JSON.parse(options.body);
      const routeGuid = body.relationships.route.data.guid;
      
      const newUrl = `/v3/routes/${routeGuid}/destinations`;
      const newBody = {
        destinations: [{
          app: { guid: body.relationships.app.data.guid },
          weight: body.weight || 100
        }]
      };
      
      return await fetch(newUrl, {
        ...options,
        body: JSON.stringify(newBody)
      });
    }
    
    // Handle other methods...
  }
}
```

### 3. Deprecation Monitoring

```javascript
// Track deprecated API usage
const deprecationTracker = {
  usage: new Map(),
  
  track(endpoint) {
    const count = this.usage.get(endpoint) || 0;
    this.usage.set(endpoint, count + 1);
  },
  
  report() {
    const report = {
      timestamp: new Date().toISOString(),
      usage: Array.from(this.usage.entries()).map(([endpoint, count]) => ({
        endpoint,
        count,
        status: this.getDeprecationStatus(endpoint)
      }))
    };
    
    return report;
  },
  
  getDeprecationStatus(endpoint) {
    const deprecations = {
      '/v3/route_mappings': {
        deprecated: '2023-01-01',
        removal: '2026-01-01',
        replacement: '/v3/routes/{guid}/destinations'
      }
    };
    
    return deprecations[endpoint] || { status: 'unknown' };
  }
};
```

## Testing Deprecated Features

### 1. Compatibility Tests

```javascript
describe('Route Mapping Compatibility', () => {
  it('should work with both old and new APIs', async () => {
    const routeGuid = 'test-route';
    const appGuid = 'test-app';
    
    // Test old API
    const oldResult = await createRouteMapping(routeGuid, appGuid);
    expect(oldResult).toBeDefined();
    
    // Clean up
    await deleteRouteMapping(oldResult.guid);
    
    // Test new API
    const newResult = await addRouteDestination(routeGuid, appGuid);
    expect(newResult).toBeDefined();
    
    // Verify same effect
    const route = await getRoute(routeGuid);
    expect(route.destinations).toContainEqual(
      expect.objectContaining({
        app: { guid: appGuid }
      })
    );
  });
});
```

### 2. Migration Validation

```bash
#!/bin/bash
# validate-migration.sh

echo "Validating route mapping migration..."

# Count existing mappings
OLD_COUNT=$(cf curl /v3/route_mappings | jq '.pagination.total_results')

# Run migration
./migrate-route-mappings.sh

# Count new destinations
NEW_COUNT=$(cf curl /v3/routes | jq '[.resources[].destinations | length] | add')

# Verify counts match
if [ "$OLD_COUNT" -eq "$NEW_COUNT" ]; then
  echo "✓ Migration successful: $OLD_COUNT mappings migrated"
else
  echo "✗ Migration mismatch: $OLD_COUNT mappings, $NEW_COUNT destinations"
  exit 1
fi
```

## Planning for Removal

### 1. Audit Current Usage

```bash
# Find deprecated API usage in codebase
grep -r "route_mappings" src/
grep -r "processes/.*/stats" src/

# Check API logs
cf logs my-app --recent | grep "deprecated"
```

### 2. Update Documentation

```markdown
# Migration Checklist

- [ ] Identify all deprecated API usage
- [ ] Update client libraries
- [ ] Modify CI/CD scripts
- [ ] Update monitoring queries
- [ ] Train team on new APIs
- [ ] Set migration deadline
- [ ] Plan rollback strategy
```

### 3. Communicate Changes

```javascript
// Add migration notices to your app
if (process.env.CF_API_VERSION < '3.200.0') {
  console.warn(`
    ⚠️  DEPRECATION NOTICE ⚠️
    This application uses deprecated Cloud Foundry APIs:
    - Route mappings (use route destinations)
    - Process stats (use process instances)
    
    These APIs will be removed in CF API v4.0.0.
    Please update your code before ${REMOVAL_DATE}.
    
    Migration guide: https://docs.cf.org/migrations
  `);
}
```

## Best Practices

### 1. Stay Informed

- Subscribe to CF release notes
- Monitor deprecation announcements
- Test with latest API versions
- Join CF community channels

### 2. Proactive Migration

- Migrate early in deprecation cycle
- Test thoroughly before removal
- Use feature flags for gradual rollout
- Monitor for issues

### 3. Future-Proof Code

```javascript
// Abstract API interactions
class CFApiAdapter {
  constructor(version) {
    this.version = version;
    this.strategies = this.loadStrategies(version);
  }
  
  loadStrategies(version) {
    if (version >= '3.150.0') {
      return {
        mapRoute: new RouteDestinationStrategy(),
        getProcessMetrics: new ProcessInstanceStrategy()
      };
    } else {
      return {
        mapRoute: new RouteMappingStrategy(),
        getProcessMetrics: new ProcessStatsStrategy()
      };
    }
  }
  
  async mapRoute(route, app) {
    return this.strategies.mapRoute.execute(route, app);
  }
}
```

## Related Documentation

- [API Overview](api-overview.md) - Current API patterns
- [Advanced Features Guide](advanced-features.md) - Modern replacements
- [Migration Guide](migration-guide.md) - Detailed migration instructions