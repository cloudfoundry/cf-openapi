# CAPI OpenAPI Testing Guide

## Overview

This guide covers:
1. How to generate the OpenAPI spec and view test reports
2. How to perform end-to-end testing of generated Go SDK against live CF API

## SDK Integration Testing

The project includes comprehensive integration testing for generated SDKs with automatic cleanup.

### Running Integration Tests

```bash
# Run integration tests for all supported languages
./bin/integration-test

# Test specific languages
./bin/integration-test --languages=go,python

# Keep generated SDKs after testing (for debugging)
./bin/integration-test --no-cleanup

# Clean up test-generated SDKs manually
make clean-test
```

### Integration Test Features

- **Automatic cleanup**: Generated SDKs are removed after testing by default
- **Multiple language support**: Tests Go, Python, Java, TypeScript, Ruby SDKs
- **Compilation testing**: Verifies generated code compiles correctly
- **Basic functionality tests**: Creates test programs to verify SDK works
- **Live API testing**: Optional testing against real CF API endpoints

### Test Output Directory

Generated test SDKs are placed in `test/sdk-integration/` and are:
- Automatically cleaned up after tests complete
- Ignored by git (via .gitignore)
- Removable with `make clean` or `make clean-test`

## Part A: Generate and Test OpenAPI Spec

### 1. Generate the OpenAPI Specification

```bash
# Generate spec in JSON format (recommended)
./bin/gen spec --version=3.195.0 --format=json

# Fix type issues
./bin/fix-spec-types --input=capi/3.195.0/openapi.json
```

### 2. Run Validation Tests

```bash
# Validate the OpenAPI spec structure
./bin/validate-spec --version=3.195.0

# Validate examples in the spec
./bin/validate-examples capi/3.195.0/openapi.json

# Run comprehensive tests
./bin/test-schemas --version=3.195.0
```

### 3. View Test Reports

After generation and testing, check these reports in `capi/3.195.0/`:

- **generation-report.md** - HTML parsing statistics and issues
- **enhancement-report.md** - Enhancement statistics (descriptions, examples, etc.)
- **final-report.md** - Overall generation summary
- **example-validation-report.md** - Results of example validation
- **review-report.md** - Spec review findings

Example viewing:
```bash
# View all reports
ls -la capi/3.195.0/*.md

# View enhancement report
cat capi/3.195.0/enhancement-report.md

# View validation results
cat capi/3.195.0/example-validation-report.md
```

## Part B: End-to-End Testing of Go SDK

### 1. Generate the Go SDK

```bash
./bin/gen sdk --version=3.195.0 --language=go --generator=openapi-generator
```

### 2. Set Up CF Environment

First, ensure you have access to a Cloud Foundry environment:

```bash
# Login to your CF instance
cf login -a https://api.cf.example.com

# Get your API token
CF_TOKEN=$(cf oauth-token | grep bearer)
```

### 3. Create Test Program

Create `test/e2e-test.go`:

