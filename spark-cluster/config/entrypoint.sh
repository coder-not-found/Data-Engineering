#!/bin/bash
 
# Change dns config

 echo "Updating DNS Config"

 NETWORK="tailscale0"
 
if [ -d "/sys/class/net/$NETWORK" ]; then

         sed -i "/dfs.datanode.dns.interface/{n;s/default/$NETWORK/}" $HADOOP_CONF_DIR/hdfs-site.xml

 fi
 
# Start services in the background

 service ssh start
 
HOSTNAME=$(hostname)

 # Format on the first start

 if [ "$HOSTNAME" = "master-node" ] && [ ! -d "/home/hadoop/data/nameNode/current" ]; then

         $HADOOP_HOME/bin/hadoop namenode -format

 fi
 
if [ "$HOSTNAME" = "master-node" ]; then

         echo "Starting HDFS and Yarn on Master"

         $HADOOP_HOME/sbin/start-dfs.sh

         sleep 5

         $HADOOP_HOME/sbin/start-yarn.sh

         sleep 5

         $SPARK_HOME/sbin/start-master.sh -h 100.123.239.104
 
        # Starts history server to check running and completed applications

         $HADOOP_HOME/bin/hdfs dfs -mkdir -p /spark-logs

         $SPARK_HOME/sbin/start-history-server.sh
 
        # Disables safe mode to prevent errors in small clusters

         $HADOOP_HOME/bin/hdfs dfsadmin -safemode leave

         echo "Start Jupyter..."

         nohup jupyter notebook --allow-root --no-browser --NotebookApp.token='' --ip='*' > /home/big_data/jupyter.log &

 else

         echo "Starting DataNode and NodeManager on Worker"

         # Start only datanode (not full DFS)

         $HADOOP_HOME/bin/hdfs --daemon start datanode

         sleep 5

         # Start only nodemanager (not full YARN)

         $HADOOP_HOME/bin/yarn --daemon start nodemanager

         sleep 5

         $SPARK_HOME/sbin/start-worker.sh spark://100.123.239.104:7077

 fi

 sleep infinity
