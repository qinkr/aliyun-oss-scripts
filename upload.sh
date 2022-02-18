#!/bin/sh
set -e

### aliyun oss config ###
endpoint=""
bucket=""
access_key_id=""
access_key_secret=""
host=$bucket.$endpoint

error_exit ()
{
    echo "Error: $1"
    exit 1
}

source=$1
[[ ! -f ${source} ]] && error_exit "${source} is not existed"
file_name=`basename ${source}`

dest=`dirname ${2:-''}/${file_name}`
[[ ${dest} == '/' || ${dest} == '.' ]] && dest=''

resource="/${bucket}${dest}/${file_name}"
content_type=`file --mime --brief ${source} | awk -F ";" '{print $1}'`
date_value="`TZ=GMT env LANG=en_US.UTF-8 date +'%a, %d %b %Y %H:%M:%S GMT'`"
if [[ `uname -a` =~ 'Darwin' ]]; then
    # remove newline in macOS
    string_to_sign="PUT\n\n${content_type}\n${date_value}\n${resource}\c"
    signature=`echo ${string_to_sign} | openssl sha1 -hmac ${access_key_secret} -binary | base64`
else
    string_to_sign="PUT\n\n${content_type}\n${date_value}\n${resource}"
    signature=`echo -en ${string_to_sign} | openssl sha1 -hmac ${access_key_secret} -binary | base64`
fi

url="https://${host}${dest}/${file_name}"

curl -q --silent --include \
    --output /dev/null \
    --request PUT \
    --upload-file "${source}" \
    --header "Host: ${host}" \
    --header "Date: ${date_value}" \
    --header "Content-Type: ${content_type}" \
    --header "Authorization: OSS ${access_key_id}:${signature}" \
    ${url}

echo "upload ${source} to ${url}"
