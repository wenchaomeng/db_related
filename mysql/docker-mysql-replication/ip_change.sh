ip=`ifconfig | egrep -m 1 "192\.|10\." | awk '{print $2}'`
echo "------Local ip address:$ip"
sed -i 's/ADDRESS=\(.*\)/ADDRESS='$ip'/' .env
cat .env
