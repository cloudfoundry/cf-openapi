# Security Features Guide

This guide covers Cloud Foundry's security features including security groups, network policies, SSH access control, and environment variable security.

## Overview

Cloud Foundry provides multiple layers of security:
- **Network Security** - Security groups and network policies
- **Access Control** - SSH restrictions and authentication
- **Data Protection** - Environment variable encryption
- **Audit Trail** - Comprehensive event logging
- **Isolation** - Container and namespace separation

## Security Groups

Security groups control outbound network traffic from applications and staging containers.

### Security Group Rules

Define allowed outbound connections:

```bash
POST /v3/security_groups
```

```json
{
  "name": "public-networks",
  "rules": [
    {
      "protocol": "tcp",
      "destination": "0.0.0.0/0",
      "ports": "443",
      "description": "Allow HTTPS to any destination"
    },
    {
      "protocol": "tcp",
      "destination": "10.0.0.0/8",
      "ports": "5432",
      "description": "Allow PostgreSQL to internal network"
    },
    {
      "protocol": "udp",
      "destination": "8.8.8.8",
      "ports": "53",
      "description": "Allow DNS queries to Google DNS"
    },
    {
      "protocol": "icmp",
      "destination": "0.0.0.0/0",
      "type": 8,
      "code": 0,
      "description": "Allow ICMP ping"
    }
  ],
  "metadata": {
    "labels": {
      "purpose": "public-access"
    }
  }
}
```

### Rule Properties

- **protocol**: `tcp`, `udp`, `icmp`, or `all`
- **destination**: IP address, CIDR range, or IP range
- **ports**: Single port, range (e.g., "8080-8090"), or comma-separated list
- **type/code**: For ICMP protocol only
- **log**: Enable logging (default: false)
- **description**: Human-readable description

### Destination Formats

```json
// CIDR notation
{ "destination": "192.168.1.0/24" }

// IP range
{ "destination": "192.168.1.1-192.168.1.254" }

// Single IP
{ "destination": "192.168.1.1" }

// Multiple ports
{ "ports": "80,443,8080-8090" }
```

### Binding Security Groups

#### Staging Security Groups

Applied during app staging:

```bash
# Bind globally (platform-wide)
POST /v3/security_groups/{guid}/relationships/staging_spaces
```

```json
{
  "data": []
}
```

#### Running Security Groups

Applied to running applications:

```bash
# Bind globally
POST /v3/security_groups/{guid}/relationships/running_spaces
```

```json
{
  "data": []
}
```

#### Space-Specific Binding

Bind to specific spaces:

```bash
# Staging
POST /v3/security_groups/{guid}/relationships/staging_spaces
```

```json
{
  "data": [
    { "guid": "space-guid-1" },
    { "guid": "space-guid-2" }
  ]
}
```

```bash
# Running
POST /v3/security_groups/{guid}/relationships/running_spaces
```

### Default Security Groups

Cloud Foundry typically includes default groups:

1. **dns** - Allow DNS resolution
2. **public_networks** - Internet access
3. **private_networks** - RFC1918 ranges (often restricted)

### Security Group Precedence

1. Platform defaults (lowest priority)
2. Organization security groups
3. Space security groups (highest priority)

All rules are additive (allow-list based).

## Network Policies

Network policies control app-to-app communication within Cloud Foundry.

### Creating Network Policies

Allow communication between apps:

```bash
POST /networking/v1/external/policies
```

```json
{
  "policies": [
    {
      "source": {
        "id": "source-app-guid"
      },
      "destination": {
        "id": "destination-app-guid",
        "protocol": "tcp",
        "ports": {
          "start": 8080,
          "end": 8080
        }
      }
    }
  ]
}
```

### Policy Properties

- **source.id**: Source app GUID
- **destination.id**: Destination app GUID
- **protocol**: `tcp` or `udp`
- **ports**: Port range (start and end)

### Container-to-Container Networking

Enable internal communication:

1. Apps must use internal routes
2. Network policy must exist
3. Apps discover each other via internal DNS

Example internal URL:
```
http://backend.apps.internal:8080
```

### Network Policy Use Cases

1. **Microservices Communication**
   ```json
   {
     "policies": [{
       "source": { "id": "frontend-app" },
       "destination": {
         "id": "backend-api",
         "protocol": "tcp",
         "ports": { "start": 8080, "end": 8080 }
       }
     }]
   }
   ```

