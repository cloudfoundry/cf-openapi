# Query Parameters Guide

This guide provides comprehensive documentation on using query parameters to filter, sort, and customize API responses in Cloud Foundry.

## Overview

Cloud Foundry's API provides powerful query parameters for:
- **Filtering** - Select specific resources
- **Sorting** - Order results
- **Pagination** - Control result sets
- **Including** - Embed related resources
- **Field Selection** - Choose specific fields

## Basic Filtering

### Filter by Single Value

Most resources support filtering by basic attributes:

```bash
# Filter by name
GET /v3/apps?names=my-app

# Filter by GUID
GET /v3/apps?guids=585bc3a1-3743-497d-88b0-403ad6b56d16

# Filter by state
GET /v3/apps?states=STARTED
```

### Filter by Multiple Values

Use comma-separated values for OR conditions:

```bash
# Apps named "frontend" OR "backend"
GET /v3/apps?names=frontend,backend

# Spaces with specific GUIDs
GET /v3/spaces?guids=guid1,guid2,guid3
```

### Relationship Filters

Filter by related resources:

```bash
# Apps in specific spaces
GET /v3/apps?space_guids=space-guid-1,space-guid-2

# Apps in specific organizations
GET /v3/apps?organization_guids=org-guid

# Service instances in a space
GET /v3/service_instances?space_guids=space-guid
```

## Label Selectors

Label selectors provide Kubernetes-style filtering on metadata labels.

### Equality-Based Selectors

```bash
# Exact match
GET /v3/apps?label_selector=environment=production

# Not equal (using !=)
GET /v3/apps?label_selector=environment!=production

# Multiple requirements (AND)
GET /v3/apps?label_selector=environment=production,tier=frontend
```

### Set-Based Selectors

```bash
# In set
GET /v3/apps?label_selector=environment in (production,staging)

# Not in set
GET /v3/apps?label_selector=environment notin (test,development)

# Exists
GET /v3/apps?label_selector=monitored

# Does not exist
GET /v3/apps?label_selector=!deprecated
```

### Complex Label Queries

Combine multiple selector types:

```bash
# Production frontend apps that are monitored
GET /v3/apps?label_selector=environment=production,tier=frontend,monitored

# Non-production apps without deprecation flag
GET /v3/apps?label_selector=environment notin (production),!deprecated
```

### Label Selector Syntax Rules

- **Keys**: Max 63 characters, alphanumeric plus `-`, `_`, `.`
- **Values**: Max 63 characters, alphanumeric plus `-`, `_`, `.`
- **Operators**: `=`, `!=`, `in`, `notin`, exists (key only), `!` (not exists)
- **Multiple selectors**: Comma-separated (AND logic)

## Timestamp Filters

Filter resources by creation or update times using operators.

### Operators

- `[gt]` - Greater than
- `[gte]` - Greater than or equal to
- `[lt]` - Less than
- `[lte]` - Less than or equal to

### Examples

```bash
# Created after January 1, 2025
GET /v3/apps?created_ats[gt]=2025-01-01T00:00:00Z

# Updated before December 31, 2024
GET /v3/apps?updated_ats[lt]=2024-12-31T23:59:59Z

# Created in January 2025
GET /v3/apps?created_ats[gte]=2025-01-01T00:00:00Z&created_ats[lt]=2025-02-01T00:00:00Z

# Updated in the last 24 hours
GET /v3/apps?updated_ats[gt]=2025-01-25T00:00:00Z
```

### Timestamp Format

Use ISO 8601 format with timezone:
- `2025-01-26T15:30:00Z` (UTC)
- `2025-01-26T10:30:00-05:00` (with offset)

## Sorting

Control the order of results using `order_by`.

### Basic Sorting

```bash
# Sort by creation date (ascending)
GET /v3/apps?order_by=created_at

# Sort by name (ascending)
GET /v3/apps?order_by=name
```

### Descending Order

Prefix with `-` for descending order:

```bash
# Newest first
GET /v3/apps?order_by=-created_at

# Reverse alphabetical
GET /v3/apps?order_by=-name
```

### Available Sort Fields

