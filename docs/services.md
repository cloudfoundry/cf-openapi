# Services Guide

This guide covers Cloud Foundry's service ecosystem, including managed services, user-provided services, and service bindings.

## Overview

Cloud Foundry services provide applications with external dependencies like databases, message queues, and third-party APIs. Services are made available through:

- **Service Brokers** - Implement the Open Service Broker API
- **Marketplace** - Catalog of available services
- **Service Instances** - Provisioned services
- **Service Bindings** - Connections between apps and services

## Service Concepts

### Service Hierarchy

```
Service Broker
  └── Service Offerings (e.g., PostgreSQL)
      └── Service Plans (e.g., small, medium, large)
          └── Service Instances (e.g., my-postgres-db)
              └── Service Bindings (credentials)
```

### Service Types

1. **Managed Services** - Provisioned through service brokers
2. **User-Provided Services** - External services with manual credentials
3. **Route Services** - Process requests before reaching apps

## Service Brokers

Service brokers implement the Open Service Broker API to provision and manage service instances.

### Registering a Service Broker

```bash
POST /v3/service_brokers
```

```json
{
  "name": "my-broker",
  "url": "https://broker.example.com",
  "authentication": {
    "type": "basic",
    "credentials": {
      "username": "broker-user",
      "password": "broker-password"
    }
  },
  "metadata": {
    "labels": {
      "provider": "acme-corp"
    }
  }
}
```

### Updating Service Broker Catalog

```bash
POST /v3/service_brokers/{guid}/actions/catalog_sync
```

This triggers Cloud Foundry to fetch the latest catalog from the broker.

### Space-Scoped Brokers

Create a broker visible only within a space:

```json
{
  "name": "space-broker",
  "url": "https://broker.example.com",
  "authentication": {
    "type": "basic",
    "credentials": {
      "username": "user",
      "password": "pass"
    }
  },
  "relationships": {
    "space": {
      "data": {
        "guid": "space-guid"
      }
    }
  }
}
```

## Service Offerings

Service offerings represent the services available from brokers.

### Listing Available Services

```bash
GET /v3/service_offerings
```

### Service Offering Properties

```json
{
  "guid": "offering-guid",
  "name": "postgresql",
  "description": "Reliable PostgreSQL Database",
  "available": true,
  "bindable": true,
  "instances_retrievable": true,
  "bindings_retrievable": true,
  "tags": ["postgresql", "relational", "database"],
  "requires": [],
  "metadata": {
    "labels": {},
    "annotations": {}
  },
  "relationships": {
    "service_broker": {
      "data": {
        "guid": "broker-guid"
      }
    }
  }
}
```

### Service Features

- `bindable` - Can create bindings
- `instances_retrievable` - Supports GET instance
- `bindings_retrievable` - Supports GET binding
- `plan_updateable` - Can change plans
- `allow_context_updates` - Supports context updates

## Service Plans

Service plans define different tiers or configurations of a service.

### Listing Service Plans

```bash
GET /v3/service_plans?service_offering_guids=offering-guid
```

### Plan Visibility

Control which organizations can see specific plans:

```bash
# Make plan public
PATCH /v3/service_plans/{guid}/visibility
```

```json
{
  "type": "public"
}
```

```bash
# Restrict to specific organizations
PATCH /v3/service_plans/{guid}/visibility
```

```json
{
  "type": "organization",
  "organizations": [
    { "guid": "org-guid-1" },
    { "guid": "org-guid-2" }
  ]
}
```

### Plan Properties

```json
{
  "guid": "plan-guid",
  "name": "small",
  "description": "Small PostgreSQL instance",
  "free": false,
  "broker_catalog": {
    "id": "broker-plan-id",
    "metadata": {
      "costs": [
        {
          "amount": {
            "usd": 99.0
          },
          "unit": "MONTHLY"
        }
      ],
      "bullets": [
        "10 GB storage",
        "100 connections"
      ]
    }
  },
  "schemas": {
    "service_instance": {
      "create": {
        "parameters": {
          "$schema": "http://json-schema.org/draft-04/schema#",
          "type": "object",
          "properties": {
            "backup_enabled": {
              "type": "boolean"
            }
          }
        }
      }
    }
  }
}
```

