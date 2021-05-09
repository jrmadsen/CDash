#!/bin/bash
echo $CERTBOT_VALIDATION > /var/www/cdash/.well-known/acme-challenge/$CERTBOT_TOKEN