```go
package main

import (
    "context"
    "fmt"
    "os"
    "strings"
    
    capiclient "github.com/cloudfoundry-community/capi-openapi-go-client/capiclient"
)

func main() {
    // Get CF API endpoint and token
    cfAPI := os.Getenv("CF_API")
    cfToken := os.Getenv("CF_TOKEN")
    
    if cfAPI == "" || cfToken == "" {
        fmt.Println("Please set CF_API and CF_TOKEN environment variables")
        fmt.Println("Example: CF_API=https://api.cf.example.com CF_TOKEN='bearer ...'")
        os.Exit(1)
    }
    
    // Create configuration
    cfg := capiclient.NewConfiguration()
    cfg.Host = strings.TrimPrefix(cfAPI, "https://")
    cfg.Scheme = "https"
    cfg.AddDefaultHeader("Authorization", cfToken)
    
    // Create client
    client := capiclient.NewAPIClient(cfg)
    ctx := context.Background()
    
    // Test 1: Get API info
    fmt.Println("=== Test 1: Get API Info ===")
    info, resp, err := client.DefaultApi.GetApiInfo(ctx).Execute()
    if err != nil {
        fmt.Printf("Error getting API info: %v\n", err)
        if resp != nil {
            fmt.Printf("HTTP Status: %d\n", resp.StatusCode)
        }
    } else {
        fmt.Printf("API Version: %s\n", *info.ApiVersion)
        fmt.Printf("Links: %+v\n", info.Links)
    }
    
    // Test 2: List Organizations
    fmt.Println("\n=== Test 2: List Organizations ===")
    orgs, resp, err := client.OrganizationsApi.GetOrganizations(ctx).Execute()
    if err != nil {
        fmt.Printf("Error listing orgs: %v\n", err)
    } else {
        fmt.Printf("Found %d organizations\n", len(orgs.Resources))
        for i, org := range orgs.Resources {
            if i < 3 { // Show first 3
                fmt.Printf("  - %s (guid: %s)\n", *org.Name, *org.Guid)
            }
        }
    }
    
    // Test 3: List Spaces (if orgs exist)
    if len(orgs.Resources) > 0 {
        fmt.Println("\n=== Test 3: List Spaces ===")
        orgGuid := *orgs.Resources[0].Guid
        spaces, _, err := client.SpacesApi.GetSpaces(ctx).
            OrganizationGuids([]string{orgGuid}).
            Execute()
        if err != nil {
            fmt.Printf("Error listing spaces: %v\n", err)
        } else {
            fmt.Printf("Found %d spaces in org %s\n", len(spaces.Resources), orgGuid)
        }
    }
    
    // Test 4: List Apps
    fmt.Println("\n=== Test 4: List Apps ===")
    apps, _, err := client.AppsApi.GetApps(ctx).PerPage(5).Execute()
    if err != nil {
        fmt.Printf("Error listing apps: %v\n", err)
    } else {
        fmt.Printf("Found %d apps (showing max 5)\n", len(apps.Resources))
        for _, app := range apps.Resources {
            fmt.Printf("  - %s (state: %s)\n", *app.Name, *app.State)
        }
    }
    
    fmt.Println("\n=== All tests completed ===")
}
```

### 4. Run End-to-End Tests

```bash
# Set up environment
export CF_API=$(cf api | grep endpoint | awk '{print $3}')
export CF_TOKEN=$(cf oauth-token | grep bearer)

# Change to SDK directory
cd sdk/3.195.0/go/capiclient

# Initialize module (if needed)
go mod init github.com/cloudfoundry-community/capi-openapi-go-client/capiclient
go mod tidy

# Run the test
go run ../../../../test/e2e-test.go
```

### 5. Advanced Testing Script

Create `bin/test-cf-sdk`:

