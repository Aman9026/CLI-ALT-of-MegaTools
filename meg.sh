#!/bin/bash
# Updated Aman Gupta
# Syntax ./meg.sh
url=$1

# get id and key from url
id=`echo $url | awk -F '!' '{print $2}'`
key=`echo $url | awk -F '!' '{print $3}' | sed -e 's/-/+/g' -e 's/_/\//g' -e 's/,//g'`

# decode key
b64_hex_key=`echo -n $key | base64 --decode --ignore-garbage 2> /dev/null | xxd -p | tr -d '\n'`
key[0]=$(( 0x${b64_hex_key:00:16} ^ 0x${b64_hex_key:32:16} ))
key[1]=$(( 0x${b64_hex_key:16:16} ^ 0x${b64_hex_key:48:16} ))
key=`printf "%016x" ${key[*]}`
iv="${b64_hex_key:32:16}0000000000000000"

# send the request
json_data=`curl --silent --request POST --data-binary '[{"a":"g","g":1,"p":"'$id'"}]' https://eu.api.mega.co.nz/cs`

# get the download url
#Formerly $12
new_url=`echo $json_data | awk -F '"' '{print $14}'`


# get the file name, have to do a lot of weird things because openssl is tricky
tmp=`echo $json_data | awk -F '"' '{print $6}' | sed -e 's/-/+/g' -e 's/_/\//g' -e 's/,//g' | base64 --decode --ignore-garbage 2> /dev/null | xxd -p | tr -d '\n' > enc_attr.mdtmp`
tmp=`xxd -p -r enc_attr.mdtmp > enc_attr2.mdtmp`
openssl enc -d -aes-128-cbc -K $key -iv 0 -nopad -in enc_attr2.mdtmp -out dec_attr.mdtmp
#Changed this too, can't remember where from
file_name=`cat dec_attr.mdtmp | awk -F '"' '{print $8}'`
rm -f *.mdtmp

# download the file and decrypt it
enc_file=${file_name}.enc

curl --output $enc_file $new_url
openssl enc -d -aes-128-ctr -K $key -iv $iv -in $enc_file -out $file_name
rm -f $enc_file
