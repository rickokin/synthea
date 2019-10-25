#!/bin/bash
############################################
#
# This script continues after the hsop_prac_load.sh which deletes the datastores and recreates them, pre-processes 
# the json files to remove newlines, copies the hospital and practitioner files to GCS and then 
# Imports them into the FHIR datastore
# 
# This script simply copies the preprocessed patient files to GCS and the imports them into the FHIRStore
#
############################################


############################################
#
# Read in shared variables
#
############################################

source include.sh


read -p "PRESS ENTER TO START"

############################################
#
# CLEAR OUT BUCKET AT GCS
#
############################################

gsutil -m rm $INGESTION_GCS_BUCKET/**

############################################
# 
# COPY FILES TO GCS BUCKET FOR IMPORT
#
############################################

for i in `ls $FILE_OUTPUT/ |grep -v hospitalInformation* |grep -v practitionerInformation*`
do
echo $i
gsutil -m cp $FILE_OUTPUT/$i $INGESTION_GCS_BUCKET
done

############################################
#
# IMPORT PATIENT RECORDS INTO FHIR DATASTORE
#
############################################

curl -X POST \
  "https://healthcare.googleapis.com/v1beta1/projects/{$PROJECT}/locations/{$LOCATION}/datasets/{$DATASET}/fhirStores/{$FHIRSTORE}:import" \
  -H 'Authorization: Bearer '$OAUTH_TOKEN \
  -H 'Content-Type: application/json' \
  -H 'cache-control: no-cache' \
  -d '{ "gcsSource": { "uri": "'$INGESTION_GCS_BUCKET'/*" } }'