Common fields (varies by resource):
- `created_at`
- `updated_at`
- `name`
- `position` (for ordered resources)

## Pagination

Control result sets with pagination parameters.

### Parameters

```bash
# Page number (default: 1)
GET /v3/apps?page=2

# Results per page (default: 50, max: 5000)
GET /v3/apps?per_page=100

# Combined
GET /v3/apps?page=3&per_page=20
```

### Pagination Response

```json
{
  "pagination": {
    "total_results": 145,
    "total_pages": 8,
    "first": {
      "href": "/v3/apps?page=1&per_page=20"
    },
    "last": {
      "href": "/v3/apps?page=8&per_page=20"
    },
    "next": {
      "href": "/v3/apps?page=4&per_page=20"
    },
    "previous": {
      "href": "/v3/apps?page=2&per_page=20"
    }
  },
  "resources": [...]
}
```

### Pagination Best Practices

1. **Use reasonable page sizes** - 50-200 for most cases
2. **Handle pagination in loops**:
   ```javascript
   async function getAllResources() {
     let allResources = [];
     let page = 1;
     let hasMore = true;
     
     while (hasMore) {
       const response = await fetch(`/v3/apps?page=${page}&per_page=100`);
       const data = await response.json();
       allResources = [...allResources, ...data.resources];
       hasMore = data.pagination.next !== null;
       page++;
     }
     
     return allResources;
   }
   ```

## Including Related Resources

Embed related resources to reduce API calls.

### Basic Include

```bash
# Include space with each app
GET /v3/apps?include=space

# Include multiple resources
GET /v3/apps?include=space,organization
```

### Nested Includes

Use dot notation for nested relationships:

```bash
# Include space and its organization
GET /v3/apps?include=space,space.organization

# Include service plan and offering
GET /v3/service_instances?include=service_plan,service_plan.service_offering
```

### Available Includes by Resource

#### Apps
- `space`
- `space.organization`
- `organization` (direct)

#### Service Instances
- `service_plan`
- `service_plan.service_offering`
- `service_plan.service_offering.service_broker`
- `space`
- `space.organization`

#### Service Credential Bindings
- `app`
- `service_instance`
- `service_instance.service_plan`
- `service_instance.service_plan.service_offering`

### Include Response Format

```json
{
  "resources": [
    {
      "guid": "app-guid",
      "name": "my-app",
      "relationships": {
        "space": {
          "data": {
            "guid": "space-guid"
          }
        }
      }
    }
  ],
  "included": {
    "spaces": [
      {
        "guid": "space-guid",
        "name": "production",
        "relationships": {
          "organization": {
            "data": {
              "guid": "org-guid"
            }
          }
        }
      }
    ],
    "organizations": [
      {
        "guid": "org-guid",
        "name": "my-org"
      }
    ]
  }
}
```

## Field Selection

Request only specific fields to reduce payload size.

### Basic Field Selection

```bash
# Only return guid and name for apps
GET /v3/apps?fields[apps]=guid,name

# Multiple fields
GET /v3/apps?fields[apps]=guid,name,state,created_at
```

### Fields with Includes

Select fields for included resources:

```bash
# Specific fields for apps and included spaces
GET /v3/apps?include=space&fields[apps]=guid,name&fields[spaces]=guid,name

# Complex field selection
GET /v3/service_instances?include=service_plan,service_plan.service_offering&fields[service_instances]=guid,name&fields[service_plans]=guid,name&fields[service_offerings]=guid,name,description
```

### Field Selection Rules

- Use resource type in square brackets: `fields[apps]`
- Comma-separate multiple fields
- Relationships are included automatically when referenced
- Some fields (like `guid`) are always included

## Advanced Filtering Patterns

### Combining Multiple Filters

All filters use AND logic:

```bash
# Started apps in production space created this month
GET /v3/apps?states=STARTED&space_guids=prod-space-guid&created_ats[gte]=2025-01-01T00:00:00Z
```

### Complex Queries

```bash
# Production apps updated in last week, sorted by update time
GET /v3/apps?
  label_selector=environment=production&
  updated_ats[gt]=2025-01-19T00:00:00Z&
  order_by=-updated_at&
  include=space&
  fields[apps]=guid,name,updated_at&
  per_page=100
```

