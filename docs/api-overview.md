# Cloud Foundry CAPI v3 API Overview

This document provides a comprehensive overview of the Cloud Foundry Cloud Controller API v3, including REST principles, common patterns, and important concepts.

## REST API Principles

The Cloud Foundry API follows REST principles:

- **Resources** are represented as JSON objects
- **Standard HTTP methods** (GET, POST, PUT, PATCH, DELETE) are used for operations
- **HTTP status codes** indicate success or failure
- **Hypermedia links** connect related resources

## Base URL and Versioning

The API is versioned via the URL path:
```
https://api.<your-domain>/v3
```

The current API version is v3, which represents a complete redesign from the v2 API with improved consistency and functionality.

## Request Format

### Headers

Standard headers for API requests:

```http
Authorization: bearer <token>
Content-Type: application/json
Accept: application/json
```

### Request Body

POST, PUT, and PATCH requests use JSON bodies:

```json
{
  "name": "my-app",
  "environment_variables": {
    "KEY": "value"
  },
  "relationships": {
    "space": {
      "data": {
        "guid": "space-guid-here"
      }
    }
  }
}
```

## Response Format

### Standard Resource Response

All resources follow a consistent structure:

```json
{
  "guid": "unique-identifier",
  "created_at": "2025-01-26T12:00:00Z",
  "updated_at": "2025-01-26T12:30:00Z",
  "name": "resource-name",
  "relationships": {
    "parent": {
      "data": {
        "guid": "parent-guid"
      }
    }
  },
  "metadata": {
    "labels": {
      "key": "value"
    },
    "annotations": {
      "key": "value"
    }
  },
  "links": {
    "self": {
      "href": "https://api.example.com/v3/resources/guid"
    }
  }
}
```

### List Response

List endpoints return paginated collections:

```json
{
  "pagination": {
    "total_results": 142,
    "total_pages": 15,
    "first": {
      "href": "https://api.example.com/v3/apps?page=1&per_page=10"
    },
    "last": {
      "href": "https://api.example.com/v3/apps?page=15&per_page=10"
    },
    "next": {
      "href": "https://api.example.com/v3/apps?page=2&per_page=10"
    },
    "previous": null
  },
  "resources": [
    {
      "guid": "...",
      "name": "..."
    }
  ]
}
```

## Pagination

### Query Parameters

- `page`: Page number (default: 1)
- `per_page`: Results per page (default: 50, max: 5000)
- `order_by`: Sort field with direction prefix (`created_at`, `-updated_at`)

### Example
```bash
GET /v3/apps?page=2&per_page=100&order_by=-created_at
```

## Filtering

### Basic Filters

Most resources support filtering by common attributes:

```bash
# Filter by names
GET /v3/apps?names=app1,app2

# Filter by GUIDs
GET /v3/apps?guids=guid1,guid2

# Filter by organization
GET /v3/apps?organization_guids=org-guid
```

### Timestamp Filters

Use operators for timestamp comparisons:

```bash
# Created after a date
GET /v3/apps?created_ats[gt]=2025-01-01T00:00:00Z

# Updated before a date  
GET /v3/apps?updated_ats[lt]=2025-01-26T00:00:00Z

# Between dates
GET /v3/apps?created_ats[gte]=2025-01-01T00:00:00Z&created_ats[lte]=2025-01-31T23:59:59Z
```

Supported operators:
- `[gt]` - greater than
- `[gte]` - greater than or equal
- `[lt]` - less than
- `[lte]` - less than or equal

### Label Selectors

Kubernetes-style label selectors for metadata filtering:

```bash
# Exact match
GET /v3/apps?label_selector=env=production

# Set membership
GET /v3/apps?label_selector=env in (production,staging)

# Existence
GET /v3/apps?label_selector=env

# Non-existence
GET /v3/apps?label_selector=!deprecated

# Multiple requirements (AND)
GET /v3/apps?label_selector=env=production,tier=frontend
```

## Including Related Resources

Use the `include` parameter to embed related resources:

```bash
# Include space with app
GET /v3/apps/guid?include=space

# Include space and organization
GET /v3/apps/guid?include=space,space.organization
```

Supported includes vary by resource - check specific endpoint documentation.

## Field Selection

Use the `fields` parameter to request specific fields:

```bash
# Only return guid and name for apps
GET /v3/apps?fields[apps]=guid,name

# Return specific fields for apps and included spaces
GET /v3/apps?include=space&fields[apps]=guid,name&fields[spaces]=guid,name
```

## Error Handling

### Error Response Format

```json
{
  "errors": [
    {
      "code": 10008,
      "title": "UnprocessableEntity", 
      "detail": "The request is semantically invalid: space can't be blank"
    }
  ]
}
```

