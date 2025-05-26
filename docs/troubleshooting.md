# Troubleshooting Guide

This guide helps diagnose and resolve common issues when working with the Cloud Foundry API.

## Common Error Codes

### 1000 Series - Request Errors

#### 10000: InvalidRequest
```json
{
  "errors": [{
    "code": 10000,
    "title": "CF-InvalidRequest",
    "detail": "The request is invalid"
  }]
}
```
**Causes:**
- Malformed JSON
- Missing required headers
- Invalid URL format

**Solutions:**
```bash
# Validate JSON
echo '{"your": "json"}' | jq .

# Check required headers
curl -H "Authorization: bearer $TOKEN" \
     -H "Content-Type: application/json" \
     https://api.example.com/v3/apps
```

#### 10002: InvalidAuth
```json
{
  "errors": [{
    "code": 10002,
    "title": "CF-InvalidAuth",
    "detail": "Invalid authentication token"
  }]
}
```
**Solutions:**
```bash
# Get new token
cf oauth-token

# Verify token format (should start with "bearer ")
echo $CF_TOKEN | cut -c1-7  # Should output "bearer "
```

#### 10003: NotAuthorized
```json
{
  "errors": [{
    "code": 10003,
    "title": "CF-NotAuthorized",
    "detail": "You are not authorized to perform the requested action"
  }]
}
```
**Debug Steps:**
```bash
# Check your roles
cf curl /v3/roles?user_guids=$(cf curl /v3/users?usernames=$(cf target | grep User | awk '{print $2}') | jq -r '.resources[0].guid')

# Verify space/org access
cf target
```

#### 10008: UnprocessableEntity
```json
{
  "errors": [{
    "code": 10008,
    "title": "CF-UnprocessableEntity",
    "detail": "The request is semantically invalid: space can't be blank"
  }]
}
```
**Common Causes:**
- Missing relationships
- Invalid field values
- Business logic violations

**Debug Example:**
```javascript
// Check your request body
const debugRequest = {
  name: "my-app",
  // Missing space relationship!
  relationships: {
    space: {
      data: {
        guid: "space-guid"  // Add this
      }
    }
  }
};
```

### 2000 Series - Resource Errors

#### 20000: ResourceNotFound
```json
{
  "errors": [{
    "code": 20000,
    "title": "CF-ResourceNotFound",
    "detail": "The resource could not be found: app"
  }]
}
```
**Debug Steps:**
```bash
# Verify resource exists
cf curl /v3/apps/your-app-guid

# List resources to find correct GUID
cf curl "/v3/apps?names=your-app-name"
```

### 3000 Series - Quota/Limit Errors

#### 30003: QuotaExceeded
```json
{
  "errors": [{
    "code": 30003,
    "title": "CF-QuotaExceeded",
    "detail": "Memory quota exceeded for space"
  }]
}
```
**Debug Quota Issues:**
```bash
# Check organization quota
cf curl /v3/organizations/$(cf target | grep Org | awk '{print $2}' | xargs -I {} cf curl "/v3/organizations?names={}" | jq -r '.resources[0].guid')/usage_summary

# Check space quota
cf curl /v3/spaces/$(cf target | grep Space | awk '{print $2}' | xargs -I {} cf curl "/v3/spaces?names={}" | jq -r '.resources[0].guid')/usage_summary
```

## Debugging API Requests

### 1. Enable Verbose Output

```bash
# CF CLI verbose mode
CF_TRACE=true cf apps

# cURL verbose mode
curl -v https://api.example.com/v3/apps \
  -H "Authorization: bearer $TOKEN"
```

### 2. Request Inspection

```bash
# Use CF CLI curl with pretty-print
cf curl /v3/apps | jq .

# Save request/response for analysis
cf curl /v3/apps > response.json 2> headers.txt
```

### 3. API Request Builder

```javascript
// Debug helper for API requests
class CFDebugClient {
  constructor(apiUrl, token) {
    this.apiUrl = apiUrl;
    this.token = token;
  }
  
  async request(method, path, body = null) {
    const url = `${this.apiUrl}${path}`;
    console.log(`🔵 ${method} ${url}`);
    
    if (body) {
      console.log('📤 Request Body:', JSON.stringify(body, null, 2));
    }
    
    try {
      const response = await fetch(url, {
        method,
        headers: {
          'Authorization': `bearer ${this.token}`,
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
        body: body ? JSON.stringify(body) : null
      });
      
      const data = await response.json();
      
      if (!response.ok) {
        console.error('❌ Error Response:', response.status);
        console.error('📥 Error Body:', JSON.stringify(data, null, 2));
      } else {
        console.log('✅ Success:', response.status);
        console.log('📥 Response:', JSON.stringify(data, null, 2));
      }
      
      return { response, data };
    } catch (error) {
      console.error('💥 Request Failed:', error);
      throw error;
    }
  }
}
```

