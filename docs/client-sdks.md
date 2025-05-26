# Client SDK Guide

This guide explains how to generate and use client SDKs from the Cloud Foundry CAPI OpenAPI specification in various programming languages.

## Overview

The OpenAPI specification enables automatic generation of client SDKs that:
- Provide type-safe API access
- Handle authentication and request formatting
- Include comprehensive documentation
- Support all API operations

## Generating Clients

### Prerequisites

1. **Generated OpenAPI spec file**:
   ```bash
   make gen-openapi-spec
   ```
   This creates `capi/3.181.0.openapi.yaml`

2. **OpenAPI Generator** (recommended):
   ```bash
   # Install via Homebrew
   brew install openapi-generator
   
   # Or download JAR
   wget https://repo1.maven.org/maven2/org/openapitools/openapi-generator-cli/7.2.0/openapi-generator-cli-7.2.0.jar
   ```

### Supported Languages

OpenAPI Generator supports 50+ languages including:
- Go
- JavaScript/TypeScript
- Python
- Java
- Ruby
- C#
- PHP
- Swift
- Rust

## Go Client

### Generation

```bash
# Using Makefile
make gen-go-client

# Or directly with openapi-generator
openapi-generator generate \
  -i capi/3.181.0.openapi.yaml \
  -g go \
  -o clients/go \
  --package-name cfclient \
  --git-user-id cloudfoundry-community \
  --git-repo-id capi-openapi-spec/clients/go
```

### Configuration Options

Create `config.yaml` for custom generation:

```yaml
packageName: cfclient
packageVersion: 3.195.0
generateInterfaces: true
enumClassPrefix: true
structPrefix: true
```

### Usage Example

```go
package main

import (
    "context"
    "fmt"
    "os"
    
    cfclient "github.com/cloudfoundry-community/capi-openapi-spec/clients/go"
)

func main() {
    // Configure client
    cfg := cfclient.NewConfiguration()
    cfg.Host = "api.example.com"
    cfg.Scheme = "https"
    cfg.DefaultHeader["Authorization"] = "bearer " + os.Getenv("CF_TOKEN")
    
    client := cfclient.NewAPIClient(cfg)
    
    // List organizations
    orgs, _, err := client.OrganizationsApi.GetOrganizations(context.Background()).Execute()
    if err != nil {
        panic(err)
    }
    
    for _, org := range orgs.Resources {
        fmt.Printf("Organization: %s (GUID: %s)\n", org.Name, org.Guid)
    }
    
    // Create an app
    createAppRequest := cfclient.NewCreateAppRequest("my-app")
    createAppRequest.SetRelationships(cfclient.AppRelationships{
        Space: cfclient.ToOneRelationship{
            Data: &cfclient.Relationship{
                Guid: cfclient.PtrString("space-guid"),
            },
        },
    })
    
    app, _, err := client.AppsApi.CreateApp(context.Background()).
        CreateAppRequest(*createAppRequest).
        Execute()
    if err != nil {
        panic(err)
    }
    
    fmt.Printf("Created app: %s\n", app.Guid)
}
```

### Error Handling

```go
// Handle API errors
apps, resp, err := client.AppsApi.GetApps(context.Background()).Execute()
if err != nil {
    if apiErr, ok := err.(*cfclient.GenericOpenAPIError); ok {
        // Parse error response
        var cfError cfclient.ErrorResponse
        if err := json.Unmarshal(apiErr.Body(), &cfError); err == nil {
            for _, e := range cfError.Errors {
                fmt.Printf("Error %d: %s - %s\n", e.Code, e.Title, e.Detail)
            }
        }
    }
    return
}
```

## JavaScript/TypeScript Client

### Generation

```bash
# TypeScript client
openapi-generator generate \
  -i capi/3.181.0.openapi.yaml \
  -g typescript-axios \
  -o clients/typescript \
  --additional-properties=npmName=@cloudfoundry/capi-client,npmVersion=3.195.0

# JavaScript client  
openapi-generator generate \
  -i capi/3.181.0.openapi.yaml \
  -g javascript \
  -o clients/javascript \
  --additional-properties=usePromises=true,projectName=cf-capi-client
```

### Installation

```bash
# From generated client
cd clients/typescript
npm install
npm run build

# In your project
npm install ../clients/typescript
```

### Usage Example

