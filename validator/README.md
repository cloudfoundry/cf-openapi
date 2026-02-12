# Cloud Foundry OpenAPI Unit test Validator

Validates the http calls to Cloud Controller API based on data captured from running CAPI request tests.

## Installation

1. Install dependencies:
   ```bash
   go mod download
   ```

## Usage

To capture the json file. Do the following:
1. Pull https://github.com/cloudfoundry/cloud_controller_ng/tree/open_api_request_capturer
2. Run the tests with capture enabled CAPTURE_REQUESTS=true bundle exec rspec 'spec/request'  
3. `out/request_capture.json` is the input to this program.


### Running the validator

Run the validator with command-line arguments:

```bash
go run main.go <requests.json> <openapi.yaml>
```

Example:
```bash
go run main.go example_request_capture.json ../dist/latest/openapi.yaml
```

### Building and Running

You can also build the program into an executable:

```bash
go build -o validator main.go
./validator cf_requests.json openapi.yaml
```

The program will:
1. Load the OpenAPI specification from the specified YAML file
2. Read HTTP request/response data from the specified JSON file
3. Validate each request and response against the OpenAPI schema
4. Display validation results with detailed logging
5. Show a summary of validation results

### Command Line Arguments

- `<requests.json>` - Path to the JSON file containing HTTP request/response data
- `<openapi.yaml>` - Path to the OpenAPI specification file (YAML format)

## Input File Format

The `cf_requests.json` file should contain an array of objects with this structure:

```json
[
  {
    "timestamp": "2025-08-22T15:39:32-06:00",
    "request": {
      "method": "GET",
      "path": "/v3/buildpacks",
      "headers": {
        "Authorization": "bearer ...",
        "Content-Type": "application/json"
      },
      "body": null
    },
    "response": {
      "status": 200,
      "headers": {
        "Content-Type": "application/json; charset=utf-8",
        "X-VCAP-Request-ID": "..."
      },
      "body": {
        "pagination": {...},
        "resources": [...]
      }
    }
  }
]
```

## Output

The program outputs:
- Detailed logs for each request validation
- Individual validation results (pass/fail)
- Final summary with total counts of valid and invalid requests

Example output:
```bash
$ go run main.go cf_requests.json openapi.yaml
2025/08/22 15:44:30 Loaded 47 requests for validation
2025/08/22 15:44:30 Validating request 1: GET /v3/buildpacks
2025/08/22 15:44:30 Request 1 validation passed
2025/08/22 15:44:30 Response 1 validation passed
...
2025/08/22 15:44:30 Validation Summary:
2025/08/22 15:44:30 Total requests: 47
2025/08/22 15:44:30 Valid requests: 47
2025/08/22 15:44:30 Invalid requests: 0
```

### Error Handling

If you run the program without the correct arguments, you'll see:
```bash
$ go run main.go
Usage: main <requests.json> <openapi.yaml>
Example: main cf_requests.json openapi.yaml
```

## Dependencies

- [github.com/pb33f/libopenapi](https://github.com/pb33f/libopenapi) - OpenAPI document parsing
- [github.com/pb33f/libopenapi-validator](https://github.com/pb33f/libopenapi-validator) - OpenAPI validation

## License

This project is provided as-is for demonstration purposes.