```bash
#!/usr/bin/env perl

use strict;
use warnings;
use v5.20;
use JSON::XS;
use File::Spec;
use File::Basename;
use Getopt::Long;

my $version = '3.195.0';
my $language = 'go';
my $cf_api;
my $cf_user;
my $cf_password;
my $help;

GetOptions(
    'version=s' => \$version,
    'language=s' => \$language,
    'api=s' => \$cf_api,
    'user=s' => \$cf_user,
    'password=s' => \$cf_password,
    'help' => \$help,
) or die "Error in command line arguments\n";

if ($help) {
    print <<EOF;
Usage: test-cf-sdk [options]

Test generated SDK against live CF API

Options:
  --version=VERSION   CAPI version (default: 3.195.0)
  --language=LANG     SDK language (default: go)
  --api=URL          CF API endpoint
  --user=USERNAME    CF username
  --password=PASS    CF password
  --help             Show this help

Examples:
  # Test with existing cf login
  test-cf-sdk

  # Test with credentials
  test-cf-sdk --api=https://api.cf.example.com --user=admin --password=secret

EOF
    exit 0;
}

# Get CF credentials
if (!$cf_api) {
    my $api_output = `cf api 2>&1`;
    if ($api_output =~ /endpoint:\s*(\S+)/) {
        $cf_api = $1;
    } else {
        die "Could not determine CF API endpoint. Please login with 'cf login' or provide --api\n";
    }
}

# Get auth token
my $token_output = `cf oauth-token 2>&1`;
my $cf_token;
if ($token_output =~ /(bearer\s+\S+)/i) {
    $cf_token = $1;
} else {
    die "Could not get CF token. Please login with 'cf login'\n";
}

say "Testing $language SDK v$version against $cf_api";

# Run language-specific tests
if ($language eq 'go') {
    test_go_sdk();
} elsif ($language eq 'python') {
    test_python_sdk();
} elsif ($language eq 'java') {
    test_java_sdk();
} else {
    die "Unsupported language: $language\n";
}

sub test_go_sdk {
    my $sdk_dir = "sdk/$version/go/capiclient";
    
    unless (-d $sdk_dir) {
        die "SDK not found at $sdk_dir. Please generate it first.\n";
    }
    
    # Create test file
    my $test_file = "$sdk_dir/e2e_test.go";
    
    open my $fh, '>', $test_file or die "Cannot create test file: $!";
    print $fh get_go_test_code();
    close $fh;
    
    # Run tests
    say "Running Go SDK tests...";
    $ENV{CF_API} = $cf_api;
    $ENV{CF_TOKEN} = $cf_token;
    
    system("cd $sdk_dir && go test -v");
    
    # Clean up
    unlink $test_file;
}

sub get_go_test_code {
    return <<'GO_CODE';
package capiclient

import (
    "context"
    "os"
    "strings"
    "testing"
)

func TestLiveCFAPI(t *testing.T) {
    cfAPI := os.Getenv("CF_API")
    cfToken := os.Getenv("CF_TOKEN")
    
    if cfAPI == "" || cfToken == "" {
        t.Skip("CF_API and CF_TOKEN not set")
    }
    
    cfg := NewConfiguration()
    cfg.Host = strings.TrimPrefix(cfAPI, "https://")
    cfg.Scheme = "https"
    cfg.AddDefaultHeader("Authorization", cfToken)
    
    client := NewAPIClient(cfg)
    ctx := context.Background()
    
    t.Run("GetAPIInfo", func(t *testing.T) {
        info, resp, err := client.DefaultApi.GetApiInfo(ctx).Execute()
        if err != nil {
            t.Fatalf("Failed to get API info: %v", err)
        }
        if resp.StatusCode != 200 {
            t.Fatalf("Expected 200, got %d", resp.StatusCode)
        }
        if info.ApiVersion == nil {
            t.Fatal("API version is nil")
        }
        t.Logf("API Version: %s", *info.ApiVersion)
    })
    
    t.Run("ListOrganizations", func(t *testing.T) {
        orgs, _, err := client.OrganizationsApi.GetOrganizations(ctx).Execute()
        if err != nil {
            t.Fatalf("Failed to list orgs: %v", err)
        }
        t.Logf("Found %d organizations", len(orgs.Resources))
    })
    
    t.Run("ListApps", func(t *testing.T) {
        apps, _, err := client.AppsApi.GetApps(ctx).PerPage(5).Execute()
        if err != nil {
            t.Fatalf("Failed to list apps: %v", err)
        }
        t.Logf("Found %d apps", len(apps.Resources))
    })
}
GO_CODE
}

sub test_python_sdk {
    say "Python SDK testing not yet implemented";
}

sub test_java_sdk {
    say "Java SDK testing not yet implemented";
}
```

Make it executable:
```bash
chmod +x bin/test-cf-sdk
```

### 6. Integration Test Suite

Create `bin/test-integration`:

```bash
#!/usr/bin/env perl

use strict;
use warnings;
use v5.20;

my $version = shift || '3.195.0';

say "Running full integration test suite for v$version";
say "=" x 60;

# 1. Generate spec
say "\n1. Generating OpenAPI spec...";
system("./bin/gen spec --version=$version --format=json") == 0
    or die "Spec generation failed";

# 2. Fix types
say "\n2. Fixing type issues...";
system("./bin/fix-spec-types --input=capi/$version/openapi.json") == 0
    or die "Type fixing failed";

# 3. Validate spec
say "\n3. Validating spec...";
system("./bin/validate-spec --version=$version");

# 4. Validate examples
say "\n4. Validating examples...";
system("./bin/validate-examples capi/$version/openapi.json");

# 5. Generate SDK
say "\n5. Generating Go SDK...";
system("./bin/gen sdk --version=$version --language=go --generator=openapi-generator") == 0
    or die "SDK generation failed";

# 6. Test SDK
say "\n6. Testing SDK against live API...";
system("./bin/test-cf-sdk --version=$version");

say "\n" . "=" x 60;
say "Integration test suite completed!";
say "\nReports available in capi/$version/:";
system("ls -la capi/$version/*.md");
```

Make it executable:
```bash
chmod +x bin/test-integration
```

## Quick Test Commands

```bash
# Full integration test
./bin/test-integration 3.195.0

# Just SDK testing
./bin/test-cf-sdk --version=3.195.0

# View all reports
ls -la capi/3.195.0/*.md
cat capi/3.195.0/final-report.md
```

## Troubleshooting

1. **Authentication errors**: Make sure you're logged into CF with `cf login`
2. **SSL errors**: Add `cfg.HTTPClient.Transport = &http.Transport{TLSClientConfig: &tls.Config{InsecureSkipVerify: true}}` for self-signed certs
3. **Rate limiting**: Add delays between API calls if needed
4. **Missing methods**: Check the generated `api_*.go` files for available methods