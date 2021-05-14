. ./ips.sh
xpipe=$xpipe_uat

export XPIPE=$xpipe


#/api/redis/inner/unhealthy/all

python fix_cluster.py
