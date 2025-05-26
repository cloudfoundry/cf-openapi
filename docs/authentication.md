# Authentication & Authorization Guide

This guide covers authentication and authorization for the Cloud Foundry API, including UAA integration, token management, and role-based access control.

## Overview

Cloud Foundry uses OAuth 2.0 for API authentication via the User Account and Authentication (UAA) service. All API requests (except `/` and `/v3/info`) require a valid Bearer token.

## UAA Basics

UAA is Cloud Foundry's identity management service that handles:
- User authentication
- OAuth 2.0 token issuance
- Client registration
- User management
- Group and scope management

### Finding the UAA Endpoint

```bash
curl https://api.example.com/v3/info
```

Response includes:
```json
{
  "links": {
    "self": {
      "href": "https://api.example.com/v3/info"
    },
    "login": {
      "href": "https://login.example.com"
    },
    "uaa": {
      "href": "https://uaa.example.com"
    }
  }
}
```

## Authentication Methods

### 1. Password Grant (Users)

For interactive user authentication:

```bash
curl -X POST https://uaa.example.com/oauth/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -H "Accept: application/json" \
  -d "grant_type=password" \
  -d "username=user@example.com" \
  -d "password=userpassword" \
  -d "client_id=cf" \
  -d "client_secret="
```

### 2. Client Credentials (Service Accounts)

For automated systems and CI/CD:

```bash
curl -X POST https://uaa.example.com/oauth/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -H "Accept: application/json" \
  -d "grant_type=client_credentials" \
  -d "client_id=my-service-account" \
  -d "client_secret=my-client-secret"
```

### 3. Authorization Code (Web Apps)

For web applications with user login:

1. **Redirect user to authorize**:
```
https://login.example.com/oauth/authorize?
  response_type=code&
  client_id=my-app&
  redirect_uri=https://myapp.com/callback&
  scope=cloud_controller.read cloud_controller.write
```

2. **Exchange code for token**:
```bash
curl -X POST https://uaa.example.com/oauth/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=authorization_code" \
  -d "code=AUTHORIZATION_CODE" \
  -d "client_id=my-app" \
  -d "client_secret=my-secret" \
  -d "redirect_uri=https://myapp.com/callback"
```

### 4. Refresh Token

Refresh an expired access token:

```bash
curl -X POST https://uaa.example.com/oauth/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=refresh_token" \
  -d "refresh_token=REFRESH_TOKEN" \
  -d "client_id=cf" \
  -d "client_secret="
```

## Token Response

Successful authentication returns:

```json
{
  "access_token": "eyJhbGciOiJSUzI1NiIsI...",
  "token_type": "bearer",
  "refresh_token": "eyJhbGciOiJSUzI1NiIsI...",
  "expires_in": 599,
  "scope": "cloud_controller.read cloud_controller.write",
  "jti": "28f8c3f1-f5f9-4c5d-8b8e-8c6a0835e650"
}
```

## Using Tokens

Include the token in the Authorization header:

```bash
curl https://api.example.com/v3/apps \
  -H "Authorization: bearer eyJhbGciOiJSUzI1NiIsI..."
```

## Token Validation

### Introspection

Check if a token is valid:

```bash
curl -X POST https://uaa.example.com/introspect \
  -H "Authorization: Basic <base64(client_id:client_secret)>" \
  -d "token=ACCESS_TOKEN"
```

### Token Info

Get details about the current token:

```bash
curl https://uaa.example.com/token_info \
  -H "Authorization: bearer ACCESS_TOKEN"
```

## Scopes and Permissions

### Common Scopes

- `cloud_controller.read` - Read access to Cloud Controller
- `cloud_controller.write` - Write access to Cloud Controller
- `cloud_controller.admin` - Admin access to Cloud Controller
- `cloud_controller.admin_read_only` - Read-only admin access
- `cloud_controller.global_auditor` - View all resources

### Scope Hierarchy

```
cloud_controller.admin
  └── cloud_controller.write
      └── cloud_controller.read
```

## Cloud Foundry Roles

### Organization Roles

- **OrgManager** - Can manage the organization
  - Create/modify spaces
  - Manage users and roles
  - View billing and quotas

- **OrgAuditor** - Read-only access to organization
  - View all spaces
  - View all apps and services

- **BillingManager** - Can manage billing
  - View and modify billing info
  - View quotas

### Space Roles

- **SpaceManager** - Can manage the space
  - Manage space users
  - View and modify all resources

- **SpaceDeveloper** - Can manage apps and services
  - Create/modify/delete apps
  - Manage service instances
  - View logs and stats

- **SpaceAuditor** - Read-only access to space
  - View all resources
  - Cannot modify anything

### Role Assignment

```bash
# Assign org role
POST /v3/roles
{
  "type": "organization_manager",
  "relationships": {
    "user": {
      "data": {
        "guid": "user-guid"
      }
    },
    "organization": {
      "data": {
        "guid": "org-guid"
      }
    }
  }
}

# Assign space role
POST /v3/roles
{
  "type": "space_developer",
  "relationships": {
    "user": {
      "data": {
        "guid": "user-guid"
      }
    },
    "space": {
      "data": {
        "guid": "space-guid"
      }
    }
  }
}
```

