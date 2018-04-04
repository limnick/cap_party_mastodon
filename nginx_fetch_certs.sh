#!/bin/sh

if [ -z $ENDPOINT_URL ]; then
    echo "NO ENDPOINT_URL SET, ABORTING CERTS FETCH"
    exit 1
fi

if [ -z $GOOGLE_CLOUD_STORAGE_BUCKET ]; then
    echo "NO GOOGLE_CLOUD_STORAGE_BUCKET SET, ABORTING CERTS FETCH"
    exit 1
fi

gsutil -m cp -r gs://$GOOGLE_CLOUD_STORAGE_BUCKET/ssl-certs/$ENDPOINT_URL/letsencrypt/* /etc/letsencrypt


# get highest number cert available (i.e. cert10.pem over cert9.pem )
LATEST_CERT_VERSION=$(cd /etc/letsencrypt/archive/${ENDPOINT_URL}/ && ls cert*.pem | grep -o '[0-9]\+' | sort -n | tail -1)

# clean existing live certs
rm /etc/letsencrypt/live/${ENDPOINT_URL}/*.pem

# symlink in latest live certs instead of having a copy of the file, fixes renewal issues
ln -s /etc/letsencrypt/archive/${ENDPOINT_URL}/cert${LATEST_CERT_VERSION}.pem /etc/letsencrypt/live/${ENDPOINT_URL}/cert.pem
ln -s /etc/letsencrypt/archive/${ENDPOINT_URL}/chain${LATEST_CERT_VERSION}.pem /etc/letsencrypt/live/${ENDPOINT_URL}/chain.pem
ln -s /etc/letsencrypt/archive/${ENDPOINT_URL}/fullchain${LATEST_CERT_VERSION}.pem /etc/letsencrypt/live/${ENDPOINT_URL}/fullchain.pem
ln -s /etc/letsencrypt/archive/${ENDPOINT_URL}/privkey${LATEST_CERT_VERSION}.pem /etc/letsencrypt/live/${ENDPOINT_URL}/privkey.pem


