. ./env.sh

for CLUSTERID in $MUTLICLUSTERID
do 
	echo $CLUSTERID
        echo "Login to cluster...."
        oc login -u admin -p $ADMINPD https://api.cluster-${CLUSTERID}.dynamic.redhatworkshops.io:6443/
	# create the VMs
	for ((i=1;i<=MAXUSER;i++)); do
           echo "Create VM Manifest"
	   virtctl create vm --instancetype u1.small --name thesource --volume-import "type:http,size:20Gi,url:$IMAGEBUILDERURL" \
	   | awk '
	       /^      terminationGracePeriodSeconds: 180/ { print; 
			  print "      accessCredentials:"
			  print "        - sshPublicKey:"
			  print "            propagationMethod:"
			  print "              noCloud: {}"
			  print "            source:"
			  print "              secret:"
			  print "                secretName: techquest"
			  next
	       } 

	       /^status: {}/ {

			  print "      - cloudInitNoCloud:"
			  print "          userData: |-"
			  print "            #cloud-config"
			  print "            user: cloud-user"
			  print "            password: redhat"
			  print "            chpasswd: { expire: False }"
			  print "        name: cloudinitdisk"

			  print;
			  next
	       }
	       { print }
	   ' > virtualmachine-thesource_$CLUSTERID_$i.yaml
	   oc create -f secret.yaml -n mtv-user$i
           echo "Create VM §CLUSTERID $i"
	   oc create -f virtualmachine-thesource_$CLUSTERID_$i.yaml -n mtv-user$i
	done
done


