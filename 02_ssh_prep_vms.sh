# https://downloads-openshift-console.apps.cluster-f78pb.dyn.redhatworkshops.io/amd64/linux/oc.tar
# https://hyperconverged-cluster-cli-download-openshift-cnv.apps.cluster-f78pb.dyn.redhatworkshops.io/amd64/linux/virtctl.tar.gz


. ./env.sh

for CLUSTERID in $MUTLICLUSTERID
do 
    echo $CLUSTERID
    PW=ADMINPW_$CLUSTERID  
    PW=${!PW}
    echo $PW
        echo "Login to cluster...."

        oc login -u admin -p $PW https://api.cluster-${CLUSTERID}.dyn.redhatworkshops.io:6443/

    for ((i=1;i<=MAXUSER;i++)); do
        # login and get ssh running
        echo login and get ssh running
        virtctl -n mtv-user$i ssh -i ~/.ssh/id_techquest cloud-user@vmi/thesource  -c "hostname"
    done

    for ((i=1;i<=MAXUSER;i++)); do
	# create network attachment definition for all projects
	echo  create network attachment definition for all projects
	sed -e 's/default/mtv-user'$i'/' files/networkattachmentdefinition.yaml | oc create -f - -n mtv-user$i

	echo  patch the VM
        oc patch vm thesource -n mtv-user2 --type=json -p '[
          {"op":"add","path":"/spec/template/spec/domain/devices/interfaces","value":[
            {"name":"default","masquerade":{}},
            {"name":"nic-flat","bridge":{}}
          ]},
          {"op":"add","path":"/spec/template/spec/networks","value":[
            {"name":"default","pod":{}},
            {"name":"nic-flat","multus":{"networkName":"flatnetwork"}}
          ]}
        ]'

        echo Number 1
        virtctl -n mtv-user$i scp -i ~/.ssh/id_techquest ./files/rhel_image_mode-main.zip cloud-user@vmi/thesource:.
        echo Number 2
        virtctl -n mtv-user$i ssh -i ~/.ssh/id_techquest cloud-user@vmi/thesource  -c "sudo -i -- bash -c 'unzip /home/cloud-user/rhel_image_mode-main.zip && rm -f rhel_image_mode-main/README.md && mkdir rhel_image_mode-main/output'"
        echo Number 3
        virtctl -n mtv-user$i ssh -i ~/.ssh/id_techquest cloud-user@vmi/thesource  -c "sudo -i -- bash -c 'curl -o /tmp/oc.tar https://downloads-openshift-console.apps.cluster-'$CLUSTERID'.dyn.redhatworkshops.io/amd64/linux/oc.tar && cd /usr/local/bin && tar xf /tmp/oc.tar'"
        echo Number 4
        virtctl -n mtv-user$i ssh -i ~/.ssh/id_techquest cloud-user@vmi/thesource  -c "sudo -i -- bash -c 'curl -o /tmp/virtctl.tar.gz https://hyperconverged-cluster-cli-download-openshift-cnv.apps.cluster-'$CLUSTERID'.dyn.redhatworkshops.io/amd64/linux/virtctl.tar.gz && cd /usr/local/bin &&  tar xzf /tmp/virtctl.tar.gz'"
        echo Number 5
        virtctl -n mtv-user$i ssh -i ~/.ssh/id_techquest cloud-user@vmi/thesource  -c "sudo -i -- bash -c 'chmod a+x /usr/local/bin/*; restorecon -R /usr/local/bin'" 
        echo Number 6
        virtctl -n mtv-user$i ssh -i ~/.ssh/id_techquest cloud-user@vmi/thesource  -c "sudo -i -- bash -c 'echo "PATH=/usr/local/bin:$PATH" >>/root/.bash_profile'" 
        echo Number 7
        virtctl -n mtv-user$i ssh -i ~/.ssh/id_techquest cloud-user@vmi/thesource  -c "sudo -i -- bash -c 'subscription-manager register --org 7257185 --activationkey RHEL'"
        echo Number 8
        virtctl -n mtv-user$i ssh -i ~/.ssh/id_techquest cloud-user@vmi/thesource  -c 'sudo tee /etc/containers/registries.conf.d/99-openshift-internal.conf >/dev/null' < ./files/99-openshift-internal.conf
    done
done