## Common Scenarios

### App Won't Start

**Symptoms:**
- App remains in STOPPED state
- No running instances

**Debug Steps:**

1. **Check app state:**
```bash
cf curl /v3/apps/$(cf app my-app --guid) | jq '.state'
```

2. **Check recent events:**
```bash
cf events my-app
```

3. **Check droplet:**
```bash
# Get current droplet
cf curl /v3/apps/$(cf app my-app --guid)/droplets/current

# Check if staging failed
cf curl /v3/builds?app_guids=$(cf app my-app --guid)&states=FAILED
```

4. **Check process information:**
```bash
# Get process details
cf curl /v3/apps/$(cf app my-app --guid)/processes

# Check process stats
cf curl /v3/processes/$(cf curl /v3/apps/$(cf app my-app --guid)/processes | jq -r '.resources[] | select(.type=="web") | .guid')/stats
```

5. **Common fixes:**
```bash
# Restage if droplet is missing
cf restage my-app

# Ensure route is mapped
cf map-route my-app apps.example.com --hostname my-app

# Scale if instances are 0
cf scale my-app -i 1
```

### Service Binding Failures

**Symptoms:**
- Binding creation fails
- App can't access service credentials

**Debug Steps:**

1. **Verify service instance:**
```bash
# Check service instance state
cf curl "/v3/service_instances?names=my-database" | jq '.resources[0].last_operation'
```

2. **Check existing bindings:**
```bash
# List bindings for app
cf curl "/v3/service_credential_bindings?app_guids=$(cf app my-app --guid)"
```

3. **Verify credentials injection:**
```bash
# Check VCAP_SERVICES
cf curl /v3/apps/$(cf app my-app --guid)/env | jq '.system_env_json.VCAP_SERVICES'
```

4. **Common fixes:**
```bash
# Recreate binding
cf unbind-service my-app my-database
cf bind-service my-app my-database

# Restage to pick up new credentials
cf restage my-app
```

### Route Not Accessible

**Symptoms:**
- 404 errors when accessing app
- Route exists but doesn't work

**Debug Steps:**

1. **Verify route exists:**
```bash
cf curl "/v3/routes?hosts=my-app&domain_guids=$(cf curl '/v3/domains?names=apps.example.com' | jq -r '.resources[0].guid')"
```

2. **Check route destinations:**
```bash
# Get route GUID
ROUTE_GUID=$(cf curl "/v3/routes?hosts=my-app" | jq -r '.resources[0].guid')

# Check destinations
cf curl "/v3/routes/$ROUTE_GUID/destinations"
```

3. **Verify app is running:**
```bash
cf app my-app
```

4. **Common fixes:**
```bash
# Add destination to route
cf curl -X POST "/v3/routes/$ROUTE_GUID/destinations" -d '{
  "destinations": [{
    "app": {
      "guid": "'$(cf app my-app --guid)'"
    },
    "weight": 100
  }]
}'

# Or use CF CLI
cf map-route my-app apps.example.com --hostname my-app
```

### Memory Issues

**Symptoms:**
- App crashes with "Insufficient memory"
- OOMKilled errors

**Debug Steps:**

1. **Check memory usage:**
```bash
# Get current memory allocation
cf app my-app

# Check actual usage
cf curl /v3/processes/$(cf curl "/v3/apps/$(cf app my-app --guid)/processes" | jq -r '.resources[] | select(.type=="web") | .guid')/stats | jq '.resources[].usage'
```

2. **Monitor memory over time:**
```javascript
// Memory monitoring script
async function monitorMemory(appName, duration = 60000) {
  const startTime = Date.now();
  const appGuid = await getAppGuid(appName);
  const processGuid = await getWebProcessGuid(appGuid);
  
  const interval = setInterval(async () => {
    const stats = await cf.curl(`/v3/processes/${processGuid}/stats`);
    const memoryUsage = stats.resources.map(r => ({
      index: r.index,
      memory_mb: Math.round(r.usage.mem / 1048576),
      memory_percent: Math.round((r.usage.mem / r.mem_quota) * 100)
    }));
    
    console.log(new Date().toISOString(), memoryUsage);
    
    if (Date.now() - startTime > duration) {
      clearInterval(interval);
    }
  }, 5000);
}
```

