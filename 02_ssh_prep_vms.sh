# https://downloads-openshift-console.apps.cluster-f78pb.dynamic.redhatworkshops.io/amd64/linux/oc.tar
# https://hyperconverged-cluster-cli-download-openshift-cnv.apps.cluster-f78pb.dynamic.redhatworkshops.io/amd64/linux/virtctl.tar.gz


. ./env.sh


# create the VMs
for i in {1..20}; do
   virtctl -n mtv-user$i ssh -i ~/.ssh/id_techquest cloud-user@vmi/thesource  -c "hostname"
   virtctl -n mtv-user$i scp -i ~/.ssh/id_techquest ./rhel_image_mode-main.zip cloud-user@vmi/thesource:.
   virtctl -n mtv-user$i ssh -i ~/.ssh/id_techquest cloud-user@vmi/thesource  -c "sudo -i -- bash -c 'unzip /home/cloud-user/rhel_image_mode-main.zip && rm -f rhel_image_mode/README.md"
   virtctl -n mtv-user$i ssh -i ~/.ssh/id_techquest cloud-user@vmi/thesource  -c "sudo -i -- bash -c 'curl -o /tmp/oc.tar https://downloads-openshift-console.apps.cluster-'$CLUSTERID'.dynamic.redhatworkshops.io/amd64/linux/oc.tar && cd /usr/local/bin && tar xf /tmp/oc.tar'"
   virtctl -n mtv-user$i ssh -i ~/.ssh/id_techquest cloud-user@vmi/thesource  -c "sudo -i -- bash -c 'curl -o /tmp/virtctl.tar.gz https://hyperconverged-cluster-cli-download-openshift-cnv.apps.cluster-'$CLUSTERID'.dynamic.redhatworkshops.io/amd64/linux/virtctl.tar.gz && cd /usr/local/bin &&  tar xzf /tmp/virtctl.tar.gz'"
   virtctl -n mtv-user$i ssh -i ~/.ssh/id_techquest cloud-user@vmi/thesource  -c "sudo -i -- bash -c 'chmod a+x /usr/local/bin/*; restorecon -R /usr/local/bin'" 
done