## Service Account Setup

### 1. Create UAA Client

Using UAA CLI:
```bash
uaac client add my-service \
  --authorized_grant_types client_credentials \
  --authorities cloud_controller.read,cloud_controller.write \
  --scope cloud_controller.read,cloud_controller.write
```

### 2. Best Practices for Service Accounts

- Use descriptive client IDs
- Limit scope to minimum required
- Rotate credentials regularly
- Store secrets securely (e.g., Vault, KMS)
- Use separate accounts per environment

## Token Management Best Practices

### 1. Token Refresh Strategy

```javascript
async function makeAPICall(url, options = {}) {
  try {
    const response = await fetch(url, {
      ...options,
      headers: {
        ...options.headers,
        'Authorization': `bearer ${getAccessToken()}`
      }
    });
    
    if (response.status === 401) {
      await refreshAccessToken();
      return makeAPICall(url, options);
    }
    
    return response;
  } catch (error) {
    throw error;
  }
}
```

### 2. Token Storage

- **Never** store tokens in:
  - Git repositories
  - Unencrypted files
  - URL parameters
  - Browser local storage (for sensitive apps)

- **Do** store tokens in:
  - Environment variables
  - Secure key management services
  - Encrypted configuration
  - Secure session storage

### 3. Token Lifetime

- Access tokens: Typically 5-60 minutes
- Refresh tokens: Hours to days
- Configure based on security requirements

## Multi-Factor Authentication (MFA)

If MFA is enabled:

1. Initial authentication returns MFA challenge
2. Submit MFA code:
```bash
curl -X POST https://login.example.com/oauth/token \
  -d "grant_type=password" \
  -d "username=user@example.com" \
  -d "password=password" \
  -d "mfaCode=123456" \
  -d "client_id=cf"
```

## SSO Integration

Cloud Foundry supports various SSO providers:

- SAML 2.0
- LDAP
- OAuth 2.0 / OIDC
- Active Directory

Configuration is done at the UAA level.

## Troubleshooting Authentication

### Common Errors

1. **401 Unauthorized**
   - Token expired or invalid
   - Missing Authorization header
   - Incorrect token format

2. **403 Forbidden**
   - Valid token but insufficient permissions
   - Not a member of org/space
   - Missing required role

3. **Invalid Token Error**
   ```json
   {
     "error": "invalid_token",
     "error_description": "The token expired"
   }
   ```

### Debugging Steps

1. **Verify token validity**:
   ```bash
   curl https://uaa.example.com/check_token \
     -H "Authorization: bearer TOKEN"
   ```

2. **Check token contents**:
   ```bash
   # Decode JWT (base64)
   echo "TOKEN" | cut -d. -f2 | base64 -d | jq
   ```

3. **Verify API endpoint**:
   ```bash
   curl https://api.example.com/v3/info
   ```

4. **Check user permissions**:
   ```bash
   cf curl /v3/roles?user_guids=USER_GUID
   ```

## Security Best Practices

1. **Use HTTPS Always** - Never send tokens over unencrypted connections

2. **Implement Token Rotation** - Refresh tokens before expiration

3. **Audit Token Usage** - Monitor and log API access

4. **Principle of Least Privilege** - Grant minimum required permissions

5. **Secure Token Storage** - Encrypt tokens at rest

6. **Implement Rate Limiting** - Prevent token abuse

7. **Monitor Failed Authentications** - Detect potential attacks

## Advanced Topics

### Custom OAuth Clients

Register custom clients for specific use cases:

```bash
uaac client add my-app \
  --name "My Application" \
  --scope "openid,cloud_controller.read" \
  --authorized_grant_types "authorization_code,refresh_token" \
  --redirect_uri "https://myapp.com/callback" \
  --access_token_validity 3600 \
  --refresh_token_validity 86400
```

### Token Exchange

Exchange an external IdP token for UAA token:

```bash
curl -X POST https://uaa.example.com/oauth/token \
  -d "grant_type=urn:ietf:params:oauth:grant-type:token-exchange" \
  -d "subject_token=EXTERNAL_TOKEN" \
  -d "subject_token_type=urn:ietf:params:oauth:token-type:id_token"
```

### Impersonation

Admin users can impersonate other users:

```bash
curl -X POST https://uaa.example.com/oauth/token \
  -d "grant_type=client_credentials" \
  -d "client_id=admin-client" \
  -d "client_secret=admin-secret" \
  -d "requested_token_format=opaque" \
  -d "response_type=token" \
  -d "actor_id=admin-user-id" \
  -d "subject_id=target-user-id"
```

## Related Documentation

- [Getting Started Guide](getting-started.md) - Initial authentication setup
- [API Overview](api-overview.md) - Using tokens with the API
- [Troubleshooting Guide](troubleshooting.md) - Common auth issues