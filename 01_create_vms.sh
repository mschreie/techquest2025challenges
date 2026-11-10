. ./env.sh

for CLUSTERID in $MUTLICLUSTERID
do 
	echo $CLUSTERID
	PW=ADMINPW_$CLUSTERID  
        echo "Login to cluster...."
        oc login -u admin -p ${!PW} https://api.cluster-${CLUSTERID}.dyn.redhatworkshops.io:6443/
	# changed: keep SSH host keys in a file dedicated to this cluster
	SSH_KNOWN_HOSTS="$HOME/.ssh/kubevirt_known_hosts-$CLUSTERID"
	mkdir -p "$HOME/.ssh"
	touch "$SSH_KNOWN_HOSTS"
	chmod 600 "$SSH_KNOWN_HOSTS"
	# create the VMs
	for ((i=1;i<=MAXUSER;i++)); do
           echo "Create VM Manifest"
	   echo tmp/virtualmachine-thesource_${CLUSTERID}_${i}.yaml
	   virtctl create vm --instancetype u1.small --name thesource --volume-import "type:http,size:20Gi,url:$THESOURCEURL" \
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
	   ' > tmp/virtualmachine-thesource_${CLUSTERID}_${i}.yaml
	   oc create -f files/secret.yaml -n mtv-user$i
           echo "Create VM $CLUSTERID $i"
	    # changed: remove the old host key only after OpenShift creates a new VM.
		   if oc create -f tmp/virtualmachine-thesource_${CLUSTERID}_${i}.yaml -n mtv-user$i; then
			   ssh-keygen -R "vmi.thesource.mtv-user$i" -f "$SSH_KNOWN_HOSTS" >/dev/null 2>&1 || true
		   else
			   echo "VM creation failed for $CLUSTERID user$i; keeping its saved SSH host key" >&2
			   exit 1
		   fi
	done
done


