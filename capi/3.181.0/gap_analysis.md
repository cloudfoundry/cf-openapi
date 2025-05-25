# CAPI OpenAPI Spec Gap Analysis - v3.195.0

## Summary
This document details the gaps between the current OpenAPI specification and the official CAPI v3.195.0 documentation.

## 1. Missing Resource Files

The following resource files are completely missing from the OpenAPI spec:

1. **jobs.yml** - Asynchronous job management
   - GET /v3/jobs
   - GET /v3/jobs/{guid}

2. **manifests.yml** - Application manifest management
   - GET /v3/apps/{guid}/manifest
   - POST /v3/spaces/{guid}/actions/apply_manifest
   - POST /v3/spaces/{guid}/manifest_diff (experimental)

3. **app_features.yml** - Application feature flags
   - Already handled in apps.yml but missing PATCH operation

4. **route_mappings.yml** - Route to app mappings (deprecated but still in v3)
   - GET /v3/route_mappings
   - GET /v3/route_mappings/{guid}
   - POST /v3/route_mappings
   - PATCH /v3/route_mappings/{guid}
   - DELETE /v3/route_mappings/{guid}

## 2. Missing Endpoints in Existing Files

### apps.yml
Missing 13 endpoints:
- PATCH /v3/apps/{guid}/features/{name}
- GET /v3/apps/{guid}/sidecars
- POST /v3/apps/{guid}/sidecars
- GET /v3/apps/{guid}/revisions
- GET /v3/apps/{guid}/revisions/deployed
- GET /v3/apps/{guid}/routes
- GET /v3/apps/{guid}/droplets
- GET /v3/apps/{guid}/packages
- GET /v3/apps/{guid}/processes
- GET /v3/apps/{guid}/processes/{type}
- PATCH /v3/apps/{guid}/processes/{type}
- GET /v3/apps/{guid}/processes/{type}/sidecars
- GET /v3/apps/{guid}/tasks

### buildpacks.yml
Missing 1 endpoint:
- POST /v3/buildpacks/{guid}/upload

### domains.yml
Missing 3 endpoints:
- GET /v3/domains/{guid}/route_reservations
- POST /v3/domains/{guid}/relationships/shared_organizations
- DELETE /v3/domains/{guid}/relationships/shared_organizations/{org_guid}

### droplets.yml
Missing 2 endpoints:
- GET /v3/droplets/{guid}/download
- POST /v3/droplets/{guid}/upload

### packages.yml
Missing 2 endpoints:
- GET /v3/packages/{guid}/download
- POST /v3/packages/{guid}/upload

### processes.yml
Missing 2 endpoints:
- GET /v3/processes/{guid}/sidecars
- POST /v3/processes/{guid}/actions/terminate_instance

### routes.yml
Missing 7 endpoints:
- GET /v3/routes/{guid}/destinations
- POST /v3/routes/{guid}/destinations
- PATCH /v3/routes/{guid}/destinations
- DELETE /v3/routes/{guid}/destinations/{destination_guid}
- POST /v3/routes/{guid}/relationships/shared_spaces
- DELETE /v3/routes/{guid}/relationships/shared_spaces/{space_guid}
- PATCH /v3/routes/{guid}/transfer_owner

### security_groups.yml
Missing 4 endpoints:
- GET /v3/security_groups/{guid}/relationships/running_spaces
- PATCH /v3/security_groups/{guid}/relationships/running_spaces
- GET /v3/security_groups/{guid}/relationships/staging_spaces
- PATCH /v3/security_groups/{guid}/relationships/staging_spaces

### spaces.yml
Missing 5 endpoints:
- GET /v3/spaces/{guid}/routes
- POST /v3/spaces/{guid}/routes
- DELETE /v3/spaces/{guid}/routes
- POST /v3/spaces/{guid}/actions/apply_manifest
- GET /v3/spaces/{guid}/environment_variable_groups

### tasks.yml
Missing 1 endpoint:
- POST /v3/tasks/{guid}/actions/cancel

### organizations.yml
Missing endpoints:
- GET /v3/organizations/{guid}/domains
- GET /v3/organizations/{guid}/relationships/quota
- PATCH /v3/organizations/{guid}/relationships/quota
- GET /v3/organizations/{guid}/usage_summary

### service_instances.yml
Missing endpoints:
- GET /v3/service_instances/{guid}/credentials
- GET /v3/service_instances/{guid}/parameters

### service_brokers.yml
Missing endpoints:
- GET /v3/service_brokers/{guid}/relationships/space
- PATCH /v3/service_brokers/{guid}/relationships/space

### isolation_segments.yml
Missing endpoints:
- POST /v3/isolation_segments/{guid}/relationships/organizations
- DELETE /v3/isolation_segments/{guid}/relationships/organizations/{org_guid}
- GET /v3/isolation_segments/{guid}/relationships/spaces
- GET /v3/isolation_segments/{guid}/organizations

### revisions.yml
Missing endpoints:
- GET /v3/revisions/{guid}/deployed_processes
- GET /v3/revisions/{guid}/environment_variables

### stacks.yml
Missing endpoints:
- GET /v3/stacks/{guid}/apps
- GET /v3/stacks/{guid}/builds

## 3. Missing Query Parameters

### Advanced Filtering
Many resources are missing advanced query parameter support:
- Relationship filters (e.g., space.organization.name)
- Complex label selectors
- Advanced timestamp operators (though some were added)
- Fields parameter (though some were added)

### Include Parameter
While added to many resources, some may still be missing comprehensive include options.

## 4. Missing Schema Definitions

### Request/Response Bodies
- Many endpoints lack proper request/response schema definitions
- Missing schema for manifest format
- Missing schema for route destinations
- Missing schema for service parameters and credentials

### Error Responses
- While error schemas were enhanced, specific error codes for each endpoint are not documented

## 5. Missing Features

### Experimental Features (marked with x-experimental)
- Cloud Native Buildpacks support endpoints
- Manifest diff generation
- Service route bindings (file exists but may be incomplete)
- Route sharing between spaces

### Metadata Support
- While added to many resources, some files still lack metadata support:
  - admin.yml
  - app_usage_events.yml
  - audit_events.yml
  - info.yml
  - resource_matches.yml
  - service_usage_events.yml

## 6. Authentication & Authorization
- Missing detailed role-based access control documentation per endpoint
- Missing admin-only endpoint markings

## 7. Pagination
- Some list endpoints may be missing proper pagination parameter documentation

## 8. Webhook/Callback Support
- Missing documentation for async operation callbacks
- Missing job polling patterns

## Recommendations

1. **Priority 1 - Critical Missing Endpoints**
   - Add all missing endpoints in apps.yml (13 endpoints)
   - Add route destination management endpoints
   - Add manifest application endpoints
   - Create jobs.yml file

2. **Priority 2 - Important Features**
   - Add upload/download endpoints for packages, droplets, buildpacks
   - Add security group relationship endpoints
   - Add space route management endpoints
   - Add organization domain and usage endpoints

3. **Priority 3 - Completeness**
   - Add remaining relationship endpoints
   - Complete metadata support for all resources
   - Add comprehensive query parameter documentation
   - Add proper request/response schemas for all endpoints

4. **Priority 4 - Documentation**
   - Add role-based access documentation
   - Document experimental features clearly
   - Add examples for complex operations