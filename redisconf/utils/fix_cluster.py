import requests
import os, time

cs_url  = os.getenv('XPIPE')
dcs = ["SHAOY", "SHARB", "SHAJQ"]
mapdcs = {"SHAOY" : "UAT", "SHAJQ" : "NTGXH"}
#mapdcs = {}
TYPE="one_way"
count = 2
SLEEP=10

def getClusterInfo():
    mapdc=dcs[0]
    if not (mapdcs is None or not(mapdcs.has_key(dcs[0]))):
        mapdc = mapdcs[dcs[0]]
    clusters={}
    r = requests.get(cs_url + "/api/dc/" + mapdc)
    if r.status_code != 200:
        print "ERR:", "get cluster info", mapdc
        return
    for cluster, values in r.json()["clusters"].items():
        clusters[cluster] = {}
        clusters[cluster]["type"] = values["type"]

    return clusters

    
def getTasks(clusterInfo):
    r = requests.get(cs_url + "/api/redis/inner/unhealthy/all")
    tasks=[]
    for cluster, shards in r.json()["unhealthyInstance"].items():
        for shard in shards.keys():
            shard = shard.split()[1]
            #print  "cluster:", cluster, "shard:", shard
            if clusterInfo.has_key(cluster) and clusterInfo[cluster]["type"] == TYPE :
                tasks.append([cluster, shard])
    return tasks
    

def doTasks(tasks, count, op_type):
    print "All Task count:", len(tasks), "do task count:", count
    realCount = min(count, len(tasks))
    print "OP:{}, Check All Tasks: ".format(op_type.upper())
    for i in range(realCount):
        print i, ":", tasks[i]
    if raw_input("continue yes/no:")  != "yes":
        print "quit !!"
        return 0
    for i in range(realCount):
        cluster = tasks[i][0]
        shard = tasks[i][1]
        print "==begin:", cluster, shard
        for dc in dcs:
            url = "{}/api/keepers/{}/{}/{}".format(cs_url, dc, cluster, shard)
            if op_type == "delete":
                r = requests.delete(url)
            if op_type == "post":
                r = requests.post(url)
            if r.status_code != 200:
                print "fail", "curl -X{} {}".format(op_type.upper(), url)
            else:
                print "succeed", "curl -X{} {}".format(op_type.upper(), url)
    return i+1

if __name__ == "__main__":
    clusterInfo = getClusterInfo()
    tasks = getTasks(clusterInfo)
    taskDone = doTasks(tasks, count, "delete")
    if taskDone > 0:
        print "sleep {} seconds".format(SLEEP)
        time.sleep(SLEEP)
    doTasks(tasks, count, "post")