3. **Solutions:**
```bash
# Increase memory
cf scale my-app -m 1G

# Add memory per instance type
cf curl -X PATCH /v3/processes/$(cf curl "/v3/apps/$(cf app my-app --guid)/processes" | jq -r '.resources[] | select(.type=="web") | .guid') -d '{
  "memory_in_mb": 1024
}'
```

### Deployment Failures

**Symptoms:**
- Deployment stuck in DEPLOYING
- Deployment fails repeatedly

**Debug Steps:**

1. **Check deployment status:**
```bash
# List recent deployments
cf curl "/v3/deployments?app_guids=$(cf app my-app --guid)&order_by=-created_at" | jq '.resources[0]'
```

2. **Monitor deployment progress:**
```bash
# Get deployment details
DEPLOYMENT_GUID=$(cf curl "/v3/deployments?app_guids=$(cf app my-app --guid)&states=DEPLOYING" | jq -r '.resources[0].guid')

# Watch status
watch -n 2 "cf curl /v3/deployments/$DEPLOYMENT_GUID | jq '{state,status}'"
```

3. **Common fixes:**
```bash
# Cancel stuck deployment
cf curl -X POST "/v3/deployments/$DEPLOYMENT_GUID/actions/cancel"

# Use different strategy
cf curl -X POST /v3/deployments -d '{
  "strategy": "recreate",
  "droplet": {
    "guid": "'$(cf curl /v3/apps/$(cf app my-app --guid)/droplets/current | jq -r .guid)'"
  },
  "relationships": {
    "app": {
      "data": {
        "guid": "'$(cf app my-app --guid)'"
      }
    }
  }
}'
```

## Performance Issues

### Slow API Responses

**Diagnosis:**
```bash
# Measure API response time
time cf curl /v3/apps

# Profile specific endpoints
for i in {1..10}; do
  time cf curl /v3/apps >/dev/null 2>&1
done | awk '{sum+=$1; count++} END {print "Average:", sum/count}'
```

**Optimizations:**

1. **Use field selection:**
```bash
# Only get needed fields
cf curl "/v3/apps?fields[apps]=guid,name,state"
```

2. **Optimize includes:**
```bash
# Avoid deep includes
# Bad: include=space,space.organization,space.organization.quota
# Good: include=space
```

3. **Use pagination efficiently:**
```bash
# Larger page sizes for bulk operations
cf curl "/v3/apps?per_page=200"
```

### High Error Rates

**Monitor errors:**
```javascript
// Error tracking
class ErrorMonitor {
  constructor() {
    this.errors = new Map();
  }
  
  track(error) {
    const key = `${error.code}-${error.title}`;
    const count = this.errors.get(key) || 0;
    this.errors.set(key, count + 1);
  }
  
  report() {
    const sorted = Array.from(this.errors.entries())
      .sort((a, b) => b[1] - a[1]);
    
    console.table(sorted.map(([error, count]) => ({
      Error: error,
      Count: count,
      Percentage: ((count / this.totalErrors()) * 100).toFixed(2) + '%'
    })));
  }
  
  totalErrors() {
    return Array.from(this.errors.values()).reduce((a, b) => a + b, 0);
  }
}
```

## Advanced Debugging

### 1. Network Tracing

```bash
# Trace network path
traceroute api.example.com

# Check DNS resolution
nslookup api.example.com

# Test connectivity
nc -zv api.example.com 443
```

### 2. API Health Checks

```javascript
// Comprehensive health check
async function healthCheck() {
  const checks = {
    api_accessible: false,
    auth_working: false,
    can_list_apps: false,
    can_create_resources: false
  };
  
  try {
    // Check API accessibility
    const info = await fetch('/v3/info');
    checks.api_accessible = info.ok;
    
    // Check authentication
    const orgs = await authenticatedFetch('/v3/organizations');
    checks.auth_working = orgs.ok;
    
    // Check read permissions
    const apps = await authenticatedFetch('/v3/apps');
    checks.can_list_apps = apps.ok;
    
    // Check write permissions (dry run)
    const testApp = await authenticatedFetch('/v3/apps', {
      method: 'POST',
      headers: { 'CF-Dry-Run': 'true' },
      body: JSON.stringify({
        name: 'health-check-test',
        relationships: { space: { data: { guid: 'test' } } }
      })
    });
    checks.can_create_resources = testApp.status !== 403;
    
  } catch (error) {
    console.error('Health check failed:', error);
  }
  
  return checks;
}
```

