# Routing & Domains Guide

This guide covers Cloud Foundry's routing system, including domains, routes, and how to configure application access.

## Overview

Cloud Foundry's routing system provides:
- **Domains** - Base URLs for your applications
- **Routes** - Specific URLs mapped to applications
- **Route Mappings** - Connections between routes and app processes
- **Route Services** - Middleware for request processing

## Key Concepts

### Routing Flow

```
Internet → Router → Route → Destination → App Process
                       ↓
                 Route Service (optional)
```

### URL Structure

```
https://hostname.domain.com/path
        ↑        ↑          ↑
     hostname  domain    path (optional)
```

## Domains

Domains define the base URLs available for routing.

### Domain Types

1. **Shared Domains** - Available to all organizations
2. **Private Domains** - Owned by specific organizations
3. **Internal Domains** - For internal app-to-app communication

### Creating a Domain

```bash
POST /v3/domains
```

```json
{
  "name": "apps.example.com",
  "internal": false,
  "metadata": {
    "labels": {
      "env": "production"
    }
  }
}
```

### Creating a Private Domain

```json
{
  "name": "private.example.com",
  "relationships": {
    "organization": {
      "data": {
        "guid": "org-guid"
      }
    }
  }
}
```

### Creating an Internal Domain

```json
{
  "name": "apps.internal",
  "internal": true,
  "relationships": {
    "organization": {
      "data": {
        "guid": "org-guid"
      }
    }
  }
}
```

### Sharing Private Domains

Share a private domain with other organizations:

```bash
POST /v3/domains/{guid}/relationships/shared_organizations
```

```json
{
  "data": [
    { "guid": "org-guid-1" },
    { "guid": "org-guid-2" }
  ]
}
```

### Domain Properties

```json
{
  "guid": "domain-guid",
  "name": "example.com",
  "internal": false,
  "router_group": {
    "guid": "router-group-guid",
    "name": "default-tcp",
    "type": "tcp"
  },
  "supported_protocols": ["http", "tcp"],
  "relationships": {
    "organization": {
      "data": {
        "guid": "org-guid"
      }
    }
  }
}
```

## Routes

Routes are URLs that can be mapped to applications.

### Creating a Route

```bash
POST /v3/routes
```

```json
{
  "host": "my-app",
  "path": "/v1",
  "port": null,
  "metadata": {
    "labels": {
      "app": "frontend"
    }
  },
  "relationships": {
    "space": {
      "data": {
        "guid": "space-guid"
      }
    },
    "domain": {
      "data": {
        "guid": "domain-guid"
      }
    }
  }
}
```

This creates: `https://my-app.example.com/v1`

### Route Types

#### HTTP Routes
```json
{
  "host": "api",
  "path": "/users",
  "relationships": {
    "domain": {
      "data": {
        "guid": "http-domain-guid"
      }
    }
  }
}
```

#### TCP Routes
```json
{
  "port": 61001,
  "relationships": {
    "domain": {
      "data": {
        "guid": "tcp-domain-guid"
      }
    }
  }
}
```

### Reserved Routes

Create a route without mapping it immediately:

```bash
POST /v3/routes?unmapped=true
```

### Route Validation

Routes must be unique within a space:
- Same host + domain + path = conflict
- Same port (for TCP routes) = conflict

## Route Destinations

Route destinations map routes to specific app processes.

### Adding a Destination

```bash
POST /v3/routes/{guid}/destinations
```

```json
{
  "destinations": [
    {
      "app": {
        "guid": "app-guid"
      },
      "weight": 80,
      "port": 8080,
      "protocol": "http1"
    },
    {
      "app": {
        "guid": "app-guid-2",
        "process": {
          "type": "web"
        }
      },
      "weight": 20,
      "port": 8080,
      "protocol": "http1"
    }
  ]
}
```

### Weighted Routing

Distribute traffic between multiple destinations:

- `weight`: 1-100 (must total 100 across all destinations)
- Useful for canary deployments
- Supports A/B testing

### Destination Properties

- `app.guid`: Target application
- `app.process.type`: Specific process type (default: "web")
- `port`: Port the app listens on
- `weight`: Traffic percentage
- `protocol`: Communication protocol (`http1`, `http2`, `tcp`)

### Updating Destinations

Replace all destinations:

```bash
PATCH /v3/routes/{guid}/destinations
```

```json
{
  "destinations": [
    {
      "app": {
        "guid": "new-app-guid"
      },
      "weight": 100
    }
  ]
}
```

### Removing Specific Destination

```bash
DELETE /v3/routes/{route-guid}/destinations/{destination-guid}
```

## Route Mappings (Deprecated)

⚠️ **Deprecated**: Use Route Destinations instead

Legacy method for connecting routes to apps:

```bash
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
  "process": {
    "type": "web"
  },
  "weight": 100
}
```

## Route Services

Route services process requests before they reach applications.

### Binding a Route Service

```bash
POST /v3/service_route_bindings
```

```json
{
  "parameters": {
    "rate_limit": "100req/s"
  },
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
  }
}
```

### Route Service Flow

```
Client → Router → Route Service → Router → Application
```

Headers added by router:
- `X-CF-Forwarded-Url`: Original request URL
- `X-CF-Proxy-Signature`: Request signature
- `X-CF-Proxy-Metadata`: Request metadata

### Use Cases

- Authentication/Authorization
- Rate limiting
- Request logging
- Content modification
- WAF functionality

