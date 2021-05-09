#!/bin/bash

function exec-verbose()
{
    echo "##### Executing \"${@}\" #####"
    eval $@
}

function renew-cdash-cert()
{
    echo y | certbot certonly --agree-tos --manual --preferred-challenges=http --manual-auth-hook /var/www/cdash/authenticator.sh --manual-cleanup-hook /var/www/cdash/cleanup.sh ${@}
}

function backup-cdash()
{
    local FNAME=/var/lib/cdash-db-backup/cdash.backup
    local EXT=mysql
    local ARGS="${@}"

    # directory
    if [ ! -d "$(dirname ${FNAME})" ]; then
        mkdir -p $(dirname ${FNAME})
    fi

    # rotate logs
    for j in $(seq 9 -1 1)
    do
        local i=$((${j} - 1))
        if [ -f ${FNAME}.${i}.${EXT} ]; then
            exec-verbose mv ${FNAME}.${i}.${EXT} ${FNAME}.${j}.${EXT}
        fi
    done

    # move current to ${FNAME}.0.${EXT}
    if [ -f ${FNAME}.${EXT} ]; then
        mv ${FNAME}.${EXT} ${FNAME}.0.${EXT}
    fi

    if [ -z "${ARGS}" ]; then
        local DB_PASSWD=""
        if [ -f "/run/secrets/cdash-mysql-passwd" ]; then
            DB_PASSWD=$(cat /run/secrets/cdash-mysql-passwd)
        else
            DB_PASSWD=$(echo $CDASH_CONFIG | sed 's/;/\n/g' | grep CDASH_DB_PASS  | awk '{print $NF}' | sed "s/'//g")
        fi
        ARGS="--host=mysql --password=${DB_PASSWD} cdash"
    fi

    # echo "#### Executing \"mysqldump ${ARGS}\" #####"
    mysqldump ${ARGS} > ${FNAME}.${EXT}
}
