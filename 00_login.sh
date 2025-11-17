. ./env.sh

for CLUSTERID in $MUTLICLUSTERID
do 
	echo $CLUSTERID
	PW=ADMINPW_$CLUSTERID  
	echo ${!PW}
	oc login -u admin -p ${!PW} https://api.cluster-${CLUSTERID}.dynamic.redhatworkshops.io:6443/
done 

