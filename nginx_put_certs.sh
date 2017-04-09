#!/bin/sh

if [ -z $ENDPOINT_URL ]; then
    echo "NO ENDPOINT_URL SET, ABORTING CERTS PUT"
    exit 1
fi

if [ -z $GOOGLE_CLOUD_STORAGE_BUCKET ]; then
    echo "NO GOOGLE_CLOUD_STORAGE_BUCKET SET, ABORTING CERTS FETCH"
    exit 1
fi

gsutil cp -r /etc/letsencrypt/. gs://$GOOGLE_CLOUD_STORAGE_BUCKET/ssl-certs/$ENDPOINT_URL/letsencrypt
