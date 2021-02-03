#!/bin/bash
# func: deploy serviceapp script
# auth: renxiaowei@cnstrong
# version: v2.0

nacos=mynacos
nacos_ns=mynsnacos
app=myapp
port=myport
base_dir=mybasedir
log_dir=mylogdir
start_log=mystartlog
url=myurl
xmx=myxmx
xms=myxms
params=myparams

mkdir -p $base_dir/$app/$log_dir
log=$base_dir/$app/$log_dir/$start_log
pid=$base_dir/$app/$log_dir/.${app}.pid

export JAVA_OPT="-server -Xms$xms -Xmx$xmx"

pid_of_jar(){
    cat $pid 2>/dev/null
}

health_check() {
    curl -I -s http://127.0.0.1:$port$url |grep 200 > /dev/null 2>&1
    if [ $? -eq 0 ];then
        echo "Service $app is healthy, deploy success."
    else
        echo "Service $app is unhealthy."
    fi
}

status() {
    if [ -z `pid_of_jar` ];then
        echo "=========== Service $app is not running. ============"
    else
        echo "=========== Service $app is running, status: ============"
        ps -ef |grep $app|egrep -vw "grep|${app}.jar-|vi|vim|tail|tailf|dhcp"
    fi
}

stop() {
    echo "=========== Stop: $app ... ============"
    pid_of_jar |xargs kill -9 > /dev/null 2>&1 ; rm -f $pid
    if [ $? -eq 0 ];then
        sleep 1
        echo "Stop Successfully."
    else
        echo "Stop Failed."
    fi
    status
}

force_stop() {
    stop > /dev/null
    ps -ef |grep $app |egrep -vw "grep|${app}.jar-|deploy.sh"|xargs kill -9 > /dev/null 2>&1
    if [ $? -eq 0 ];then
        sleep 1
        echo "Force stop Successfully."
    else
        echo "Force stop Failed."
    fi
    status
}

start() {
    if [ ! -f $base_dir/$app/${app}.jar ];then
        echo "No find service file: $base_dir/$app/${app}.jar"
        exit 1
    fi

    if [ -z `pid_of_jar` ];then
        echo "=========== Start $app ... ============"
        cd $base_dir/$app

        [ -e $log_dir/$start_log ] && cnt=`wc -l $log_dir/$start_log | awk '{print $1}'` || cnt=1
        last_newline=$cnt

        if [ $port == 'null' ];then
            nohup java $JAVA_OPT -Dspring.cloud.nacos.config.server-addr=$nacos -Dspring.cloud.nacos.config.namespace=$nacos_ns $params -jar ${app}.jar > $log_dir/$start_log 2>&1 &
            echo $! > $pid
        else
            nohup java $JAVA_OPT -Dserver.port=$port -Dspring.cloud.nacos.config.server-addr=$nacos -Dspring.cloud.nacos.config.namespace=$nacos_ns $params -jar ${app}.jar > $log_dir/$start_log 2>&1 &
            echo $! > $pid
        fi

        sleep 1

        while { pid_of_jar > /dev/null ; } && ! { tail --lines=$cnt $log_dir/$start_log | egrep -q 'Successful Application Startup!' ; }; do
            newline=`wc -l $log_dir/$start_log | awk '{ print $1 }'`
            tail --lines=$(($newline-$last_newline)) $log_dir/$start_log
            last_newline=$newline
            tail -1000 $log_dir/$start_log |grep 'APPLICATION FAILED TO START'
            if [ $? -eq 0 ];then
                force_stop
                break
            fi
            tail -1000 $log_dir/$start_log |grep 'Successful Application Startup!'
            if [ $? -eq 0 ];then
                break
            fi
        done

        health_check
    else
        echo "=========== Start Failed: $app ============"
        echo "Service: $app pid exit or service is running, please use force-stop|restart command stop|restart it."
        exit 1
    fi
    status
}

restart() {
    force_stop
    sleep 1
    start
}

case "$1" in
    start)
        start
        ;;
    stop)
        stop
        ;;
    force-stop)
        force_stop
        ;;
    status)
        status
        ;;
    restart)
        force_stop
        sleep 1
        start
        ;;
    *)
        echo $"Usage: $0 {start|stop|force-stop|status|restart}"
        exit 1
esac

