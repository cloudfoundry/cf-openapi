# Organizations & Spaces Guide

This guide covers Cloud Foundry's organizational hierarchy, including organizations, spaces, quotas, and isolation segments.

## Overview

Cloud Foundry uses a hierarchical structure for resource organization:

```
Platform
  └── Organizations
      └── Spaces
          └── Applications & Services
```

This structure provides:
- **Multi-tenancy** - Isolation between different teams/projects
- **Resource Management** - Quotas and limits
- **Access Control** - Role-based permissions
- **Billing Separation** - Cost tracking per organization

## Organizations

Organizations (orgs) are the top-level organizational unit in Cloud Foundry.

### Creating an Organization

```bash
POST /v3/organizations
```

```json
{
  "name": "my-company",
  "metadata": {
    "labels": {
      "company": "acme-corp",
      "environment": "production"
    },
    "annotations": {
      "contact": "platform-team@acme.com",
      "cost-center": "engineering"
    }
  }
}
```

### Organization Properties

```json
{
  "guid": "org-guid",
  "name": "my-company",
  "created_at": "2025-01-26T10:00:00Z",
  "updated_at": "2025-01-26T10:00:00Z",
  "suspended": false,
  "relationships": {
    "quota": {
      "data": {
        "guid": "quota-guid"
      }
    }
  },
  "metadata": {
    "labels": {},
    "annotations": {}
  },
  "links": {
    "self": {
      "href": "/v3/organizations/org-guid"
    },
    "spaces": {
      "href": "/v3/spaces?organization_guids=org-guid"
    },
    "domains": {
      "href": "/v3/domains?organization_guids=org-guid"
    }
  }
}
```

### Suspending Organizations

Suspend an org to prevent resource usage:

```bash
PATCH /v3/organizations/{guid}
```

```json
{
  "suspended": true
}
```

Effects of suspension:
- Apps cannot be started
- New resources cannot be created
- Existing apps continue running
- Billing may continue

### Organization Features

Organizations can:
- Own private domains
- Have custom quotas
- Contain multiple spaces
- Share resources between spaces
- Track usage and costs

## Spaces

Spaces provide isolated environments within an organization for deploying applications.

### Creating a Space

```bash
POST /v3/spaces
```

```json
{
  "name": "development",
  "relationships": {
    "organization": {
      "data": {
        "guid": "org-guid"
      }
    }
  },
  "metadata": {
    "labels": {
      "env": "dev",
      "team": "backend"
    },
    "annotations": {
      "purpose": "Development environment for backend team"
    }
  }
}
```

### Space Isolation

Each space provides:
- Separate application deployment area
- Independent service instances
- Isolated routes (unless shared)
- Distinct user permissions
- Separate SSH access control

### Space Features

Enable or disable features per space:

```bash
# Get current features
GET /v3/spaces/{guid}/features

# Enable SSH
PATCH /v3/spaces/{guid}/features/ssh
```

```json
{
  "enabled": true
}
```

Available features:
- `ssh` - SSH access to applications
- `unassigned_roles` - Unassigned org users can view space

### Space Security Groups

Assign security groups to a space:

```bash
POST /v3/spaces/{guid}/staging_security_groups
```

```json
{
  "data": [
    { "guid": "security-group-guid-1" },
    { "guid": "security-group-guid-2" }
  ]
}
```

## Roles and Permissions

Cloud Foundry uses role-based access control (RBAC).

### Organization Roles

#### OrgManager
- Create/delete spaces
- Manage organization settings
- View billing information
- Manage users and roles

```bash
POST /v3/roles
```

```json
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
```

#### OrgAuditor
- View all organization information
- Cannot make changes
- Useful for compliance/monitoring

```json
{
  "type": "organization_auditor",
  "relationships": {
    "user": {
      "data": { "guid": "user-guid" }
    },
    "organization": {
      "data": { "guid": "org-guid" }
    }
  }
}
```

#### BillingManager
- View and manage billing information
- View organization usage
- Cannot manage technical resources

### Space Roles

#### SpaceManager
- Manage space settings
- Add/remove space developers
- Cannot deploy applications

```json
{
  "type": "space_manager",
  "relationships": {
    "user": {
      "data": { "guid": "user-guid" }
    },
    "space": {
      "data": { "guid": "space-guid" }
    }
  }
}
```

#### SpaceDeveloper
- Deploy and manage applications
- Create and bind services
- View logs and metrics
- Full space access

```json
{
  "type": "space_developer",
  "relationships": {
    "user": {
      "data": { "guid": "user-guid" }
    },
    "space": {
      "data": { "guid": "space-guid" }
    }
  }
}
```