```typescript
import { Configuration, AppsApi, OrganizationsApi } from '@cloudfoundry/capi-client';

// Configure client
const config = new Configuration({
    basePath: 'https://api.example.com/v3',
    accessToken: process.env.CF_TOKEN,
});

const appsApi = new AppsApi(config);
const orgsApi = new OrganizationsApi(config);

// List organizations
async function listOrganizations() {
    try {
        const { data } = await orgsApi.getOrganizations();
        data.resources.forEach(org => {
            console.log(`Organization: ${org.name} (${org.guid})`);
        });
    } catch (error) {
        console.error('Error listing organizations:', error);
    }
}

// Create an app with TypeScript types
async function createApp(spaceguid: string) {
    try {
        const { data } = await appsApi.createApp({
            name: 'my-app',
            relationships: {
                space: {
                    data: {
                        guid: spaceguid
                    }
                }
            },
            environment_variables: {
                NODE_ENV: 'production'
            },
            lifecycle: {
                type: 'buildpack',
                data: {
                    buildpacks: ['nodejs_buildpack'],
                    stack: 'cflinuxfs3'
                }
            }
        });
        
        console.log(`Created app: ${data.guid}`);
        return data;
    } catch (error) {
        if (error.response) {
            console.error('API Error:', error.response.data);
        }
        throw error;
    }
}
```

### Pagination Helper

```typescript
async function getAllApps(): Promise<App[]> {
    const allApps: App[] = [];
    let page = 1;
    let hasMore = true;
    
    while (hasMore) {
        const { data } = await appsApi.getApps(undefined, undefined, page, 100);
        allApps.push(...data.resources);
        hasMore = data.pagination.next !== null;
        page++;
    }
    
    return allApps;
}
```

## Python Client

### Generation

```bash
openapi-generator generate \
  -i capi/3.181.0.openapi.yaml \
  -g python \
  -o clients/python \
  --package-name cfcapi \
  --additional-properties=packageVersion=3.195.0,projectName=cf-capi-client
```

### Installation

```bash
cd clients/python
pip install -e .

# Or build and install
python setup.py sdist bdist_wheel
pip install dist/cf-capi-client-3.195.0.tar.gz
```

### Usage Example

```python
import cfcapi
from cfcapi.api import apps_api, organizations_api
from cfcapi.model.create_app_request import CreateAppRequest
from cfcapi.model.app_relationships import AppRelationships
from cfcapi.model.to_one_relationship import ToOneRelationship
from cfcapi.model.relationship import Relationship
import os

# Configure client
configuration = cfcapi.Configuration(
    host="https://api.example.com/v3",
    access_token=os.environ.get("CF_TOKEN")
)

with cfcapi.ApiClient(configuration) as api_client:
    # List organizations
    orgs_api = organizations_api.OrganizationsApi(api_client)
    try:
        orgs = orgs_api.get_organizations()
        for org in orgs.resources:
            print(f"Organization: {org.name} ({org.guid})")
    except cfcapi.ApiException as e:
        print(f"Exception when calling OrganizationsApi: {e}")
    
    # Create an app
    apps_api_instance = apps_api.AppsApi(api_client)
    
    create_app_request = CreateAppRequest(
        name="my-python-app",
        relationships=AppRelationships(
            space=ToOneRelationship(
                data=Relationship(guid="space-guid")
            )
        ),
        environment_variables={
            "PYTHON_ENV": "production"
        }
    )
    
    try:
        app = apps_api_instance.create_app(create_app_request)
        print(f"Created app: {app.guid}")
    except cfcapi.ApiException as e:
        print(f"Exception when creating app: {e}")
```

### Async Support

```python
import asyncio
import cfcapi
from cfcapi.api_client import AsyncAppsApi

async def list_apps_async():
    configuration = cfcapi.Configuration(
        host="https://api.example.com/v3",
        access_token=os.environ.get("CF_TOKEN")
    )
    
    async with cfcapi.AsyncApiClient(configuration) as api_client:
        apps_api = AsyncAppsApi(api_client)
        apps = await apps_api.get_apps()
        return apps.resources

# Run async function
apps = asyncio.run(list_apps_async())
```

## Java Client

### Generation

```bash
openapi-generator generate \
  -i capi/3.181.0.openapi.yaml \
  -g java \
  -o clients/java \
  --group-id org.cloudfoundry \
  --artifact-id capi-client \
  --artifact-version 3.195.0 \
  --library webclient \
  --additional-properties=dateLibrary=java8
```

### Maven Configuration

```xml
<dependency>
    <groupId>org.cloudfoundry</groupId>
    <artifactId>capi-client</artifactId>
    <version>3.195.0</version>
</dependency>
```

### Usage Example

