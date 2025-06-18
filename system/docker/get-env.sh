#!/bin/sh

# cite
# https://stackoverflow.com/a/40866205

# USAGE:
# download-aws.sh <bucket> <region> <source-file> <dest-file>

set -e

# fill this in with your credentials, this could be changed to use the same approach as s3-upload-aws4.sh.
s3Key='AKIA222ESEU6KJI7ZDWI'
# as above
s3Secret='n1LhmXClSMk628bvacd1SACCyZ2OWSGOCXeTFRXR'

file=$3
bucket=$1
host="${bucket}.s3.amazonaws.com"
resource="/${file}"
contentType="text/plain"
dateValue="`date +'%Y%m%d'`"
X_amz_date="`date --utc +'%Y%m%dT%H%M%SZ'`"
X_amz_algorithm="AWS4-HMAC-SHA256"
awsRegion=$2
awsService="s3"
X_amz_credential="$s3Key%2F$dateValue%2F$awsRegion%2F$awsService%2Faws4_request"
X_amz_credential_auth="$s3Key/$dateValue/$awsRegion/$awsService/aws4_request"

signedHeaders="host;x-amz-algorithm;x-amz-content-sha256;x-amz-credential;x-amz-date"
# this hash is created via echo -n ''|sha256sum
contentHash="e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"

HMAC_SHA256_asckey () {
        var=`/bin/echo -en $2 | openssl sha256 -hmac $1 -binary | xxd -p -c256`
        echo $var
}
HMAC_SHA256 () {
        var=`/bin/echo -en $2 | openssl dgst -sha256 -mac HMAC -macopt hexkey:$1 -binary | xxd -p -c256`
        echo $var
}
REQUEST () {
        canonicalRequest="GET\n$resource\n\n"\
"host:$1\n"\
"x-amz-algorithm:$X_amz_algorithm""\n"\
"x-amz-content-sha256:$contentHash""\n"\
"x-amz-credential:$X_amz_credential""\n"\
"x-amz-date:$X_amz_date""\n\n"\
"$signedHeaders\n"\
"$contentHash"
        #echo $canonicalRequest
        canonicalHash=`/bin/echo -en "$canonicalRequest" | openssl sha256 -binary | xxd -p -c256`
        stringToSign="$X_amz_algorithm\n$X_amz_date\n$dateValue/$awsRegion/s3/aws4_request\n$canonicalHash"
        #echo $stringToSign


        s1=`HMAC_SHA256_asckey "AWS4""$s3Secret" $dateValue`
        s2=`HMAC_SHA256 "$s1" "$awsRegion"`
        s3=`HMAC_SHA256 "$s2" "$awsService"`
        signingKey=`HMAC_SHA256 "$s3" "aws4_request"`
        signature=`/bin/echo -en $stringToSign | openssl dgst -sha256 -mac HMAC -macopt hexkey:$signingKey -binary | xxd -p -c256`
        #echo signature

        authorization="$X_amz_algorithm Credential=$X_amz_credential_auth,SignedHeaders=$signedHeaders,Signature=$signature"
        result=$(curl -v -H "Host: $1" -H "X-Amz-Algorithm: $X_amz_algorithm" -H "X-Amz-Content-Sha256: $contentHash" -H "X-Amz-Credential: $X_amz_credential" -H "X-Amz-Date: $X_amz_date" -H "Authorization: $authorization" https://${1}/${file} -o "$2" --write-out "%{http_code}")
        if [ $result -eq 307 ]; then
                redirecthost=`cat $2 | sed -n 's:.*<Endpoint>\(.*\)</Endpoint>.*:\1:p'`
                REQUEST "$redirecthost" "$2"
        fi
}
REQUEST "$host" "$4"
