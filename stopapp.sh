pid=`netstat -apn | grep 8080 | grep -o -P '(?<=LISTEN).*(?=/python)'`
result=`kill -9 $pid`