```java
import org.cloudfoundry.capi.*;
import org.cloudfoundry.capi.auth.*;
import org.cloudfoundry.capi.model.*;
import org.cloudfoundry.capi.api.AppsApi;
import org.cloudfoundry.capi.api.OrganizationsApi;

public class CloudFoundryExample {
    public static void main(String[] args) {
        // Configure client
        ApiClient defaultClient = Configuration.getDefaultApiClient();
        defaultClient.setBasePath("https://api.example.com/v3");
        
        // Configure OAuth2 access token
        OAuth bearer = (OAuth) defaultClient.getAuthentication("bearer");
        bearer.setAccessToken(System.getenv("CF_TOKEN"));
        
        // List organizations
        OrganizationsApi orgsApi = new OrganizationsApi(defaultClient);
        try {
            OrganizationList orgs = orgsApi.getOrganizations()
                .perPage(100)
                .execute();
                
            for (Organization org : orgs.getResources()) {
                System.out.println("Organization: " + org.getName() + 
                                 " (" + org.getGuid() + ")");
            }
        } catch (ApiException e) {
            System.err.println("Exception: " + e.getMessage());
        }
        
        // Create an app
        AppsApi appsApi = new AppsApi(defaultClient);
        
        CreateAppRequest createRequest = new CreateAppRequest()
            .name("my-java-app")
            .relationships(new AppRelationships()
                .space(new ToOneRelationship()
                    .data(new Relationship().guid("space-guid"))
                )
            )
            .environmentVariables(Map.of(
                "JAVA_OPTS", "-Xmx512m"
            ));
            
        try {
            App app = appsApi.createApp(createRequest);
            System.out.println("Created app: " + app.getGuid());
        } catch (ApiException e) {
            System.err.println("Error creating app: " + e.getResponseBody());
        }
    }
}
```

## Ruby Client

### Generation

```bash
openapi-generator generate \
  -i capi/3.181.0.openapi.yaml \
  -g ruby \
  -o clients/ruby \
  --gem-name cf_capi_client \
  --gem-version 3.195.0 \
  --module-name CfCapi
```

### Usage Example

```ruby
require 'cf_capi_client'

# Configure client
CfCapi.configure do |config|
  config.host = 'api.example.com'
  config.base_path = '/v3'
  config.access_token = ENV['CF_TOKEN']
end

# List organizations
orgs_api = CfCapi::OrganizationsApi.new
begin
  result = orgs_api.get_organizations
  result.resources.each do |org|
    puts "Organization: #{org.name} (#{org.guid})"
  end
rescue CfCapi::ApiError => e
  puts "Error: #{e}"
end

# Create an app
apps_api = CfCapi::AppsApi.new
create_app_request = CfCapi::CreateAppRequest.new(
  name: 'my-ruby-app',
  relationships: CfCapi::AppRelationships.new(
    space: CfCapi::ToOneRelationship.new(
      data: CfCapi::Relationship.new(guid: 'space-guid')
    )
  ),
  environment_variables: {
    'RAILS_ENV' => 'production'
  }
)

begin
  app = apps_api.create_app(create_app_request)
  puts "Created app: #{app.guid}"
rescue CfCapi::ApiError => e
  puts "Error creating app: #{e.response_body}"
end
```

## Client Configuration

### Common Configuration Options

All generated clients support similar configuration:

1. **Base URL**: API endpoint
2. **Authentication**: Bearer token
3. **Timeouts**: Connection and read timeouts
4. **Proxy**: HTTP proxy settings
5. **SSL/TLS**: Certificate validation
6. **Retry**: Automatic retry logic

### Example Configuration (Go)

```go
cfg := cfclient.NewConfiguration()
cfg.Host = "api.example.com"
cfg.Scheme = "https"
cfg.HTTPClient = &http.Client{
    Timeout: 30 * time.Second,
    Transport: &http.Transport{
        Proxy: http.ProxyFromEnvironment,
        TLSClientConfig: &tls.Config{
            InsecureSkipVerify: false,
        },
    },
}
cfg.DefaultHeader = map[string]string{
    "Authorization": "bearer " + token,
    "User-Agent": "my-app/1.0",
}
```

## Advanced Features

### Middleware/Interceptors

Most clients support middleware for:
- Request/response logging
- Automatic retry
- Token refresh
- Metrics collection

#### TypeScript Example

```typescript
import axios from 'axios';

// Add request interceptor
axios.interceptors.request.use(
    config => {
        console.log(`${config.method?.toUpperCase()} ${config.url}`);
        return config;
    },
    error => Promise.reject(error)
);

// Add response interceptor for token refresh
axios.interceptors.response.use(
    response => response,
    async error => {
        if (error.response?.status === 401) {
            const newToken = await refreshToken();
            error.config.headers.Authorization = `bearer ${newToken}`;
            return axios(error.config);
        }
        return Promise.reject(error);
    }
);
```

