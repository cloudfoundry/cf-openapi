package main

import (
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"net/url"
	"os"
	"strings"

	"github.com/pb33f/libopenapi"
	validator "github.com/pb33f/libopenapi-validator"
)

// Request represents the structure of a request in the JSON file
type Request struct {
	Method  string            `json:"method"`
	Path    string            `json:"path"`
	Headers map[string]string `json:"headers"`
	Body    interface{}       `json:"body"`
}

// Response represents the structure of a response in the JSON file
type Response struct {
	Status  int               `json:"status"`
	Headers map[string]string `json:"headers"`
	Body    interface{}       `json:"body"`
}

// RequestResponse represents the structure of each entry in the JSON file
type RequestResponse struct {
	Timestamp string   `json:"timestamp"`
	Request   Request  `json:"request"`
	Response  Response `json:"response"`
}

func main() {
	// Check command line arguments
	if len(os.Args) != 3 {
		fmt.Fprintf(os.Stderr, "Usage: %s <requests.json> <openapi.yaml>\n", os.Args[0])
		fmt.Fprintf(os.Stderr, "Example: %s cf_requests.json openapi.yaml\n", os.Args[0])
		os.Exit(1)
	}

	requestsFile := os.Args[1]
	openapiFile := os.Args[2]

	// Read the OpenAPI specification
	spec, err := os.ReadFile(openapiFile)
	if err != nil {
		log.Fatalf("Failed to read OpenAPI spec from '%s': %v", openapiFile, err)
	}

	// Parse the OpenAPI document
	document, err := libopenapi.NewDocument(spec)
	if err != nil {
		log.Fatalf("Failed to parse OpenAPI document: %v", err)
	}

	// Create the validator
	v, errs := validator.NewValidator(document)
	if len(errs) > 0 {
		log.Printf("Validator creation warnings: %d", len(errs))
		for _, e := range errs {
			log.Printf("Warning: %s", e.Error())
		}
	}

	// Read the requests JSON file
	requestsData, err := os.ReadFile(requestsFile)
	if err != nil {
		log.Fatalf("Failed to read requests file '%s': %v", requestsFile, err)
	}

	// Parse the JSON data
	var requests []RequestResponse
	if err := json.Unmarshal(requestsData, &requests); err != nil {
		log.Fatalf("Failed to parse requests JSON: %v", err)
	}

	log.Printf("Loaded %d requests for validation", len(requests))

	var validCount, invalidCount int

	// Validate each request and response
	for i, reqResp := range requests {
		isValid := true
		// log.Printf("Validating request %d: %s %s", i+1, reqResp.Request.Method, reqResp.Request.Path)

		// Create HTTP request
		httpReq, err := createHTTPRequest(reqResp.Request)
		if err != nil {
			log.Printf("Error creating HTTP request %d: %v", i+1, err)
			continue
		}

		// Validate the request
		_, reqErrors := v.ValidateHttpRequest(httpReq)
		if len(reqErrors) > 0 {
			isValid = false
			log.Printf("Request %d validation failed:", i+1)
			for _, e := range reqErrors {
				log.Printf("  - %s", e.Error())
			}
		}

		// Create HTTP response for validation
		httpResp, err := createHTTPResponse(reqResp.Response, httpReq)
		if err != nil {
			log.Printf("Error creating HTTP response %d: %v", i+1, err)
			continue
		}

		// Validate the response
		_, respErrors := v.ValidateHttpResponse(httpReq, httpResp)
		if len(respErrors) > 0 {
			isValid = false
			log.Printf("Response %d validation failed:", i+1)
			for _, e := range respErrors {
				log.Printf("  - %s", e.Error())
			}
		}
		if isValid {
			validCount++
		} else {
			invalidCount++
		}
	}

	log.Printf("\nValidation Summary:")
	log.Printf("Total requests: %d", len(requests))
	log.Printf("Valid requests: %d", validCount)
	log.Printf("Invalid requests: %d", invalidCount)
}

// createHTTPRequest creates an http.Request from our Request struct
func createHTTPRequest(req Request) (*http.Request, error) {
	// Parse the URL path and query parameters
	parsedURL, err := url.Parse(req.Path)
	if err != nil {
		return nil, fmt.Errorf("invalid path: %w", err)
	}

	var body io.Reader
	if req.Body != nil {
		bodyBytes, err := json.Marshal(req.Body)
		if err != nil {
			return nil, fmt.Errorf("failed to marshal request body: %w", err)
		}
		body = strings.NewReader(string(bodyBytes))
	}

	// Create the HTTP request
	httpReq, err := http.NewRequest(req.Method, parsedURL.String(), body)
	if err != nil {
		return nil, fmt.Errorf("failed to create HTTP request: %w", err)
	}

	// Set headers
	for key, value := range req.Headers {
		httpReq.Header.Set(key, value)
	}

	return httpReq, nil
}

// createHTTPResponse creates an http.Response from our Response struct
func createHTTPResponse(resp Response, req *http.Request) (*http.Response, error) {
	var body io.ReadCloser
	if resp.Body != nil {
		bodyBytes, err := json.Marshal(resp.Body)
		if err != nil {
			return nil, fmt.Errorf("failed to marshal response body: %w", err)
		}
		body = io.NopCloser(strings.NewReader(string(bodyBytes)))
	}

	httpResp := &http.Response{
		Status:     fmt.Sprintf("%d %s", resp.Status, http.StatusText(resp.Status)),
		StatusCode: resp.Status,
		Header:     make(http.Header),
		Body:       body,
		Request:    req,
	}

	// Set headers
	for key, value := range resp.Headers {
		httpResp.Header.Set(key, value)
	}

	return httpResp, nil
}