### Common HTTP Status Codes

- `200 OK` - Successful GET, PATCH
- `201 Created` - Successful POST
- `202 Accepted` - Asynchronous operation started
- `204 No Content` - Successful DELETE
- `400 Bad Request` - Invalid request syntax
- `401 Unauthorized` - Invalid or missing token
- `403 Forbidden` - Valid token but insufficient permissions
- `404 Not Found` - Resource doesn't exist
- `422 Unprocessable Entity` - Semantically invalid request
- `503 Service Unavailable` - API temporarily unavailable

### Rate Limiting

When rate limited, responses include:

```http
HTTP/1.1 429 Too Many Requests
X-RateLimit-Limit: 60
X-RateLimit-Remaining: 0
X-RateLimit-Reset: 1623456789
Retry-After: 58
```

## Asynchronous Operations

### Job Resources

Long-running operations return job references:

```json
{
  "guid": "job-guid",
  "operation": "app.delete",
  "state": "PROCESSING",
  "links": {
    "self": {
      "href": "https://api.example.com/v3/jobs/job-guid"
    }
  }
}
```

### Job States

- `PROCESSING` - Job is running
- `COMPLETE` - Job finished successfully
- `FAILED` - Job encountered an error
- `POLLING` - Job is polling an external resource

### Polling Pattern

```bash
# 1. Initiate async operation
DELETE /v3/apps/app-guid
# Returns: 202 Accepted with Location header

# 2. Poll job status
GET /v3/jobs/job-guid

# 3. Check state field
# Repeat until state is COMPLETE or FAILED
```

## Metadata

### Labels

Key-value pairs for organizing and selecting resources:

```json
{
  "metadata": {
    "labels": {
      "env": "production",
      "team": "backend",
      "cost-center": "123"
    }
  }
}
```

Constraints:
- Key: 63 character max, alphanumeric + `-._`
- Value: 63 character max, alphanumeric + `-._`
- Prefix (optional): 253 character DNS subdomain

### Annotations  

Key-value pairs for storing additional information:

```json
{
  "metadata": {
    "annotations": {
      "contact": "team@example.com",
      "documentation": "https://wiki.example.com/my-app"
    }
  }
}
```

Constraints:
- Key: 63 character max
- Value: 5000 character max

## Relationships

Resources are connected via relationships:

```json
{
  "relationships": {
    "space": {
      "data": {
        "guid": "space-guid"
      }
    },
    "routes": {
      "data": [
        { "guid": "route-guid-1" },
        { "guid": "route-guid-2" }
      ]
    }
  }
}
```

### To-One Relationships
Single `data` object with `guid`

### To-Many Relationships  
Array of `data` objects with `guid`s

## Actions

Some resources support action endpoints:

```bash
# Start an app
POST /v3/apps/{guid}/actions/start

# Stop an app  
POST /v3/apps/{guid}/actions/stop

# Restart an app
POST /v3/apps/{guid}/actions/restart
```

Actions typically return the updated resource or a job for async operations.

## Experimental Features

Features marked with `x-experimental: true` in the OpenAPI spec:

- May change without notice
- Not recommended for production use
- Provide feedback to help stabilize

Current experimental features:
- Route sharing between spaces
- Application manifest diff
- Service route bindings

## Resource Lifecycle

### Creation Flow
1. POST to create resource
2. Upload/configure additional data
3. Start/deploy/bind as needed

### Update Patterns
- PATCH for partial updates
- PUT for complete replacement (rare)
- Specific action endpoints for state changes

### Deletion
- DELETE removes resource
- May return job for async deletion
- Cascading deletes for child resources

## Security Considerations

### Authentication
- All endpoints except `/` and `/v3/info` require authentication
- Use Bearer tokens from UAA
- Tokens expire - implement refresh logic

### Authorization
- Scoped based on Cloud Foundry roles
- Organization and space membership
- Admin privileges for platform operations

### Audit Events
- All modifications generate audit events
- Query via `/v3/audit_events`
- Retain for compliance requirements

## Performance Tips

1. **Use field selection** to reduce payload size
2. **Filter server-side** instead of client-side
3. **Paginate large result sets** appropriately  
4. **Cache unchanged resources** using ETags
5. **Batch operations** when possible
6. **Use includes** to avoid N+1 queries

## API Evolution

The v3 API is designed for stability:

- Backward compatible changes only
- New fields are additive
- Deprecation notices for removals
- Experimental features for testing

## Next Steps

- Review the [Core Resources Guide](core-resources.md) for detailed resource documentation
- Explore [Query Parameters Guide](query-parameters.md) for advanced filtering
- Check [Authentication & Authorization](authentication.md) for security details