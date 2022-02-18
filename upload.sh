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
[ ! -f ${source} ] && error_exit "${source} is not existed"
file_name=`basename ${source}`

dest=${2:-'/'}
file_dir=`dirname "${dest}/${file_name}"`
[[ ${file_dir} == '/' || ${file_dir} == '.' ]] && file_dir=''

resource="/${bucket}${file_dir}/${file_name}"
content_type=`file --mime --brief ${source} |awk -F ";" '{print $1}'`
date_value="`TZ=GMT env LANG=en_US.UTF-8 date +'%a, %d %b %Y %H:%M:%S GMT'`"
if [[ `uname -a` =~ 'Darwin' ]]; then
    # remove newline in macOS
    string_to_sign="PUT\n\n${content_type}\n${date_value}\n${resource}\c"
    signature=`echo ${string_to_sign} | openssl sha1 -hmac ${access_key_secret} -binary | base64`
else
    string_to_sign="PUT\n\n${content_type}\n${date_value}\n${resource}"
    signature=`echo -en ${string_to_sign} | openssl sha1 -hmac ${access_key_secret} -binary | base64`
fi

url="https://${host}${file_dir}/${file_name}"

curl --silent --include --output /dev/null -q -X PUT -T "${source}" \
    -H "Host: ${host}" \
    -H "Date: ${date_value}" \
    -H "Content-Type: ${content_type}" \
    -H "Authorization: OSS ${access_key_id}:${signature}" \
    ${url}

echo "upload ${source} to ${url}"