#### SpaceAuditor
- View all space information
- Cannot make changes
- Read-only access

#### SpaceSupporter
- View applications and services
- Cannot make changes
- SSH access if enabled

### Listing Roles

```bash
# User's roles
GET /v3/roles?user_guids=user-guid&include=organization,space

# Organization roles
GET /v3/roles?organization_guids=org-guid&include=user

# Space roles
GET /v3/roles?space_guids=space-guid&include=user
```

## Organization Quotas

Quotas limit resource consumption at the organization level.

### Creating an Organization Quota

```bash
POST /v3/organization_quotas
```

```json
{
  "name": "large-org-quota",
  "apps": {
    "total_memory_in_mb": 102400,
    "per_process_memory_in_mb": 8192,
    "total_instances": 1000,
    "per_app_tasks": 10,
    "log_rate_limit_in_bytes_per_second": 1048576
  },
  "services": {
    "paid_services_allowed": true,
    "total_service_instances": 500,
    "total_service_keys": 1000
  },
  "routes": {
    "total_routes": 1000,
    "total_reserved_ports": 10
  },
  "domains": {
    "total_domains": 20
  },
  "relationships": {
    "organizations": {
      "data": [
        { "guid": "org-guid-1" },
        { "guid": "org-guid-2" }
      ]
    }
  }
}
```

### Quota Limits

- **Memory**: Total memory across all apps
- **Instances**: Total app instances
- **Routes**: Maximum routes
- **Services**: Service instance limits
- **Reserved Ports**: For TCP routing
- **Log Rate**: Log output limits

### Assigning Quotas

```bash
# Assign to organization
PATCH /v3/organizations/{guid}/relationships/quota
```

```json
{
  "data": {
    "guid": "quota-guid"
  }
}
```

## Space Quotas

Space quotas provide limits within an organization.

### Creating a Space Quota

```bash
POST /v3/space_quotas
```

```json
{
  "name": "dev-space-quota",
  "apps": {
    "total_memory_in_mb": 10240,
    "per_process_memory_in_mb": 2048,
    "total_instances": 100,
    "per_app_tasks": 5,
    "log_rate_limit_in_bytes_per_second": 524288
  },
  "services": {
    "paid_services_allowed": false,
    "total_service_instances": 20,
    "total_service_keys": 50
  },
  "routes": {
    "total_routes": 50
  },
  "relationships": {
    "organization": {
      "data": {
        "guid": "org-guid"
      }
    },
    "spaces": {
      "data": [
        { "guid": "space-guid-1" },
        { "guid": "space-guid-2" }
      ]
    }
  }
}
```

### Space Quota Constraints

- Cannot exceed organization quota
- Applies to all resources in space
- Can be more restrictive than org quota

## Isolation Segments

Isolation segments provide dedicated infrastructure for organizations.

### Creating an Isolation Segment

```bash
POST /v3/isolation_segments
```

```json
{
  "name": "high-security-segment",
  "metadata": {
    "labels": {
      "compliance": "pci",
      "region": "us-east"
    },
    "annotations": {
      "description": "PCI-compliant infrastructure"
    }
  }
}
```

### Assigning to Organizations

```bash
POST /v3/isolation_segments/{guid}/relationships/organizations
```

```json
{
  "data": [
    { "guid": "org-guid-1" },
    { "guid": "org-guid-2" }
  ]
}
```

### Setting Default Isolation Segment

For an organization:
```bash
PATCH /v3/organizations/{guid}/relationships/default_isolation_segment
```

```json
{
  "data": {
    "guid": "isolation-segment-guid"
  }
}
```

For a space:
```bash
PATCH /v3/spaces/{guid}/relationships/isolation_segment
```

### Isolation Segment Use Cases

- **Compliance** - Separate regulated workloads
- **Performance** - Dedicated compute resources
- **Security** - Enhanced isolation
- **Geography** - Region-specific deployment

## Managing Organizations and Spaces

### Organization Operations

```bash
# List all organizations
GET /v3/organizations?order_by=name

# Get org with spaces
GET /v3/organizations/{guid}?include=spaces

# Get org usage summary
GET /v3/organizations/{guid}/usage_summary

# List org domains
GET /v3/organizations/{guid}/domains

# Get org users
GET /v3/users?organization_guids=org-guid
```

### Space Operations

```bash
# List spaces in an org
GET /v3/spaces?organization_guids=org-guid

# Get space with apps
GET /v3/spaces/{guid}?include=organization

# List apps in space
GET /v3/apps?space_guids=space-guid

# List services in space
GET /v3/service_instances?space_guids=space-guid

# Get space usage
GET /v3/spaces/{guid}/usage_summary
```