### 3. Log Analysis

```bash
# Search logs for errors
cf logs my-app --recent | grep -E "(ERROR|FATAL|Exception)"

# Get logs with timestamps
cf logs my-app --recent --timestamp

# Stream logs for debugging
cf logs my-app | tee app-debug.log
```

### 4. Event Correlation

```javascript
// Correlate events with issues
async function correlateEvents(appGuid, issueTime) {
  const events = await cf.curl(`/v3/audit_events?target_guids=${appGuid}`);
  
  const relevantEvents = events.resources.filter(event => {
    const eventTime = new Date(event.created_at);
    const timeDiff = Math.abs(eventTime - issueTime);
    return timeDiff < 300000; // Within 5 minutes
  });
  
  console.log('Events around issue time:');
  relevantEvents.forEach(event => {
    console.log(`${event.created_at}: ${event.type} by ${event.actor.name}`);
  });
}
```

## Emergency Procedures

### App Down

```bash
#!/bin/bash
# emergency-restart.sh

APP_NAME=$1

echo "🚨 Emergency restart for $APP_NAME"

# Get app GUID
APP_GUID=$(cf app $APP_NAME --guid)

# Try graceful restart first
echo "Attempting graceful restart..."
cf restart $APP_NAME

# Wait and check
sleep 10
if cf app $APP_NAME | grep -q "crashed"; then
  echo "Graceful restart failed, trying forced restart..."
  
  # Stop completely
  cf stop $APP_NAME
  sleep 5
  
  # Clear any stuck state
  cf curl -X DELETE "/v3/apps/$APP_GUID/processes/web/instances/0" 2>/dev/null || true
  
  # Start fresh
  cf start $APP_NAME
fi

# Verify
sleep 10
cf app $APP_NAME
```

### Service Outage

```bash
# Check service broker health
cf curl /v3/service_brokers | jq '.resources[] | {name, state}'

# List affected instances
cf curl "/v3/service_instances?service_plan_names=$PLAN_NAME" | jq '.resources[] | {name, last_operation}'

# Force service instance update
cf update-service my-service -c '{"restart": true}'
```

## Getting Help

### 1. Gather Information

```bash
# System information
cf curl /v3/info > cf-info.json

# Target information
cf target > cf-target.txt

# API version
cf api

# Recent events
cf events my-app > app-events.txt

# Logs
cf logs my-app --recent > app-logs.txt
```

### 2. Create Debug Bundle

```bash
#!/bin/bash
# create-debug-bundle.sh

APP_NAME=$1
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BUNDLE_DIR="cf-debug-$APP_NAME-$TIMESTAMP"

mkdir -p $BUNDLE_DIR

# Collect information
cf target > $BUNDLE_DIR/target.txt
cf app $APP_NAME > $BUNDLE_DIR/app-info.txt
cf env $APP_NAME > $BUNDLE_DIR/app-env.txt
cf events $APP_NAME > $BUNDLE_DIR/app-events.txt
cf logs $APP_NAME --recent > $BUNDLE_DIR/app-logs.txt

# API calls
cf curl /v3/apps/$(cf app $APP_NAME --guid) > $BUNDLE_DIR/app-api.json
cf curl /v3/apps/$(cf app $APP_NAME --guid)/processes > $BUNDLE_DIR/processes.json
cf curl /v3/apps/$(cf app $APP_NAME --guid)/routes > $BUNDLE_DIR/routes.json

# Create archive
tar -czf $BUNDLE_DIR.tar.gz $BUNDLE_DIR/
rm -rf $BUNDLE_DIR

echo "Debug bundle created: $BUNDLE_DIR.tar.gz"
```

### 3. Community Resources

- **CF Slack**: https://cloudfoundry.slack.com
- **CF Discuss**: https://lists.cloudfoundry.org
- **GitHub Issues**: Report API issues
- **Stack Overflow**: Tag with `cloudfoundry`

## Related Documentation

- [API Overview](api-overview.md) - Understanding error responses
- [Getting Started Guide](getting-started.md) - Basic troubleshooting
- [Advanced Features](advanced-features.md) - Complex scenario debugging