### Streaming Responses

For endpoints that support streaming:

```go
// Go example for log streaming
stream, _, err := client.AppsApi.GetAppLogs(ctx, appGuid).Execute()
if err != nil {
    return err
}
defer stream.Close()

scanner := bufio.NewScanner(stream)
for scanner.Scan() {
    fmt.Println(scanner.Text())
}
```

### Batch Operations

Create helpers for batch operations:

```python
async def batch_create_apps(space_guid: str, app_names: list[str]):
    """Create multiple apps concurrently"""
    tasks = []
    for name in app_names:
        request = CreateAppRequest(
            name=name,
            relationships=AppRelationships(
                space=ToOneRelationship(
                    data=Relationship(guid=space_guid)
                )
            )
        )
        task = apps_api.create_app_async(request)
        tasks.append(task)
    
    results = await asyncio.gather(*tasks, return_exceptions=True)
    return results
```

## Testing with Generated Clients

### Mock Servers

Use OpenAPI spec to generate mock servers:

```bash
# Generate mock server
openapi-generator generate \
  -i capi/3.181.0.openapi.yaml \
  -g nodejs-express-server \
  -o mock-server

# Run mock server
cd mock-server
npm install
npm start
```

### Integration Tests

```go
func TestCreateApp(t *testing.T) {
    // Use mock server for tests
    cfg := cfclient.NewConfiguration()
    cfg.Host = "localhost:3000"
    cfg.Scheme = "http"
    
    client := cfclient.NewAPIClient(cfg)
    
    // Test app creation
    request := cfclient.NewCreateAppRequest("test-app")
    app, _, err := client.AppsApi.CreateApp(context.Background()).
        CreateAppRequest(*request).
        Execute()
        
    assert.NoError(t, err)
    assert.Equal(t, "test-app", app.Name)
}
```

## Best Practices

### 1. Error Handling

Always handle API errors appropriately:

```typescript
try {
    const app = await appsApi.createApp(request);
} catch (error) {
    if (error.response) {
        // API error response
        const apiError = error.response.data;
        console.error(`API Error ${apiError.errors[0].code}: ${apiError.errors[0].detail}`);
    } else if (error.request) {
        // Network error
        console.error('Network error:', error.message);
    } else {
        // Other error
        console.error('Error:', error.message);
    }
}
```

### 2. Token Management

Implement automatic token refresh:

```python
class TokenManager:
    def __init__(self):
        self.token = None
        self.expires_at = None
    
    def get_token(self):
        if not self.token or datetime.now() >= self.expires_at:
            self.refresh_token()
        return self.token
    
    def refresh_token(self):
        # Implement token refresh logic
        response = requests.post(
            "https://uaa.example.com/oauth/token",
            data={
                "grant_type": "refresh_token",
                "refresh_token": self.refresh_token
            }
        )
        self.token = response.json()["access_token"]
        self.expires_at = datetime.now() + timedelta(
            seconds=response.json()["expires_in"]
        )
```

### 3. Resource Cleanup

Always clean up resources:

```java
try (ApiClient client = new ApiClient()) {
    client.setBasePath("https://api.example.com/v3");
    // Use client
} // Auto-closes client
```

### 4. Pagination Handling

Create reusable pagination utilities:

```javascript
async function* paginate(apiCall, params = {}) {
    let page = 1;
    let hasMore = true;
    
    while (hasMore) {
        const { data } = await apiCall({ ...params, page, per_page: 100 });
        yield* data.resources;
        hasMore = data.pagination.next !== null;
        page++;
    }
}

// Usage
for await (const app of paginate(appsApi.getApps, { label_selector: 'env=prod' })) {
    console.log(app.name);
}
```

## Troubleshooting

### Common Issues

1. **SSL Certificate Errors**
   - Update CA certificates
   - Configure client to use system certificates
   - For development only: disable verification

2. **Timeout Errors**
   - Increase client timeout settings
   - Implement retry logic
   - Use pagination for large datasets

3. **Authentication Failures**
   - Verify token format (include "bearer" prefix)
   - Check token expiration
   - Ensure correct scopes

4. **Version Mismatches**
   - Regenerate client for API updates
   - Check compatibility matrix
   - Use version-specific endpoints

## Related Documentation

- [Getting Started Guide](getting-started.md) - Manual API usage
- [Authentication Guide](authentication.md) - Token management
- [API Overview](api-overview.md) - Understanding the API