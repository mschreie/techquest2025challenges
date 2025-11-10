. ./env.sh
virtctl create vm --name thesource --volume-import "type:http,size:20Gi,url:$IMAGEBUILDERURL" \
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

       /^      volumes:/ { print;
                  print "       - cloudInitNoCloud:"
                  print "           userData: |-"
                  print "             #cloud-config"
                  print "             user: cloud-user"
                  print "             password: redhat"
                  print "             chpasswd: { expire: False }"
                  print "         name: cloudinitdisk"
                  next
        }
        { print }
' > virtualmachine-thesource.yaml

exit
############################


virtctl create vm --name thesource --volume-import "type:http,size:20Gi,url:$IMAGEBUILDERURL" \
   sed -i '/^      terminationGracePeriodSeconds: 180/a\
      accessCredentials:
        - sshPublicKey:
            propagationMethod:
              noCloud: {}
            source:
              secret:
                secretName: techquest

> virtualmachine-thesource_built.yaml

