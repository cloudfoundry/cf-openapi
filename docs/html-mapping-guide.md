# HTML to OpenAPI Mapping Guide

This document defines the mapping between CAPI HTML documentation elements and OpenAPI 3.0 specification components.

## Overview

The CAPI documentation follows a consistent structure for each API endpoint. This guide provides the mapping rules to transform HTML elements into valid OpenAPI 3.0 specifications.

## Endpoint Structure Mapping

### 1. Endpoint Definition

**HTML Pattern**:
```html
<h4 id="definition">Definition</h4>
<p><code class="prettyprint">METHOD /path/:parameter</code></p>
```

**OpenAPI Mapping**:
```yaml
paths:
  /path/{parameter}:
    method:
      # endpoint details
```

**Transformation Rules**:
- Extract HTTP method (GET, POST, PUT, PATCH, DELETE)
- Convert `:parameter` to `{parameter}` format
- Method must be lowercase in OpenAPI

### 2. Operation Summary and Description

**HTML Pattern**:
```html
<h3 id="operation-name">Operation Name</h3>
<p>Description paragraph...</p>
```

**OpenAPI Mapping**:
```yaml
summary: "Operation Name"
description: "Description paragraph..."
```

### 3. Request Parameters

#### Path Parameters
**HTML Pattern**:
- Identified by `:param` in the endpoint definition
- Details in parameter tables

**OpenAPI Mapping**:
```yaml
parameters:
  - name: param
    in: path
    required: true
    schema:
      type: string
```

#### Query Parameters
**HTML Pattern**:
```html
<h4 id="query-parameters">Query parameters</h4>
<table>
  <tr><td><strong>param_name</strong></td><td><em>type</em></td><td>Description</td></tr>
</table>
```

**OpenAPI Mapping**:
```yaml
parameters:
  - name: param_name
    in: query
    required: false
    schema:
      type: type
    description: "Description"
```

### 4. Request Body

**HTML Pattern**:
```html
<h4 id="required-parameters">Required parameters</h4>
<table>...</table>
<h4 id="optional-parameters">Optional parameters</h4>
<table>...</table>
```

**OpenAPI Mapping**:
```yaml
requestBody:
  required: true
  content:
    application/json:
      schema:
        type: object
        required: [required_fields]
        properties:
          field_name:
            type: field_type
            description: "Field description"
```

### 5. Response Schema

**HTML Pattern**:
```html
<div class="highlight"><pre class="highlight plaintext"><code>Example Response</code></pre></div>
<div class="highlight"><pre class="highlight http"><code>
HTTP/1.1 200 OK
Content-Type: application/json

{JSON_CONTENT}
</code></pre></div>
```

**OpenAPI Mapping**:
```yaml
responses:
  '200':
    description: "Success"
    content:
      application/json:
        schema:
          # Generated from JSON_CONTENT
        example:
          # JSON_CONTENT
```

### 6. Error Responses

**HTML Pattern**:
```html
<h4 id="potential-errors-experimental">Potential errors</h4>
<table>
  <tr><td>Title</td><td>Code</td><td>HTTP Status</td><td>Description</td></tr>
</table>
```

**OpenAPI Mapping**:
```yaml
responses:
  'HTTP_STATUS':
    description: "Error Title"
    content:
      application/json:
        schema:
          $ref: '#/components/schemas/Error'
```

### 7. Security/Authorization

**HTML Pattern**:
```html
<h4 id="permitted-roles">Permitted roles</h4>
<table>
  <tr><td>Role Name</td></tr>
</table>
```

**OpenAPI Mapping**:
```yaml
security:
  - bearerAuth: []
x-required-roles:
  - "Role Name"
```

## Data Type Mappings

| HTML Type | OpenAPI Type | Format | Notes |
|-----------|--------------|--------|-------|
| `string` | `string` | - | Default string type |
| `integer` | `integer` | `int32` | 32-bit integers |
| `number` | `number` | `float` | Floating point numbers |
| `boolean` | `boolean` | - | true/false values |
| `object` | `object` | - | JSON objects |
| `array` | `array` | - | Arrays of items |
| `datetime` | `string` | `date-time` | ISO 8601 format |
| `uuid` | `string` | `uuid` | UUID format |
| `to-one relationship` | `object` | - | Nested object with data.guid |
| `to-many relationship` | `object` | - | Nested object with data array |

## Object Schema Extraction

### Resource Objects

**HTML Pattern**:
```html
<h3 id="the-resource-object">The resource object</h3>
<div class="highlight"><pre class="highlight json"><code>{EXAMPLE_JSON}</code></pre></div>
```

**Extraction Rules**:
1. Parse EXAMPLE_JSON to understand object structure
2. Generate JSON Schema from the example
3. Add to components/schemas section
4. Use $ref to reference in operations

### Nested Objects

**Identification**:
- Links to other sections (e.g., `<a href="#lifecycle-object">`)
- Inline object definitions in parameter tables

**Handling**:
- Create separate schema definitions
- Use $ref for reusability
- Maintain object hierarchy

## Special Cases

### 1. Shared Path/Method Endpoints
Some endpoints share the same path and method but differ in query parameters or request body.

**Solution**:
- Use `oneOf` in request body schema
- Document parameter combinations in description
- Consider using discriminator if applicable

### 2. Conditional Parameters
Parameters that are only valid with certain other parameters.

**Solution**:
- Use `dependencies` in JSON Schema
- Document conditions in parameter descriptions
- Add custom x-extensions if needed

### 3. Polymorphic Responses
Responses that vary based on resource type or state.

**Solution**:
- Use `oneOf` or `anyOf` in response schema
- Include discriminator property if available
- Provide examples for each variant

### 4. Pagination
List endpoints with pagination parameters.

**Standard Parameters**:
- `page` (integer): Page number
- `per_page` (integer): Results per page
- `order_by` (string): Sort field
- `label_selector` (string): Label filtering

### 5. Include Parameters
Parameters for including related resources.

**Pattern**: `include=resource1,resource2`

**Handling**:
- Define as query parameter with array type
- Document available include values
- Show response variations in examples

## Extraction Algorithm

1. **Parse TOC**: Extract all endpoint sections from table of contents
2. **For each endpoint section**:
   - Find definition header and extract method/path
   - Extract description from section introduction
   - Parse parameter tables (required/optional)
   - Extract example request/response
   - Parse error tables
   - Extract security requirements
3. **Generate schemas**: 
   - Create object schemas from examples
   - Build parameter schemas from tables
   - Generate response schemas
4. **Handle references**:
   - Identify shared objects
   - Create component schemas
   - Replace with $ref references
5. **Validate**: Ensure all required OpenAPI fields are present

## Quality Checks

- [ ] All endpoints have unique operationId
- [ ] All parameters have descriptions
- [ ] All schemas have required fields defined
- [ ] Examples match their schemas
- [ ] Error responses are comprehensive
- [ ] Security is properly defined
- [ ] No undefined $ref references