### Resource-Specific Filters

#### Apps
```bash
# Filter by lifecycle type
GET /v3/apps?lifecycle_types=buildpack,docker

# Filter by stack
GET /v3/apps?stacks=cflinuxfs3
```

#### Routes
```bash
# Filter by host
GET /v3/routes?hosts=www,api

# Filter by path
GET /v3/routes?paths=/api/v1,/api/v2

# Filter by domain
GET /v3/routes?domain_guids=domain-guid
```

#### Service Instances
```bash
# Filter by type
GET /v3/service_instances?types=managed,user-provided

# Filter by service plan
GET /v3/service_instances?service_plan_guids=plan-guid

# Filter by service offering name
GET /v3/service_instances?service_plan_names=small,medium
```

## Query Parameter Limits

### Maximum Values

- **per_page**: Maximum 5000
- **label_selector**: Maximum 5000 characters
- **include**: Varies by resource
- **URL length**: Typically 8192 characters

### Performance Considerations

1. **Use specific filters** - More filters = faster queries
2. **Limit fields** - Reduce payload size
3. **Reasonable page sizes** - 50-200 optimal
4. **Avoid deep includes** - Each level adds overhead

## Common Query Patterns

### Finding Resources by Name

```bash
# Exact name match
GET /v3/apps?names=my-app

# Multiple names
GET /v3/apps?names=frontend,backend,api
```

### Recent Changes

```bash
# Resources changed in last hour
GET /v3/apps?updated_ats[gt]=2025-01-26T14:00:00Z

# Resources created today
GET /v3/apps?created_ats[gte]=2025-01-26T00:00:00Z
```

### Environment-Based Queries

```bash
# All production resources
GET /v3/apps?label_selector=env=production
GET /v3/service_instances?label_selector=env=production

# Non-production resources
GET /v3/apps?label_selector=env in (dev,test,staging)
```

### Audit Queries

```bash
# Find resources by owner
GET /v3/apps?label_selector=owner=team-backend

# Find resources without required labels
GET /v3/apps?label_selector=!compliance-checked
```

## URL Encoding

Always URL-encode special characters:

```bash
# Space in label value
GET /v3/apps?label_selector=team=backend%20team

# Special characters in timestamp
GET /v3/apps?created_ats[gt]=2025-01-26T15%3A30%3A00Z
```

## Error Handling

### Common Query Errors

```json
{
  "errors": [
    {
      "code": 10005,
      "title": "CF-InvalidQueryParameter",
      "detail": "The query parameter 'invalid_param' is not valid"
    }
  ]
}
```

### Query Parameter Validation

- Invalid parameter names return 400
- Invalid operators return 400
- Exceeding limits returns 400
- Invalid label selector syntax returns 422

## Best Practices

1. **Start specific** - Use multiple filters to narrow results
2. **Use includes wisely** - Reduce N+1 queries but avoid over-fetching
3. **Select fields** - Only request data you need
4. **Handle pagination** - Always check for next page
5. **Cache when possible** - Use ETags for unchanged data
6. **Monitor performance** - Track slow queries

## Examples by Use Case

### Dashboard View
```bash
# Get summary of all apps with key metrics
GET /v3/apps?
  states=STARTED&
  include=space&
  fields[apps]=guid,name,state,instances&
  fields[spaces]=guid,name&
  per_page=50
```

### Compliance Report
```bash
# Find resources missing required labels
GET /v3/apps?
  label_selector=!security-scan-date&
  include=space,space.organization&
  order_by=created_at
```

### Cost Analysis
```bash
# Get all service instances with billing info
GET /v3/service_instances?
  types=managed&
  include=service_plan,service_plan.service_offering&
  fields[service_instances]=guid,name,created_at&
  fields[service_plans]=guid,name,costs
```

## Related Documentation

- [API Overview](api-overview.md) - General API concepts
- [Core Resources Guide](core-resources.md) - Resource-specific queries
- [Services Guide](services.md) - Service-specific filters