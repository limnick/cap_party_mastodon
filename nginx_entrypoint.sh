#!/bin/sh

# get ssl certs from gcloud storage
/root/nginx_fetch_certs.sh

exec nginx -g "daemon off;"