2. **Database Access**
   ```json
   {
     "policies": [{
       "source": { "id": "app-guid" },
       "destination": {
         "id": "database-app-guid",
         "protocol": "tcp",
         "ports": { "start": 5432, "end": 5432 }
       }
     }]
   }
   ```

## SSH Access Control

Control SSH access to application containers.

### Space-Level SSH Control

```bash
# Check SSH status
GET /v3/spaces/{guid}/features/ssh

# Enable/disable SSH
PATCH /v3/spaces/{guid}/features/ssh
```

```json
{
  "enabled": true
}
```

### App-Level SSH Control

```bash
# Check app SSH status
GET /v3/apps/{guid}/features/ssh

# Enable/disable for specific app
PATCH /v3/apps/{guid}/features/ssh
```

```json
{
  "enabled": false
}
```

### SSH Access Hierarchy

SSH must be enabled at all levels:
1. Platform level (admin setting)
2. Space level
3. App level

If disabled at any level, SSH access is denied.

### SSH Security Best Practices

1. **Disable by Default**
   - Enable only when needed
   - Disable after troubleshooting

2. **Audit SSH Sessions**
   - Monitor SSH access logs
   - Track who accesses containers

3. **Time-Limited Access**
   - Enable temporarily
   - Automate disabling

## Environment Variable Security

Protect sensitive data in environment variables.

### Secure Practices

1. **Never Store Secrets Directly**
   ```json
   // DON'T DO THIS
   {
     "environment_variables": {
       "DATABASE_PASSWORD": "plaintext-password"
     }
   }
   ```

2. **Use Service Bindings**
   - Credentials injected securely
   - Rotatable through rebinding
   - Automated by service brokers

3. **Use CredHub Integration**
   ```json
   {
     "environment_variables": {
       "DATABASE_URL": "((database-url))"
     }
   }
   ```

### Environment Variable Restrictions

Cloud Foundry reserves certain prefixes:
- `VCAP_*` - System use only
- `CF_*` - Platform variables
- `PORT` - Assigned by platform

### Viewing Environment Variables

```bash
# Get app environment (requires SpaceDeveloper role)
GET /v3/apps/{guid}/env
```

Response includes:
- User-provided variables
- System environment variables
- Service credentials (VCAP_SERVICES)

### Protecting Sensitive Data

1. **Use Service Brokers**
   - Automated credential management
   - Secure storage and rotation

2. **External Secret Stores**
   - HashiCorp Vault
   - AWS Secrets Manager
   - Azure Key Vault

3. **Credential Rotation**
   - Regular rotation schedule
   - Automated through CI/CD

## Audit Events

Track security-relevant activities.

### Viewing Audit Events

```bash
GET /v3/audit_events
```

### Security-Related Events

Key events to monitor:

1. **Authentication Events**
   - `audit.user.login`
   - `audit.user.logout`
   - `audit.token.create`

2. **Authorization Events**
   - `audit.role.create`
   - `audit.role.delete`
   - `audit.permission.grant`

3. **Resource Access**
   - `audit.app.ssh-authorized`
   - `audit.app.environment_variables.view`
   - `audit.service_binding.create`

4. **Security Configuration**
   - `audit.security_group.create`
   - `audit.security_group.update`
   - `audit.network_policy.create`

### Audit Event Details

```json
{
  "guid": "event-guid",
  "type": "audit.app.ssh-authorized",
  "actor": {
    "guid": "user-guid",
    "type": "user",
    "name": "admin@example.com"
  },
  "target": {
    "guid": "app-guid",
    "type": "app",
    "name": "production-api"
  },
  "data": {
    "index": 0
  },
  "created_at": "2025-01-26T15:30:00Z"
}
```

### Audit Log Retention

- Default retention varies by deployment
- Export to external SIEM systems
- Implement long-term storage strategy

## Platform Security Features

### Container Isolation

Each app instance runs in isolated containers:
- Separate namespaces
- Resource limits (CPU, memory)
- Restricted system calls
- Read-only root filesystem

### Build Security

During staging:
- Isolated build containers
- Time-limited execution
- Network restrictions
- No persistent storage

### Runtime Security

