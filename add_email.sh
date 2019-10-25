#!/bin/bash

#########################################################
#
# uncomment to output shell commands for debugging
#set -x
#
#########################################################

#########################################################
#
# Source all of the shared variables and generate the access token, etc.  ONLY EDIT the include.sh to change any variables
#
#########################################################

source include.sh

read -p "Patient ID to add an email to: " PATIENT_ID
read -p "Email Address: " EMAIL_ADDRESS

curl -X PATCH \
  -H 'Authorization: Bearer '$OAUTH_TOKEN \
  -H 'Content-Type: application/json-patch+json' \
  --data "[
    {
      \"op\": \"add\",
      \"path\": \"/telecom/0\",
      \"value\": {\"system\": \"email\", \"use\": \"mobile\", \"value\": \"$EMAIL_ADDRESS\"}
    }
  ]" \
  "https://healthcare.googleapis.com/v1beta1/projects/{$PROJECT}/locations/{$LOCATION}/datasets/{$DATASET}/fhirStores/{$FHIRSTORE}/fhir/Patient/$PATIENT_ID"
