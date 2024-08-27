#!/bin/bash
# This script reads a list of endpoints from a file and creates or updates GitHub issues for each endpoint.

# GitHub repository details
GITHUB_OWNER="FloThinksPi"
GITHUB_REPO="cf-api-openapi-poc"

# The file containing the list of endpoints
ENDPOINTS_FILE="../ai/endpoints.txt"

# Maximum number of retries for failed requests
MAX_RETRIES=20

# Function to check if a GitHub issue with the same title already exists
find_existing_issue() {
  local title="$1"
  gh issue list --repo "$GITHUB_OWNER/$GITHUB_REPO" --search "$title in:title" --json number,title | jq -r --arg TITLE "$title" '.[] | select(.title==$TITLE) | .number'
}

create_label() {
  local label="$1"
  gh label create "$label" --repo "$GITHUB_OWNER/$GITHUB_REPO" --color "f29513" --description "Auto-created label"
}

label_exists() {
  local label="$1"
  gh label list --repo "$GITHUB_OWNER/$GITHUB_REPO" --json name --jq '.[].name' | grep -Fxq "$label"
}

# Function to create or update a GitHub issue
create_or_update_github_issue() {
  local title="$1"
  local description="$2"
  local labels="$3"
  local retries=0
  local existing_issue

  # Ensure labels exist
  IFS=',' read -ra ADDR <<< "$labels"
  for label in "${ADDR[@]}"; do
    cleaned_label="${label//\"/}"
    if ! label_exists "$cleaned_label"; then
      echo "Label '$cleaned_label' does not exist. Creating it..."
      create_label "$cleaned_label"
    fi
  done


  while [ $retries -lt $MAX_RETRIES ]; do
    # Check if the issue already exists
    existing_issue=$(find_existing_issue "$title")

    if [ -n "$existing_issue" ]; then
      # Update the existing issue
      echo "Updating existing issue: $title (Issue #$existing_issue)"
      gh issue edit "$existing_issue" --repo "$GITHUB_OWNER/$GITHUB_REPO" --body "$description" && \
      IFS=',' read -ra ADDR <<< "$labels"; for label in "${ADDR[@]}"; do gh issue edit "$existing_issue" --repo "$GITHUB_OWNER/$GITHUB_REPO" --add-label "${label//\"/}"; done && return
    else
      # Create a new issue
      echo "Creating new issue: $title"
      gh issue create --repo "$GITHUB_OWNER/$GITHUB_REPO" --title "$title" --body "$description" --label "$labels" && return
    fi

    retries=$((retries + 1))
    echo "Retry $retries/$MAX_RETRIES failed. Waiting before retrying..."
    sleep $((retries * retries)) # Exponential backoff
    done

  echo "Failed to create/update issue: $title after $MAX_RETRIES attempts."
}

# Read the endpoints file and create/update issues
while IFS= read -r endpoint; do
  method=$(echo "$endpoint" | cut -d' ' -f1)
  echo $method
  group=$(echo "$endpoint" | cut -d' ' -f2 | cut -d'/' -f3 | sed 's/.*/\u&/')
  echo $group
  # Issue title and description for Request Parameters and Request Body Issues of the endpoint
  TITLE="[Request Parameters/Body]: $endpoint"
  DESCRIPTION="""
  # Summary
  Check and Correct the Query Parameters/Request Body of \`$endpoint\`.
  """
  LABELS="\"Endpoint\",\"Group: ${group}\",\"Method: $method\",\"Category: Request Parameters/Body\""
  # Issue title and description for Response Body Issues of the endpoint
#  TITLE="[Response Body/Headers]: $endpoint"
#  DESCRIPTION="""
#  # Summary
#  Check and Correct the Query Parameters/Request Body of \`$endpoint\`.
#  """
#  LABELS="\"Endpoint\",\"Group: ${group}\",\"Method: $method\",\"Category: Request Parameters/Body\""
  # Issue title and description for Error Responses of the endpoint
#  TITLE="[Response Body/Headers]: $endpoint"
#  DESCRIPTION="""
#  # Summary
#  Check and Correct the Query Parameters/Request Body of \`$endpoint\`.
#  """
#  LABELS="\"Endpoint\",\"Group: ${group}\",\"Method: $method\",\"Category: Request Parameters/Body\""
  # Issue title and description for Authentication and Roles documentation of the endpoint

  create_or_update_github_issue "$TITLE" "$DESCRIPTION" "$LABELS"
done < "$ENDPOINTS_FILE"

echo "GitHub issues have been created/updated."