#!/bin/bash
# generate deploy.sh

app=$1
env=$2
file=conf/${app}.json
if [ ! -f $file ];then
    echo "Json file is not exit."
    exit 1
fi

jq=`which jq`

nacos=`jq .nacos.env${env}.ip ./conf/public.json`
nacos_ns=`jq .nacos.env${env}.namespace ./conf/public.json`

app=`jq .app $file`
port=`jq .port $file`
bak_dir=`jq .bak_dir $file`
log_dir=`jq .log_dir $file`
start_log=`jq .start_log $file`
url=`jq .url $file`

base_dir=`jq .env${env}.base_dir $file`
if [ $base_dir == 'null' ];then
    base_dir=`jq .base_dir $file`
fi
xmx=`jq .env${env}.xmx $file`
if [ $xmx == 'null' ];then
    xmx=`jq .default.xmx $file`
fi
xms=`jq .env${env}.xms $file`
if [ $xms == 'null' ];then
    xms=`jq .default.xmx $file`
fi

params_origin=`jq .env${env}.params $file`
if [ "$params_origin" == 'null' ];then
    params_origin=`jq .default.params $file`
    params=`echo $params_origin |jq .[] |xargs|sed 's/^/"&/g'|sed 's/$/&"/g'`
else
    params=`echo $params_origin |jq .[] |xargs|sed 's/^/"&/g'|sed 's/$/&"/g'`
fi

echo "========== Start generate deploy.sh ==========="
\cp -f deploy_template.sh deploy.sh
sed -i "s@mynacos@$nacos@g" deploy.sh
sed -i "s@mynsnacos@$nacos_ns@g" deploy.sh
sed -i "s@myapp@$app@g" deploy.sh
sed -i "s@myport@$port@g" deploy.sh
sed -i "s@mybasedir@$base_dir@g" deploy.sh
sed -i "s@mylogdir@$log_dir@g" deploy.sh
sed -i "s@mystartlog@$start_log@g" deploy.sh
sed -i "s@myurl@$url@g" deploy.sh
sed -i "s@myxmx@$xmx@g" deploy.sh
sed -i "s@myxms@$xms@g" deploy.sh
sed -i "s@myparams@$params@g" deploy.sh
sed -i "s@serviceapp@$app@g" deploy.sh

chmod +x deploy.sh

cat >>`echo $app|sed 's/\"//g'`-$env.json<<EOF
{
  "nacos": $nacos,
  "nacos_ns": $nacos_ns,
  "app": $app,
  "port": $port,
  "base_dir": $base_dir,
  "bak_dir": $bak_dir,
  "log_dir": $log_dir,
  "start_log": $start_log,
  "url": $url,
}
EOF

