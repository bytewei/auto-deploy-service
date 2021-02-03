#!/bin/bash
# generate deploy.sh

app=$1
env=$2
file=../conf/${app}.json
if [ ! -f $file ];then
    echo "Json file is not exit."
    exit 1
fi

jq=`which jq`

consul=`jq .consul.env${env}.ip ../conf/public.json`
token=`jq .consul.env${env}.token ../conf/public.json`
service=`jq .service $file`
httpport=`jq .httpport $file`
base_dir=`jq .base_dir $file`
bak_dir=`jq .bak_dir $file`
url=`jq .url $file`

cat >>`echo $app|sed 's/\"//g'`-$env.json<<EOF
{
  "consul": $consul,
  "token": $token,
  "service": $service,
  "app": "$app",
  "httpport": $httpport,
  "base_dir": $base_dir,
  "bak_dir": $bak_dir,
  "url": $url,
}
EOF