## Route Sharing (Experimental)

Share routes between spaces:

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

### Listing Shared Spaces

```bash
GET /v3/routes/{guid}/relationships/shared_spaces
```

### Unsharing Routes

```bash
DELETE /v3/routes/{guid}/relationships/shared_spaces/{space-guid}
```

## Managing Routes

### Finding Routes

```bash
# All routes in a space
GET /v3/routes?space_guids=space-guid

# Routes for a domain
GET /v3/routes?domain_guids=domain-guid

# Routes for an app
GET /v3/apps/{guid}/routes

# Routes by hostname
GET /v3/routes?hosts=www,api
```

### Route Transfer

Transfer route ownership to another space:

```bash
PATCH /v3/routes/{guid}/relationships/space
```

```json
{
  "data": {
    "guid": "new-space-guid"
  }
}
```

### Checking Route Availability

```bash
GET /v3/routes?hosts=desired-hostname&domain_guids=domain-guid
```

Empty result means the route is available.

## Internal Routes

For app-to-app communication within Cloud Foundry.

### Creating Internal Routes

1. Create internal domain:
```json
{
  "name": "apps.internal",
  "internal": true
}
```

2. Create route on internal domain:
```json
{
  "host": "backend-service",
  "relationships": {
    "domain": {
      "data": {
        "guid": "internal-domain-guid"
      }
    }
  }
}
```

3. Configure network policies for access

### Internal Route Resolution

- Only accessible from within CF
- Resolved by internal DNS
- Requires network policies
- No external traffic routing

## Best Practices

### Route Naming

1. **Use descriptive hostnames**
   - `api-v2` instead of `app1`
   - `admin-portal` instead of `frontend`

2. **Version APIs in path**
   - `/v1/users`
   - `/v2/users`

3. **Environment prefixes**
   - `staging-api.example.com`
   - `prod-api.example.com`

### High Availability

1. **Multiple app instances**
   ```bash
   cf scale app -i 3
   ```

2. **Health checks**
   - Configure proper health endpoints
   - Set appropriate timeouts

3. **Zero-downtime deployments**
   - Use rolling deployments
   - Blue-green with route swapping

### Security

1. **Use HTTPS only**
   - Configure SSL certificates
   - Force HTTPS redirects

2. **Path-based routing**
   - Isolate APIs with paths
   - Implement proper authorization

3. **Internal domains**
   - Use for backend services
   - Implement network policies

## Advanced Routing

### Blue-Green Deployments

```bash
# 1. Deploy new version
POST /v3/apps
# Create app-green

# 2. Map temporary route
POST /v3/routes
# Create temp route for testing

# 3. Test new version
# Manual testing on temp route

# 4. Switch routes
POST /v3/routes/{prod-route}/destinations
{
  "destinations": [{
    "app": { "guid": "app-green-guid" },
    "weight": 100
  }]
}

# 5. Remove old version
DELETE /v3/apps/{app-blue-guid}
```

### Canary Deployments

```bash
# Gradual traffic shift
PATCH /v3/routes/{guid}/destinations
{
  "destinations": [
    {
      "app": { "guid": "app-v1-guid" },
      "weight": 90
    },
    {
      "app": { "guid": "app-v2-guid" },
      "weight": 10
    }
  ]
}

# Increase traffic over time
# 90/10 → 70/30 → 50/50 → 0/100
```

### A/B Testing

```bash
# Split traffic for testing
PATCH /v3/routes/{guid}/destinations
{
  "destinations": [
    {
      "app": { "guid": "app-version-a" },
      "weight": 50
    },
    {
      "app": { "guid": "app-version-b" },
      "weight": 50
    }
  ]
}
```

## Troubleshooting

### Common Issues

1. **Route Already Exists**
   ```json
   {
     "errors": [{
       "code": 210003,
       "title": "CF-RouteAlreadyExists",
       "detail": "Route already exists"
     }]
   }
   ```
   Solution: Use different hostname or check existing routes

2. **Invalid Domain**
   - Verify domain exists
   - Check organization access
   - Ensure proper domain type

3. **Route Not Accessible**
   - Check route mapping
   - Verify app is running
   - Check security groups
   - Validate DNS resolution

### Debugging Routes

```bash
# List all routes for an app
GET /v3/apps/{guid}/routes?include=domain,destinations

# Check route details
GET /v3/routes/{guid}?include=domain,destinations,space

# Verify route service bindings
GET /v3/routes/{guid}/service_bindings
```

### Route Metrics

Monitor routing performance:
- Request latency
- Error rates
- Traffic distribution
- Route service processing time

## Route Management Commands

### Useful Queries

```bash
# Find unmapped routes
GET /v3/routes?unmapped=true

# Routes by label
GET /v3/routes?label_selector=env=production

# Recent route changes
GET /v3/routes?order_by=-updated_at&per_page=20
```

### Bulk Operations

```bash
# Delete all unmapped routes in a space
for route_guid in $(cf curl "/v3/routes?unmapped=true&space_guids=$SPACE_GUID" | jq -r '.resources[].guid'); do
  cf curl -X DELETE "/v3/routes/$route_guid"
done
```

## Related Documentation

- [Core Resources Guide](core-resources.md) - Application management
- [Services Guide](services.md) - Route services configuration
- [Organizations & Spaces](orgs-spaces.md) - Domain ownership