Running applications have:
- Minimal attack surface
- No root access
- Limited system capabilities
- Enforced resource quotas

## Security Best Practices

### 1. Network Security

**Principle of Least Privilege**
```json
{
  "rules": [
    {
      "protocol": "tcp",
      "destination": "10.0.1.5",
      "ports": "5432",
      "description": "Only allow connection to specific database"
    }
  ]
}
```

**Deny by Default**
- Start with no outbound access
- Add only required connections
- Document each rule purpose

### 2. Access Control

**Role-Based Access**
- Assign minimum required roles
- Regular access reviews
- Remove unused permissions

**Service Account Security**
- Unique accounts per system
- Regular credential rotation
- Monitor usage patterns

### 3. Data Protection

**Encryption in Transit**
- Force HTTPS for all routes
- Use TLS for service connections
- Verify certificates

**Secrets Management**
- No hardcoded credentials
- Use platform secret services
- Implement rotation policies

### 4. Monitoring and Compliance

**Security Monitoring**
```bash
# Monitor SSH access
GET /v3/audit_events?types=audit.app.ssh-authorized

# Track security group changes
GET /v3/audit_events?types=audit.security_group.update

# Monitor role assignments
GET /v3/audit_events?types=audit.role.create
```

**Compliance Reporting**
- Regular security audits
- Automated compliance checks
- Document security policies

## Advanced Security Topics

### Zero Trust Networking

Implement zero trust principles:

1. **Verify Everything**
   - Authenticate all connections
   - Authorize each request
   - Encrypt all traffic

2. **Microsegmentation**
   ```json
   {
     "policies": [{
       "source": { "id": "frontend" },
       "destination": {
         "id": "backend",
         "protocol": "tcp",
         "ports": { "start": 8080, "end": 8080 }
       }
     }]
   }
   ```

3. **Continuous Verification**
   - Monitor all connections
   - Detect anomalies
   - Respond automatically

### Security Automation

Automate security tasks:

```bash
#!/bin/bash
# Automated security group audit

# List all security groups
groups=$(cf curl /v3/security_groups | jq -r '.resources[].guid')

for group in $groups; do
  # Check for overly permissive rules
  rules=$(cf curl /v3/security_groups/$group | jq '.rules[]')
  
  # Alert on 0.0.0.0/0 destinations
  if echo "$rules" | grep -q '"destination":"0.0.0.0/0"'; then
    echo "WARNING: Security group $group has unrestricted destination"
  fi
done
```

### Incident Response

Prepare for security incidents:

1. **Detection**
   - Monitor audit logs
   - Set up alerts
   - Track anomalies

2. **Response**
   - Isolate affected apps
   - Revoke compromised credentials
   - Update security groups

3. **Recovery**
   - Restore from backups
   - Apply security patches
   - Update policies

## Security Checklist

### Application Security
- [ ] SSH disabled by default
- [ ] Minimal security group rules
- [ ] Network policies configured
- [ ] Secrets in service bindings
- [ ] Regular dependency updates

### Platform Security
- [ ] Audit logging enabled
- [ ] Log forwarding configured
- [ ] Regular security updates
- [ ] Access reviews scheduled
- [ ] Incident response plan

### Compliance
- [ ] Security policies documented
- [ ] Regular security training
- [ ] Compliance audits scheduled
- [ ] Vulnerability scanning
- [ ] Penetration testing

## Troubleshooting Security Issues

### Common Problems

1. **Connection Blocked**
   - Check security groups
   - Verify network policies
   - Review destination IPs

2. **SSH Access Denied**
   - Verify space SSH enabled
   - Check app SSH setting
   - Confirm user permissions

3. **Audit Events Missing**
   - Check retention settings
   - Verify permissions
   - Ensure logging enabled

### Debug Commands

```bash
# Check effective security groups
GET /v3/spaces/{guid}/staging_security_groups
GET /v3/spaces/{guid}/running_security_groups

# Verify network policies
GET /networking/v1/external/policies?id=app-guid

# Review recent security events
GET /v3/audit_events?order_by=-created_at&types=audit.security_group
```

## Related Documentation

- [Authentication Guide](authentication.md) - User authentication and authorization
- [Organizations & Spaces](orgs-spaces.md) - Access control hierarchy
- [Core Resources Guide](core-resources.md) - Application security settings