## Service Instances

Service instances are provisioned services ready for use.

### Creating a Service Instance

```bash
POST /v3/service_instances
```

```json
{
  "name": "my-database",
  "type": "managed",
  "parameters": {
    "backup_enabled": true,
    "encryption": "at-rest"
  },
  "tags": ["production", "critical"],
  "relationships": {
    "space": {
      "data": {
        "guid": "space-guid"
      }
    },
    "service_plan": {
      "data": {
        "guid": "plan-guid"
      }
    }
  },
  "metadata": {
    "labels": {
      "env": "production"
    },
    "annotations": {
      "owner": "database-team@example.com"
    }
  }
}
```

### Asynchronous Provisioning

Long-running provisions return a job:

```json
{
  "guid": "instance-guid",
  "last_operation": {
    "type": "create",
    "state": "in progress",
    "description": "Provisioning database instance"
  },
  "links": {
    "job": {
      "href": "/v3/jobs/job-guid"
    }
  }
}
```

### Updating Service Instances

```bash
PATCH /v3/service_instances/{guid}
```

```json
{
  "name": "production-database",
  "parameters": {
    "backup_enabled": true,
    "backup_schedule": "daily"
  },
  "tags": ["production", "critical", "postgresql"],
  "metadata": {
    "labels": {
      "env": "production",
      "tier": "1"
    }
  }
}
```

### Upgrading Service Plans

```bash
PATCH /v3/service_instances/{guid}/relationships/service_plan
```

```json
{
  "data": {
    "guid": "new-plan-guid"
  }
}
```

### Service Instance Sharing

Share instances across spaces:

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

## User-Provided Service Instances

For external services not managed by Cloud Foundry:

```bash
POST /v3/service_instances
```

```json
{
  "name": "external-api",
  "type": "user-provided",
  "credentials": {
    "url": "https://api.external.com",
    "api_key": "secret-key",
    "username": "api-user"
  },
  "syslog_drain_url": "syslog://logs.example.com:514",
  "route_service_url": "https://proxy.example.com",
  "tags": ["external", "api"],
  "relationships": {
    "space": {
      "data": {
        "guid": "space-guid"
      }
    }
  }
}
```

## Service Bindings

Service bindings connect applications to service instances, typically providing credentials.

### Types of Bindings

1. **App Bindings** - Credentials injected into app environment
2. **Key Bindings** - Standalone credentials (service keys)
3. **Route Bindings** - Route services (experimental)

### Creating an App Binding

```bash
POST /v3/service_credential_bindings
```

```json
{
  "name": "my-binding",
  "type": "app",
  "parameters": {
    "role": "read-write"
  },
  "relationships": {
    "app": {
      "data": {
        "guid": "app-guid"
      }
    },
    "service_instance": {
      "data": {
        "guid": "instance-guid"
      }
    }
  }
}
```

### Binding Response

```json
{
  "guid": "binding-guid",
  "name": "my-binding",
  "last_operation": {
    "type": "create",
    "state": "succeeded"
  },
  "relationships": {
    "app": {
      "data": {
        "guid": "app-guid"
      }
    },
    "service_instance": {
      "data": {
        "guid": "instance-guid"
      }
    }
  }
}
```

### Accessing Credentials

Credentials are injected into the app's environment:

```bash
GET /v3/apps/{guid}/env
```

```json
{
  "environment_variables": {},
  "system_env_json": {
    "VCAP_SERVICES": {
      "postgresql": [
        {
          "name": "my-database",
          "label": "postgresql",
          "tags": ["postgresql", "relational"],
          "credentials": {
            "uri": "postgres://user:pass@host:5432/db",
            "hostname": "host.example.com",
            "port": 5432,
            "username": "user",
            "password": "pass",
            "database": "db"
          }
        }
      ]
    }
  }
}
```

### Creating a Service Key

For accessing credentials without an app:

```json
{
  "name": "admin-key",
  "type": "key",
  "parameters": {
    "role": "admin"
  },
  "relationships": {
    "service_instance": {
      "data": {
        "guid": "instance-guid"
      }
    }
  }
}
```

### Getting Service Key Details

```bash
GET /v3/service_credential_bindings/{guid}/details
```