### User Management

```bash
# Add user to org
POST /v3/users

# Assign role
POST /v3/roles
{
  "type": "space_developer",
  "relationships": {
    "user": { "data": { "guid": "user-guid" } },
    "space": { "data": { "guid": "space-guid" } }
  }
}

# Remove role
DELETE /v3/roles/{role-guid}

# List user's organizations
GET /v3/organizations?user_guids=user-guid
```

## Best Practices

### Organization Structure

1. **Environment-based**
   ```
   acme-production
   acme-staging  
   acme-development
   ```

2. **Team-based**
   ```
   acme-frontend
   acme-backend
   acme-data
   ```

3. **Project-based**
   ```
   acme-project-a
   acme-project-b
   acme-shared-services
   ```

### Space Organization

1. **By Environment**
   - production
   - staging
   - development
   - testing

2. **By Component**
   - frontend
   - backend
   - services
   - databases

3. **By Team**
   - team-alpha
   - team-beta
   - shared

### Quota Management

1. **Start Conservative**
   - Begin with restrictive quotas
   - Increase based on actual usage
   - Monitor resource consumption

2. **Different Quotas per Environment**
   ```json
   // Production - larger quota
   {
     "name": "prod-quota",
     "apps": {
       "total_memory_in_mb": 204800
     }
   }
   
   // Development - smaller quota
   {
     "name": "dev-quota",
     "apps": {
       "total_memory_in_mb": 20480
     }
   }
   ```

3. **Regular Review**
   - Audit quota usage monthly
   - Adjust based on trends
   - Plan for growth

### Access Control

1. **Principle of Least Privilege**
   - Grant minimum required permissions
   - Use auditor roles for read-only access
   - Regularly review role assignments

2. **Separate Production Access**
   - Limited production space developers
   - Automated deployments via CI/CD
   - Audit trail for all changes

3. **Service Account Management**
   - Dedicated accounts for automation
   - Rotate credentials regularly
   - Monitor usage patterns

## Advanced Topics

### Cross-Space Resource Sharing

Share service instances between spaces:

```bash
POST /v3/service_instances/{guid}/relationships/shared_spaces
```

```json
{
  "data": [
    { "guid": "space-guid-1" },
    { "guid": "space-guid-2" }
  ]
}
```

### Space-to-Space Networking

Enable communication between apps in different spaces:

1. Deploy apps with internal routes
2. Create network policies:

```bash
POST /v3/security_groups
```

```json
{
  "name": "space-to-space",
  "rules": [
    {
      "protocol": "tcp",
      "destination": "10.0.0.0/8",
      "ports": "8080"
    }
  ]
}
```

### Organization Merging

When merging organizations:

1. Audit resources in both orgs
2. Ensure quota capacity
3. Migrate spaces one at a time
4. Update user roles
5. Transfer domains
6. Delete empty organization

## Troubleshooting

### Common Issues

1. **Quota Exceeded**
   ```json
   {
     "errors": [{
       "code": 310007,
       "title": "CF-QuotaExceeded",
       "detail": "Memory quota exceeded for organization"
     }]
   }
   ```
   Solution: Increase quota or reduce usage

2. **Permission Denied**
   - Verify user roles
   - Check space/org membership
   - Ensure feature is enabled

3. **Space Creation Failed**
   - Check org quota limits
   - Verify unique space name
   - Ensure org not suspended

### Debugging Commands

```bash
# Check org details
GET /v3/organizations/{guid}?include=quota

# Verify space quota
GET /v3/spaces/{guid}?include=quota,organization

# List user permissions
GET /v3/roles?user_guids=user-guid&include=space,organization

# Check isolation segment
GET /v3/spaces/{guid}/relationships/isolation_segment
```

## Usage Monitoring

### Organization Usage

```bash
GET /v3/organizations/{guid}/usage_summary
```

Response:
```json
{
  "usage_summary": {
    "started_instances": 45,
    "memory_in_mb": 92160,
    "routes": 125,
    "service_instances": 30,
    "spaces": 5
  }
}
```

### Space Usage

Monitor space consumption:

```bash
GET /v3/spaces/{guid}/usage_summary
```

### Quota Utilization

Track quota usage:

```bash
# Get current usage vs quota
GET /v3/organizations/{guid}?include=quota
# Compare usage_summary with quota limits
```

## Related Documentation

- [Authentication Guide](authentication.md) - User and role management
- [Core Resources Guide](core-resources.md) - Apps and services in spaces
- [Security Features](security.md) - Security groups and policies