. ./env.sh

for CLUSTERID in $MUTLICLUSTERID
do 
	echo $CLUSTERID
	# create the VMs
	for ((i=1;i<=MAXUSER;i++)); do
	     oc login -u admin -p $ADMINPD https://api.cluster-${CLUSTERID}.dynamic.redhatworkshops.io:6443/
	done
done 