```json
{
  "credentials": {
    "uri": "postgres://admin:secret@host:5432/db",
    "hostname": "host.example.com",
    "port": 5432,
    "username": "admin",
    "password": "secret",
    "database": "db"
  }
}
```

## Route Services

Route services process requests before they reach applications.

### Creating a Route Service Binding

```bash
POST /v3/service_route_bindings
```

```json
{
  "parameters": {
    "rate_limit": "1000req/min"
  },
  "relationships": {
    "route": {
      "data": {
        "guid": "route-guid"
      }
    },
    "service_instance": {
      "data": {
        "guid": "instance-guid"
      }
    }
  }
}
```

## Service Operations

### Listing All Services in a Space

```bash
# Get managed service instances
GET /v3/service_instances?space_guids=space-guid

# Include service plan and offering info
GET /v3/service_instances?space_guids=space-guid&include=service_plan,service_plan.service_offering
```

### Finding Bindings for an App

```bash
GET /v3/service_credential_bindings?app_guids=app-guid&include=service_instance
```

### Service Instance Lifecycle

1. **Create** → `in progress` → `succeeded`/`failed`
2. **Update** → `in progress` → `succeeded`/`failed`
3. **Delete** → `in progress` → (removed)

Monitor operations:
```bash
GET /v3/service_instances/{guid}

# Check last_operation
{
  "last_operation": {
    "type": "create",
    "state": "in progress",
    "description": "60% complete"
  }
}
```

## Best Practices

### Service Management

1. **Use Descriptive Names** - Include environment and purpose
2. **Tag Appropriately** - Use consistent tagging strategy
3. **Set Metadata** - Add labels for filtering and organization
4. **Plan Capacity** - Choose appropriate service plans
5. **Monitor Usage** - Track service metrics and costs

### Security

1. **Rotate Credentials** - Regularly recreate bindings
2. **Limit Access** - Use space isolation for sensitive services
3. **Audit Bindings** - Track who has access to services
4. **Encrypt in Transit** - Use TLS for all connections
5. **Parameter Validation** - Validate custom parameters

### High Availability

1. **Multi-Region** - Deploy services across regions
2. **Backup Strategy** - Regular automated backups
3. **Disaster Recovery** - Test restore procedures
4. **Connection Pooling** - Efficient resource usage
5. **Circuit Breakers** - Handle service failures gracefully

## Advanced Topics

### Custom Service Parameters

Define parameter schemas in service plans:

```json
{
  "schemas": {
    "service_instance": {
      "create": {
        "parameters": {
          "$schema": "http://json-schema.org/draft-04/schema#",
          "type": "object",
          "properties": {
            "backup_enabled": {
              "type": "boolean",
              "default": false
            },
            "region": {
              "type": "string",
              "enum": ["us-east", "us-west", "eu-central"]
            }
          }
        }
      }
    }
  }
}
```

### Service Context

Cloud Foundry provides context to brokers:

```json
{
  "context": {
    "platform": "cloudfoundry",
    "organization_guid": "org-guid",
    "organization_name": "my-org",
    "space_guid": "space-guid",
    "space_name": "production"
  }
}
```

### Orphaned Service Instances

Handle instances where the broker is unavailable:

```bash
# Purge orphaned instance
DELETE /v3/service_instances/{guid}?purge=true
```

## Troubleshooting

### Common Issues

1. **Provisioning Failures**
   - Check broker logs
   - Verify plan parameters
   - Ensure quota availability

2. **Binding Failures**
   - Verify app exists
   - Check bindable flag
   - Validate parameters

3. **Credential Issues**
   - Check VCAP_SERVICES format
   - Verify credential structure
   - Test connectivity

### Debugging Commands

```bash
# View service instance details
GET /v3/service_instances/{guid}

# Check binding details
GET /v3/service_credential_bindings/{guid}/details

# View broker catalog
GET /v3/service_offerings?service_broker_guids=broker-guid

# Check operation status
GET /v3/jobs/{job-guid}
```

## Related Documentation

- [Core Resources Guide](core-resources.md) - Application and service integration
- [Organizations & Spaces](orgs-spaces.md) - Service visibility and access
- [Security Features](security.md) - Service security best practices