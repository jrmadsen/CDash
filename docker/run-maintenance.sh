#!/bin/bash -lie

LOG_FILE=/var/www/cdash/maintenance.log

source /etc/profile

env | tee ${LOG_FILE}

type backup-cdash | tee -a ${LOG_FILE}

backup-cdash &> /dev/stdout | tee -a ${LOG_FILE}
