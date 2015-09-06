#!/bin/bash

# mega-dl
# Thanks to http://hacktracking.blogspot.com.au/2013/07/download-mega-files-from-command-line.html



# http://stackoverflow.com/questions/19059944/kb-to-mb-using-bash
function bytes_for_humans {
    local -i bytes=$1;
    if [[ $bytes -lt 1048576 ]]; then
        echo "$(( (bytes + 1023)/1024 )) KB"
    else
        echo "$(( (bytes + 1048575)/1048576 )) MB"
    fi
}

url=$1
id=$(echo $url | awk -F '!' '{print $2}')
key=$(echo $url | awk -F '!' '{print $3}' | sed -e 's/-/+/g' -e 's/_/\//g' -e 's/,//g')
b64_hex_key=$(echo -n $key | base64 --decode --ignore-garbage 2> /dev/null | xxd -p | tr -d '\n')| xxd -p | tr -d '\n')
key[0]=$(( 0x${b64_hex_key:00:16} ^ 0x${b64_hex_key:32:16} ))
key[1]=$(( 0x${b64_hex_key:16:16} ^ 0x${b64_hex_key:48:16} ))
key=$(printf "%x" ${key[*]})
iv="${b64_hex_key:32:16}0000000000000000"
api=$(curl --silent --request POST --data-binary '[{"a":"g","g":1,"p":"'$id'"}]' https://eu.api.mega.co.nz/cs)
filename=$(echo "${api}" | awk -F '"' '{print $6}' | sed -e 's/-/+/g' -e 's/_/\//g' -e 's/,//g' | base64 -di 2> /dev/null | xxd -p | tr -d '\n' | xxd -p -r | openssl enc -d -aes-128-cbc -K "${key}" -iv 0 -nopad 2> /dev/null | awk -F '"' '{print $4}')
filesiz=$(echo "${api}" | awk -F '"' '{print $3}' | sed -e 's/-/+/g' -e 's/_/\//g' -e 's/,//g' -e 's/://g')
filesize=$(bytes_for_humans $filesiz)
echo "Filesize : $filesize"
echo "Filename : $filename"
