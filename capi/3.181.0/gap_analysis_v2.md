# CAPI OpenAPI Spec Gap Analysis v2 - After First Iteration

## Summary
This document details the remaining gaps after the first iteration of improvements to the OpenAPI specification compared to CAPI v3.195.0.

## 1. Missing Endpoints in Existing Files

### apps.yml
Still missing:
- GET /v3/apps/{guid}/builds - List builds for an app
- GET /v3/apps/{guid}/environment_variable_groups - Get env var groups for an app

### isolation_segments.yml
Missing:
- GET /v3/isolation_segments/{guid}/organizations - List organizations using this isolation segment
- GET /v3/isolation_segments/{guid}/spaces - List spaces in this isolation segment

### service_instances.yml
Missing:
- GET /v3/service_instances/{guid}/credentials - Get credentials for managed service instance
- GET /v3/service_instances/{guid}/parameters - Get parameters for managed service instance

### service_brokers.yml
Missing:
- GET /v3/service_brokers/{guid}/relationships/space - Get space relationship
- PATCH /v3/service_brokers/{guid}/relationships/space - Update space relationship

### spaces.yml
Missing:
- GET /v3/spaces/{guid}/staging_security_groups - List staging security groups for space
- GET /v3/spaces/{guid}/running_security_groups - List running security groups for space
- GET /v3/spaces/{guid}/relationships/quota - Get space quota relationship
- PATCH /v3/spaces/{guid}/relationships/quota - Update space quota relationship
- GET /v3/spaces/{guid}/service_instances - List service instances in space

### stacks.yml
Missing:
- GET /v3/stacks/{guid}/apps - List apps using this stack
- GET /v3/stacks/{guid}/builds - List builds using this stack

### sidecars.yml
Needs verification of:
- GET /v3/sidecars/{guid} - Get a specific sidecar
- PATCH /v3/sidecars/{guid} - Update a sidecar
- DELETE /v3/sidecars/{guid} - Delete a sidecar

### environment_variable_groups.yml
Needs verification of all endpoints:
- GET /v3/environment_variable_groups/running - Get running env var group
- PATCH /v3/environment_variable_groups/running - Update running env var group
- GET /v3/environment_variable_groups/staging - Get staging env var group
- PATCH /v3/environment_variable_groups/staging - Update staging env var group

## 2. Missing Resource Files

### route_mappings.yml (deprecated but still in API)
- GET /v3/route_mappings
- GET /v3/route_mappings/{guid}
- POST /v3/route_mappings
- PATCH /v3/route_mappings/{guid}
- DELETE /v3/route_mappings/{guid}

## 3. Missing Query Parameters

### Advanced Filtering
Several resources still lack advanced filtering capabilities:
- Nested relationship filters (e.g., space.organization.name)
- Complex timestamp operators on some resources
- Fields parameter on some resources

### Specific Missing Parameters
- `include` parameter missing on some endpoints that support it
- `fields` parameter not consistently implemented
- Advanced operators for filtering not fully implemented

## 4. Schema Completeness Issues

### Request/Response Bodies
- Some endpoints lack complete request body schemas
- Response schemas missing detailed field descriptions
- Nested object schemas not fully defined

### Validation Rules
- Missing field validation rules (min/max lengths, patterns)
- Enum values not specified for all applicable fields
- Required fields not consistently marked

## 5. Experimental Features

### Not Properly Marked
Some experimental features may not be marked with x-experimental:
- Manifest diff endpoint
- Route sharing features
- Service instance sharing (verify all endpoints are marked)

## 6. Metadata Support

Still missing in these files:
- admin.yml
- app_usage_events.yml
- audit_events.yml
- info.yml
- resource_matches.yml
- service_usage_events.yml

## 7. Authentication/Authorization

### Missing Details
- Role requirements not specified for all endpoints
- Admin-only endpoints not clearly marked
- OAuth scopes not documented

## 8. Pagination

### Inconsistent Implementation
- Some list endpoints missing pagination parameters
- Pagination response schema not referenced consistently

## 9. Error Responses

### Missing Specific Error Cases
- Not all endpoints document their possible error responses
- Error codes specific to each endpoint not documented
- Rate limiting errors not documented for all endpoints

## 10. Links and Relationships

### Incomplete HATEOAS Support
- Some resources missing links in responses
- Relationship links not fully implemented
- Self links missing on some resources

## Priority Recommendations

### High Priority
1. Add missing endpoints in isolation_segments.yml
2. Add missing endpoints in service_instances.yml
3. Add missing endpoints in spaces.yml
4. Add missing endpoints in stacks.yml
5. Verify and complete sidecars.yml endpoints

### Medium Priority
1. Add missing service_brokers relationship endpoints
2. Complete environment_variable_groups.yml
3. Add route_mappings.yml (even if deprecated)
4. Add missing query parameters
5. Add metadata support to remaining files

### Low Priority
1. Enhance schema definitions
2. Add detailed validation rules
3. Document authentication requirements
4. Improve error response documentation