# Getting Started with Cloud Foundry CAPI v3

Welcome to the Cloud Foundry Cloud Controller API (CAPI) v3! This guide will help you get started with using the API to manage applications, services, and other Cloud Foundry resources.

## Prerequisites

Before you begin, ensure you have:

1. **Access to a Cloud Foundry deployment** - You'll need the API endpoint URL
2. **Valid credentials** - Either a username/password or a client ID/secret
3. **CF CLI installed** (optional but recommended) - For obtaining authentication tokens
4. **An HTTP client** - Such as curl, Postman, or a programming language with HTTP support

## API Endpoint

The Cloud Foundry API is typically available at:
```
https://api.<your-cf-domain>
```

You can verify the API endpoint and version by accessing the root endpoint:
```bash
curl https://api.example.com/
```

## Authentication

All API requests (except `/` and `/v3/info`) require authentication using a Bearer token.

### Obtaining a Token

#### Using CF CLI (Recommended)
```bash
# Login
cf login -a https://api.example.com

# Get your access token
cf oauth-token
```

The token will be in the format: `bearer <token>`. Use the entire string in your API requests.

#### Direct UAA Authentication
```bash
# Get token endpoint from API info
curl https://api.example.com/v3/info

# Exchange credentials for token
curl -X POST https://uaa.example.com/oauth/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=password&username=<user>&password=<pass>&client_id=cf&client_secret="
```

## Your First API Calls

### 1. Get API Information
```bash
curl https://api.example.com/v3/info \
  -H "Accept: application/json"
```

### 2. List Organizations
```bash
curl https://api.example.com/v3/organizations \
  -H "Authorization: bearer <your-token>" \
  -H "Accept: application/json"
```

### 3. List Applications
```bash
curl https://api.example.com/v3/apps \
  -H "Authorization: bearer <your-token>" \
  -H "Accept: application/json"
```

## Common Operations

### Creating an Application

```bash
curl -X POST https://api.example.com/v3/apps \
  -H "Authorization: bearer <your-token>" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "my-app",
    "relationships": {
      "space": {
        "data": {
          "guid": "<space-guid>"
        }
      }
    }
  }'
```

### Uploading Application Code

1. **Create a package**:
```bash
curl -X POST https://api.example.com/v3/packages \
  -H "Authorization: bearer <your-token>" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "bits",
    "relationships": {
      "app": {
        "data": {
          "guid": "<app-guid>"
        }
      }
    }
  }'
```

2. **Upload bits to the package**:
```bash
curl -X POST https://api.example.com/v3/packages/<package-guid>/upload \
  -H "Authorization: bearer <your-token>" \
  -F bits=@app.zip
```

3. **Create a build**:
```bash
curl -X POST https://api.example.com/v3/builds \
  -H "Authorization: bearer <your-token>" \
  -H "Content-Type: application/json" \
  -d '{
    "package": {
      "guid": "<package-guid>"
    }
  }'
```

### Starting an Application

```bash
curl -X POST https://api.example.com/v3/apps/<app-guid>/actions/start \
  -H "Authorization: bearer <your-token>"
```

## Understanding Responses

### Successful Response
```json
{
  "guid": "585bc3a1-3743-497d-88b0-403ad6b56d16",
  "name": "my-app",
  "state": "STARTED",
  "created_at": "2025-01-26T19:24:43Z",
  "updated_at": "2025-01-26T19:25:01Z",
  "lifecycle": {
    "type": "buildpack",
    "data": {
      "buildpacks": [],
      "stack": "cflinuxfs3"
    }
  },
  "relationships": {
    "space": {
      "data": {
        "guid": "2f35885d-0c9d-4423-83ad-fd05066f8576"
      }
    }
  },
  "metadata": {
    "labels": {},
    "annotations": {}
  },
  "links": {
    "self": {
      "href": "https://api.example.com/v3/apps/585bc3a1-3743-497d-88b0-403ad6b56d16"
    },
    "processes": {
      "href": "https://api.example.com/v3/apps/585bc3a1-3743-497d-88b0-403ad6b56d16/processes"
    }
  }
}
```

### Error Response
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

## Pagination

List endpoints return paginated results:

```json
{
  "pagination": {
    "total_results": 42,
    "total_pages": 5,
    "first": {
      "href": "https://api.example.com/v3/apps?page=1&per_page=10"
    },
    "last": {
      "href": "https://api.example.com/v3/apps?page=5&per_page=10"
    },
    "next": {
      "href": "https://api.example.com/v3/apps?page=2&per_page=10"
    }
  },
  "resources": [
    { 
      "guid": "...",
      "name": "app1"
    }
  ]
}
```

Navigate through pages using the `page` query parameter:
```bash
curl "https://api.example.com/v3/apps?page=2&per_page=50" \
  -H "Authorization: bearer <your-token>"
```

## Filtering Results

Use query parameters to filter results:

```bash
# Filter by name
curl "https://api.example.com/v3/apps?names=my-app,other-app" \
  -H "Authorization: bearer <your-token>"

# Filter by space
curl "https://api.example.com/v3/apps?space_guids=<space-guid>" \
  -H "Authorization: bearer <your-token>"

# Filter by label
curl "https://api.example.com/v3/apps?label_selector=env=production" \
  -H "Authorization: bearer <your-token>"
```

## Asynchronous Operations

Some operations return a job for tracking:

```bash
# Delete an app (returns a job)
curl -X DELETE https://api.example.com/v3/apps/<app-guid> \
  -H "Authorization: bearer <your-token>"

# Response includes job URL
{
  "links": {
    "job": {
      "href": "https://api.example.com/v3/jobs/87250c2e-7c04-4b2d-b8f7-b8a1791bb106"
    }
  }
}

# Poll the job
curl https://api.example.com/v3/jobs/87250c2e-7c04-4b2d-b8f7-b8a1791bb106 \
  -H "Authorization: bearer <your-token>"
```

## Using Metadata

Add labels and annotations to organize resources:

```bash
curl -X PATCH https://api.example.com/v3/apps/<app-guid> \
  -H "Authorization: bearer <your-token>" \
  -H "Content-Type: application/json" \
  -d '{
    "metadata": {
      "labels": {
        "env": "production",
        "team": "backend"
      },
      "annotations": {
        "contact": "backend-team@example.com"
      }
    }
  }'
```

## Next Steps

- Explore the [API Overview](api-overview.md) for detailed information about API conventions
- Review the [Core Resources Guide](core-resources.md) for in-depth resource documentation
- Check out the [Client SDK Guide](client-sdks.md) for generating language-specific clients
- See [Authentication & Authorization](authentication.md) for advanced auth scenarios

## Useful Tools

- **CF CLI**: Official command-line tool - https://github.com/cloudfoundry/cli
- **Postman Collection**: Import our OpenAPI spec into Postman for easy testing
- **HTTPie**: User-friendly command-line HTTP client - https://httpie.io/

## Getting Help

- Check the [Troubleshooting Guide](troubleshooting.md) for common issues
- Visit the [Cloud Foundry Slack](https://cloudfoundry.slack.com) community
- Review the official [CAPI Documentation](https://v3-apidocs.cloudfoundry.org/)