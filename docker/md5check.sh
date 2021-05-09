#!/bin/bash

tolower ()
{
    if [ "$(uname)" == "Darwin" ]; then
        echo "$@" | awk -F '\\\|\\\|\\\|' '{print tolower($1)}';
    else
        echo "$@" | awk -F '\|~\|' '{print tolower($1)}';
    fi
}

md5check ()
{
    local NARG=$#;
    function quit ()
    {
        kill -INT $$ > /dev/null
    };
    function usage ()
    {
        echo "md5check [file] [correct-checksum]";
        quit 1
    };
    function check-md5 ()
    {
        local MSG="";
        local RET=0;
        local S1=${1};
        local S2=${2};
        if [ ${#S1} -ne ${#S2} ]; then
            MSG=$(echo "${S1} and ${S2} are of different lengths -- invalid checksum");
            RET=1;
        fi;
        if [ ${RET} -eq 0 ]; then
            for ((k=0; k<${#S2}; k++ ))
            do
                if [ "${S1:$k:1}" != "${S2:$k:1}" ]; then
                    MSG=$(echo "${S1} differs from ${S2} at position ${k} - ${S1:$k:1} vs. ${S2:$k:1}");
                    RET=2;
                fi;
            done;
        fi;
        echo -n "${MSG}";
        return ${RET}
    };
    if [ ${NARG} -ne 2 ]; then
        usage;
    fi;
    if [ ! -f ${1} ]; then
        usage;
    fi;
    local MD5=$(md5sum ${1} | awk '{print $1}');
    local ARGS=("${MD5}" "${2}");
    local S1=${ARGS[0]};
    local S2=${ARGS[1]};
    local S3=$(tolower ${S2});
    local S4=$(tolower ${S2});
    local RET=0;
    local MSG="";
    for i in "${S4}" "${S3}" "${S2}";
    do
        MSG=$(check-md5 "${S1}" "${i}");
        RET=$?;
        if [ ${RET} -eq 0 ]; then
            MSG=$(echo "${1} matches the provided checksum");
            break;
        fi;
    done;
    echo ${MSG};
    return ${RET}
}
