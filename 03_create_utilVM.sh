. ./env.sh

for CLUSTERID in $MUTLICLUSTERID
do 
    echo $CLUSTERID
    PW=ADMINPW_$CLUSTERID  
    PW=${!PW}
    echo $PW
    echo "Login to cluster...."
    oc login -u admin -p $PW https://api.cluster-${CLUSTERID}.dyn.redhatworkshops.io:6443/
    # create the VM
    echo "Create VM Manifest"
    echo virtualmachine-util${CLUSTERID}.yaml
    virtctl create vm --instancetype u1.small --name util --volume-import "type:http,size:20Gi,url:$IMAGEBUILDERURL" \
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
        ' > virtualmachine-util-${CLUSTERID}.yaml
    oc create -f secret.yaml -n default
    echo "Create util VM $CLUSTERID"
    oc create -f virtualmachine-util-${CLUSTERID}.yaml -n default

    sleep 30

    # login and get ssh running
    tmp=$(mktmp)
    for (( i = 0; i < 30; i++ )); do
       virtctl -n default ssh -i ~/.ssh/id_techquest cloud-user@vmi/util  -c "hostname" 2>$tmp
       err=$(<"$tmp")
       [[ $err == *'exit status 255'* ]] || break
       sleep 10
    done



    echo Number 1
    virtctl -n default scp -i ~/.ssh/id_techquest ./rhel_image_mode-main.zip cloud-user@vmi/util:.
    echo Number 2
    virtctl -n default ssh -i ~/.ssh/id_techquest cloud-user@vmi/util  -c "sudo -i -- bash -c 'unzip /home/cloud-user/rhel_image_mode-main.zip && rm -f rhel_image_mode-main/README.md && mkdir rhel_image_mode-main/output'"
    echo Number 3
    virtctl -n default ssh -i ~/.ssh/id_techquest cloud-user@vmi/util  -c "sudo -i -- bash -c 'curl -o /tmp/oc.tar https://downloads-openshift-console.apps.cluster-'$CLUSTERID'.dyn.redhatworkshops.io/amd64/linux/oc.tar && cd /usr/local/bin && tar xf /tmp/oc.tar'"
    echo Number 4
    virtctl -n default ssh -i ~/.ssh/id_techquest cloud-user@vmi/util  -c "sudo -i -- bash -c 'curl -o /tmp/virtctl.tar.gz https://hyperconverged-cluster-cli-download-openshift-cnv.apps.cluster-'$CLUSTERID'.dyn.redhatworkshops.io/amd64/linux/virtctl.tar.gz && cd /usr/local/bin &&  tar xzf /tmp/virtctl.tar.gz'"
    echo Number 5
    virtctl -n default ssh -i ~/.ssh/id_techquest cloud-user@vmi/util  -c "sudo -i -- bash -c 'chmod a+x /usr/local/bin/*; restorecon -R /usr/local/bin'" 
    echo Number 6
    virtctl -n default ssh -i ~/.ssh/id_techquest cloud-user@vmi/util  -c "sudo -i -- bash -c 'echo "PATH=/usr/local/bin:$PATH" >>/root/.bash_profile'" 
    echo Number 7
    virtctl -n default ssh -i ~/.ssh/id_techquest cloud-user@vmi/util  -c "sudo -i -- bash -c 'subscription-manager register --org 7257185 --activationkey RHEL'"
    echo Number 8
    virtctl -n default ssh -i ~/.ssh/id_techquest cloud-user@vmi/util  -c 'sudo tee /etc/containers/registries.conf.d/99-openshift-internal.conf >/dev/null' < ./99-openshift-internal.conf

     echo Preparing central registry on each cluster vi util VM ....
     sed -i -e 's/CLUSTERID=.*$/CLUSTERID='$CLUSTERID'/' prepRegistry.sh
     sed -i -e 's/ADMIN_PW=.*$/ADMIN_PW='$PW'/' prepRegistry.sh
     sed -i -e 's/USERID=.*$/USERID=user'$i'/' prepRegistry.sh
     virtctl -n default scp -i ~/.ssh/id_techquest ./prepRegistry.sh cloud-user@vmi/util:.
     virtctl -n default ssh -i ~/.ssh/id_techquest cloud-user@vmi/util  -c "MYPW=GehHeim123 bash prepRegistry.sh"

        echo Number 9 - for UTIL Server
        virtctl -n default ssh -i ~/.ssh/id_techquest cloud-user@vmi/util  -c 'sudo subscription-manager repos --enable codeready-builder-for-rhel-$(rpm -E %rhel)-$(uname -m)-rpms && dnf install https://dl.fedoraproject.org/pub/epel/epel-release-latest-$(rpm -E %rhel).noarch.rpm && dnf install pandoc'
        virtctl -n default ssh -i ~/.ssh/id_techquest cloud-user@vmi/util  -c 'sudo systemctl enable --now httpd.service'

        virtctl expose vmi util -n default --name=httpd --port=80 --target-port=80
        oc expose svc/httpd -n default 

done

