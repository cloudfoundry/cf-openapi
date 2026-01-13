#!/bin/bash
set -e

# Configuration
VALIDATION_OUTPUT_FILE="validator/validation_output.txt"

# Function to get error count from validation output
get_error_count() {
    local pattern="$1"
    if [ -f "$VALIDATION_OUTPUT_FILE" ]; then
        grep -c "$pattern" "$VALIDATION_OUTPUT_FILE" 2>/dev/null || echo "0"
    else
        echo "0"
    fi
}

# Function to extract value from validation summary
extract_summary_value() {
    local field="$1"
    if [ -f "$VALIDATION_OUTPUT_FILE" ]; then
        grep "$field:" "$VALIDATION_OUTPUT_FILE" | sed 's/.*'"$field"': \([0-9]*\).*/\1/' | head -1 || echo ""
    else
        echo ""
    fi
}

# Check if validation output exists
if [ ! -f "$VALIDATION_OUTPUT_FILE" ]; then
    echo "Validation output file not found: $VALIDATION_OUTPUT_FILE"
    echo "Run validation first with: ./scripts/validate-local.sh"
    exit 1
fi

echo "## OpenAPI Request Spec Validation Report"
echo ""
echo ""

# Extract summary statistics
TOTAL_REQUESTS=$(extract_summary_value "Total requests")
VALID_REQUESTS=$(extract_summary_value "Valid requests")
INVALID_REQUESTS=$(extract_summary_value "Invalid requests")

if [ -n "$TOTAL_REQUESTS" ] && [ "$TOTAL_REQUESTS" != "" ]; then
    echo "### Summary Statistics"
    echo "- **Total Requests:** $TOTAL_REQUESTS"
    echo "- **Valid Requests:** $VALID_REQUESTS"
    echo "- **Invalid Requests:** $INVALID_REQUESTS"
    
    if [ "$TOTAL_REQUESTS" -gt 0 ]; then
        SUCCESS_RATE=$(( VALID_REQUESTS * 100 / TOTAL_REQUESTS ))
        echo "- **Success Rate:** ${SUCCESS_RATE}%"
    fi
else
    echo "**No validation summary found**"
fi

echo ""

# Error category analysis
echo "### Error Categories"

MISSING_RESPONSES=$(get_error_count "response code.*does not exist")
MISSING_PATHS=$(get_error_count "Path.*not found")
REQUEST_BODY_ERRORS=$(get_error_count "request body.*failed to validate")
RESPONSE_BODY_ERRORS=$(get_error_count "response body.*failed to validate")
QUERY_PARAM_ERRORS=$(get_error_count "Query.*parameter.*does not match")
CONTENT_TYPE_ERRORS=$(get_error_count "content type.*does not exist")
PATH_PARAM_ERRORS=$(get_error_count "Path parameter.*does not match\|Path parameter.*is missing")

echo "- **Missing Response Codes:** $MISSING_RESPONSES"
echo "- **Missing Paths:** $MISSING_PATHS"
echo "- **Request Body Validation Errors:** $REQUEST_BODY_ERRORS"
echo "- **Response Body Validation Errors:** $RESPONSE_BODY_ERRORS"
echo "- **Query Parameter Errors:** $QUERY_PARAM_ERRORS"
echo "- **Path Parameter Errors:** $PATH_PARAM_ERRORS"
echo "- **Content Type Errors:** $CONTENT_TYPE_ERRORS"

# Calculate total categorized errors
TOTAL_CATEGORIZED=$((MISSING_RESPONSES + MISSING_PATHS + REQUEST_BODY_ERRORS + RESPONSE_BODY_ERRORS + QUERY_PARAM_ERRORS + PATH_PARAM_ERRORS + CONTENT_TYPE_ERRORS))

# Top error patterns
echo ""
echo "### Top Error Patterns"

if [ -f "$VALIDATION_OUTPUT_FILE" ]; then
    echo ""
    echo "**Most common error messages:**"
    echo '```'
    grep -o "Reason: [^,]*" "$VALIDATION_OUTPUT_FILE" | sort | uniq -c | sort -nr | head -10
    echo '```'
    
    echo ""
    echo "**Most problematic endpoints:**"
    echo '```'
    grep -o "url [^?]*" "$VALIDATION_OUTPUT_FILE" | sort | uniq -c | sort -nr | head -10
    echo '```'
fi