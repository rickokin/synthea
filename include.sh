#!/bin/bash

############################################
#
# NOTE: This shell script must be in the directory in which you run the other scripts for
# generating hospital (organization), practitioner and patient data in the FHIR datastore
#
############################################

PREFIX=liahcare

############################################
#
# Setup required for running this script:
# Set the project, location, dataset name and FHIR store name below.  The project must already exist, and 
# the location should be one already supporting healthcloud
#
############################################


PROJECT=healthtest
LOCATION=us-central1
DATASET=$PREFIX-dataset
FHIRSTORE=$PREFIX-fhirstore

############################################
#
# -- Create a service account key with the appropriate roles, and log in to that account using the key file.
#    Set the service account email in the environment variable below.  
#    This script uses "gcloud config set account" to switch to this account,
#    so you should use "gcloud auth activate-service-account" to activate this account PRIOR to running this script.
#
#    Required roles for this service account:
#    -- Healthcare Dataset Administrator (to create datasets)
#    -- Healthcare FHIR Administrator (to create FHIR stores)
#    -- Healthcare FHIR Resource Editor (to create FHIR resources)
#    -- Healthcare FHIR Resource Reader (to read FHIR resources)
#    -- Healthcare FHIR Store Viewer (to view existing FHIR stores)
#    -- Pub/Sub Admin (to publish and subscribe to Pub/Sub topics and subscriptions)
#    -- Storage Admin (to create and read GCS buckets)
#    -- Storage Object Admin (to create and read GCS bucket objects)
#    -- Service Account User (to enable the Cloud Functions routine to use this account to send requests to CHC API)
#    -- Cloud Functions Developer (to allow this script to deploy and delete Cloud Functions instances)
#
############################################

SERVICE_ACCOUNT_EMAIL=addyour service account

############################################
#
#  Create a Pub/Sub topic, and set the name in the environment variable below.  
#  When data is loaded into the FHIR store, messages will be sent to this topic; 
#  these can be picked up by a listener if desired.
#
# NOT CURRENTLY BEING USED
#
############################################

PUBSUB_TOPIC_NAME=$FHIRSTORE-topic

############################################
#
#  Create a Pub/Sub scription for the topic above.  
#  This will be used by a command-line tool to read messages produced by Cloud Healthcare
#  API as data is ingested into the FHIR store.
#
# NOT CURRENTLY BEING USED
#
############################################

PUBSUB_SUBSCRIPTION_NAME=$FHIRSTORE-subscription

############################################
#
# Create a GCS bucket and set the name in the environment variable below.  
# This bucket will have a Cloud Functions 'finalize' trigger activated so that uploaded files 
# will automatically be loaded into the FHIR store you specified.
#
############################################

INGESTION_GCS_BUCKET=gs://$PREFIX-demo-bucket

############################################
#
# Generate the OAUTH TOKEN for use in the CURL (API) calls
#
############################################

OAUTH_TOKEN=$(gcloud auth print-access-token)

############################################
#
# Directory where synthea will generate files (fhir, fhir3, etc)
# SYNTHEA_HOME - home directory where synthea is installed
# FILEDIR - directory where synthea outputs the json files that get upload and imported
# Should match what is in the synthea.properties file which is located in src/main/resources/
#
############################################

SYNTHEA_HOME=$HOME/gitrepos/synthea
FILEDIR=$HOME/gitrepos/synthea/output

############################################
#
# Directory where modified files will be output for upload to GCS bucket
#
############################################

FILE_OUTPUT=$HOME/GCP/FHIR_LOAD/GCS_UPLOAD

############################################
#
# gcloud commands to set account and project
# 
############################################

gcloud config set account $SERVICE_ACCOUNT_EMAIL
gcloud config set project $PROJECT
