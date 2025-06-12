# CAPI Endpoint Variations and Edge Cases

This document catalogs endpoints with special handling requirements in the CAPI v3 API that need careful consideration when generating the OpenAPI specification.

## 1. Polymorphic Request/Response Bodies

### Service Credential Bindings
**Endpoint**: `POST /v3/service_credential_bindings`

**Variations**:
- Type field can be `app` or `key`
- Conditional fields based on type:
  - When `type: app` → requires `relationships.app`
  - When `type: key` → `relationships.app` is optional
- Response status varies:
  - `201 Created` for User-Provided Service Instances
  - `202 Accepted` for Managed Service Instances (async)

**OpenAPI Strategy**:
```yaml
requestBody:
  content:
    application/json:
      schema:
        oneOf:
          - $ref: '#/components/schemas/AppCredentialBinding'
          - $ref: '#/components/schemas/KeyCredentialBinding'
        discriminator:
          propertyName: type
```

### Packages
**Endpoint**: `POST /v3/packages`

**Variations**:
- Type field can be `bits` or `docker`
- Different data requirements:
  - `bits`: empty data object
  - `docker`: requires `data.image`, optional `data.username`/`data.password`

**OpenAPI Strategy**:
```yaml
requestBody:
  content:
    application/json:
      schema:
        oneOf:
          - $ref: '#/components/schemas/BitsPackage'
          - $ref: '#/components/schemas/DockerPackage'
        discriminator:
          propertyName: type
```

## 2. Shared Path Endpoints

### Route Destinations
**Path**: `/v3/routes/{guid}/destinations`

**Operations**:
- `GET`: List destinations
- `POST`: Insert destinations  
- `PATCH`: Replace all destinations

**Handling**: Each method gets its own operation with unique operationId

### Process Scaling (Duplicate Endpoints)
**Endpoints**:
1. `POST /v3/processes/{guid}/actions/scale`
2. `POST /v3/apps/{guid}/processes/{type}/actions/scale`

**Handling**: Document that these are equivalent operations with different path structures

## 3. Conditional Parameters

### Empty Value Semantics
**Pattern**: Query parameters where empty string has special meaning

**Examples**:
- `GET /v3/buildpacks?stacks=` → Returns buildpacks with NULL stack
- `GET /v3/routes?hosts=hostname1,,hostname2` → Empty string is valid host

**OpenAPI Strategy**:
```yaml
parameters:
  - name: stacks
    in: query
    allowEmptyValue: true
    description: "Use empty value to filter for NULL stacks"
```

### Timestamp Range Filters
**Pattern**: Timestamps support both range and relational operators

**Formats**:
- Range: `created_ats=2020-01-01T00:00:00Z,2020-12-31T23:59:59Z`
- Operators: `created_ats[gt]=`, `created_ats[gte]=`, `created_ats[lt]=`, `created_ats[lte]=`

**OpenAPI Strategy**: Define multiple parameters for each operator variant

## 4. Complex Parameter Dependencies

### Manifest Application
**Endpoint**: `POST /v3/spaces/{guid}/actions/apply_manifest`

**Complexity**:
- Accepts YAML content
- Service bindings can be:
  - Array of strings (service instance names)
  - Array of objects (with configuration)

**OpenAPI Strategy**: Use flexible schema with oneOf for service bindings

### Package Upload
**Endpoint**: `POST /v3/packages/{guid}/upload`

**Complexity**:
- Multi-part form with optional fields:
  - `bits`: .zip file
  - `resources`: array of resource matches
- Can use either or both

**OpenAPI Strategy**:
```yaml
requestBody:
  content:
    multipart/form-data:
      schema:
        type: object
        properties:
          bits:
            type: string
            format: binary
          resources:
            type: array
```

## 5. Feature Flag Dependencies

### Role Creation
**Endpoint**: `POST /v3/roles`

**Conditional Behavior**:
- User can be specified by:
  - GUID (always works)
  - Username (requires `set_roles_by_username` feature flag)
  - Username + origin (for disambiguation)

**OpenAPI Strategy**: Document in description, use oneOf for user specification

## 6. Special Query Parameter Logic

### Label Selector AND Logic
**Pattern**: Unlike other filters that use OR logic, `label_selector` uses AND

**Example**: 
- `GET /v3/spaces?label_selector=production,east_coast`
- Returns spaces with BOTH labels, not either

**OpenAPI Strategy**: Clearly document this exception in parameter description

## 7. Response Variations

### Buildpack Credentials
**Pattern**: Credentials can contain different authentication methods

**Variations**:
- Username/password pair
- Token authentication

**OpenAPI Strategy**:
```yaml
credentials:
  oneOf:
    - type: object
      properties:
        username: { type: string }
        password: { type: string }
      required: [username, password]
    - type: object
      properties:
        token: { type: string }
      required: [token]
```

## Implementation Guidelines

1. **Use Discriminators**: For polymorphic types, always specify discriminator property
2. **Document Edge Cases**: Include detailed descriptions for conditional behavior
3. **Validate Examples**: Ensure examples cover all variations
4. **Test Generation**: Verify client SDK generation handles these cases
5. **Version Considerations**: Document which variations are version-specific

## Testing Requirements

For each edge case:
- [ ] Schema validates against all variations
- [ ] Examples provided for each variation
- [ ] Client SDK handles polymorphic types correctly
- [ ] Conditional parameters documented clearly
- [ ] Error cases covered in responses