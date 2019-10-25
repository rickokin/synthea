#!/bin/bash
#########################################################
#
# This script deletes and creates a new FHIR datastore
# Generates Synthea data
# Pre-processes the synthea data for Import to the FHIR Store
# Copies the hospital (organization) and practitioner synthea files to the GCS bucket
# Runs the API FHIR Import command
# THIS SCRIPT MUST BE RUN FIRST BEFORE THE patient_load.sh since it depends on having the organizations and practitioners
# imported first - outstanding question for Google as to why the referential integrtity integrity setting does not seem 
# address this
#
#########################################################

#########################################################
#
# Source all of the shared variables and generate the access token, etc.  ONLY EDIT the include.sh to change any variables
#
#########################################################

source include.sh

read -p "Press [Enter] key to delete and re-create the FHIR STORE: $FHIRSTORE and DATASET: $DATASET in LOCATION: $LOCATION PROJECT: $PROJECT"

#########################################################
#
# Delete the dataset, which also deletes the FHIR store
#
#########################################################
curl -X DELETE \
  'https://healthcare.googleapis.com/v1beta1/projects/'$PROJECT'/locations/'$LOCATION'/datasets/'$DATASET \
  -H 'Authorization: Bearer '$OAUTH_TOKEN  \
  -H 'cache-control: no-cache'

#########################################################
#
# Create the dataset
#
#########################################################

curl -X POST \
  'https://healthcare.googleapis.com/v1beta1/projects/'$PROJECT'/locations/'$LOCATION'/datasets?datasetId='$DATASET \
  -H 'Authorization: Bearer '$OAUTH_TOKEN \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -H 'cache-control: no-cache'

#########################################################
#
# Create the FHIR store
#
#########################################################

curl -X POST \
  "https://healthcare.googleapis.com/v1beta1/projects/${PROJECT}/locations/${LOCATION}/datasets/${DATASET}/fhirStores?fhirStoreId=${FHIRSTORE}" \
  -H 'Authorization: Bearer '$OAUTH_TOKEN \
  -H 'Content-Type: application/json;charset=UTF-8' \
  -H 'cache-control: no-cache' \
  -d '{ "name": "'"$FHIRSTORE"'", "enableUpdateCreate": true, "disableReferentialIntegrity": true, "disableResourceVersioning": false }'

read -p "PRESS ENTER TO START"

#########################################################
#
# GENERATE SYNTHEA DATA
# Remove previously generated files (if any)
#
#########################################################

rm $FILEDIR/fhir_stu3/*.json

#########################################################
#
# run synthea command to generate files
#
#########################################################

cd $SYNTHEA_HOME
$SYNTHEA_HOME/run_synthea -s 999 -p 10

#########################################################
#
# REMOVE PREPROCESSED FILES
#
#########################################################

rm $FILE_OUTPUT/*.json

#########################################################
#
# PRE-PROCESS THE SYNTHEA FILES to remove newlines
#
#########################################################

for i in `ls $FILEDIR/fhir_stu3`
do
cat $FILEDIR/fhir_stu3/$i | tr -d '\n' > $FILE_OUTPUT/$i
done

#########################################################
#
# empty the bucket
# copy the hospital and practitioner files to GCS 
#
#########################################################

gsutil -m rm $INGESTION_GCS_BUCKET/**
gsutil -m cp $FILE_OUTPUT/hospitalInformation*.json $INGESTION_GCS_BUCKET
gsutil -m cp $FILE_OUTPUT/practitionerInformation*.json $INGESTION_GCS_BUCKET
gsutil ls gs://liahcare-demo-bucket

#########################################################
#
# RUN THE IMPORT COMMAND
#
#########################################################

curl -X POST \
  "https://healthcare.googleapis.com/v1beta1/projects/{$PROJECT}/locations/{$LOCATION}/datasets/{$DATASET}/fhirStores/{$FHIRSTORE}:import" \
  -H 'Authorization: Bearer '$OAUTH_TOKEN \
  -H 'Content-Type: application/json' \
  -H 'cache-control: no-cache' \
  -d '{ "gcsSource": { "uri": "'$INGESTION_GCS_BUCKET'/*" } }'

