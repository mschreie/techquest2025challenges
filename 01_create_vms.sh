. ./env.sh

# create the VMs
for i in {1..20}; do
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
' > virtualmachine-thesource_$i.yaml
  oc create -f secret.yaml -n mtv-user$i
  oc create -f virtualmachine-thesource_$i.yaml -n mtv-user$i
done


