. ./env.sh

for CLUSTERID in $MUTLICLUSTERID
do 
	echo $CLUSTERID
        echo "Login to cluster...."
        oc login -u admin -p $ADMINPD https://api.cluster-${CLUSTERID}.dynamic.redhatworkshops.io:6443/

	for ((i=1;i<=MAXUSER;i++)); do
	   virtctl stop thesource -n mtv-user$i  --force --grace-period 0 &
	done
	for ((i=1;i<=MAXUSER;i++)); do
	   oc delete vm thesource -n mtv-user$i  &
	done
done


