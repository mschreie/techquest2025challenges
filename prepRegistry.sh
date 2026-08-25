#! /usr/bin/env bash
# This script need to be run on the VMs built before.

## Download images from registries with my personal login and push the on to the OCP internal cluster registry. 


# next 2 lines get exchanged by parent-script 02_ssh_prep_vms.sh
CLUSTERID=dn94p
ADMIN_PW=QHPXzQ0EYlzORwI3

## LOGIN
echo podman login -u mschreie --password-stdin  registry.redhat.io
echo $MYPW | podman login -u mschreie --password-stdin registry.redhat.io

## PULL
# Check available versions  at: https://catalog.redhat.com/en/search?q=image+builder&searchType=Containers
echo
echo podman pull registry.redhat.io/rhel10/bootc-image-builder:10.2
podman pull registry.redhat.io/rhel10/bootc-image-builder:10.2


echo
echo podman pull registry.redhat.io/rhel10/rhel-bootc:10.2
podman pull registry.redhat.io/rhel10/rhel-bootc:10.2

# Check available version - take second-new version for update testing!!
### Tags: 20.08.2026 9:07 AM sha256-46869af272cd10dc08f6cd8c1d8cdd9b8906a64002b33e13c97a04b55be44efc
### Tags: 19.08.2026 5:37 PM sha256-4ccc34f3c655d55a213c5d0235f078fb6fbbfd41711ff9566c31d6efce8b14d6

echo
echo podman pull quay.io/hummingbird-community/bootc-os:sha256-46869af272cd10dc08f6cd8c1d8cdd9b8906a64002b33e13c97a04b55be44efc
podman pull quay.io/hummingbird-community/bootc-os:sha256-46869af272cd10dc08f6cd8c1d8cdd9b8906a64002b33e13c97a04b55be44efc

podman tag quay.io/hummingbird-community/bootc-os:sha256-46869af272cd10dc08f6cd8c1d8cdd9b8906a64002b33e13c97a04b55be44efc quay.io/hummingbird-community/bootc-os:mylatest 

## LOGIN LOCAL
echo
echo oc login --insecure-skip-tls-verify=true -u admin -p ADMIN_PW  https://api.cluster-${CLUSTERID}.dyn.redhatworkshops.io:6443
oc login --insecure-skip-tls-verify=true -u admin -p $ADMIN_PW  https://api.cluster-${CLUSTERID}.dyn.redhatworkshops.io:6443

echo
echo podman login --tls-verify=false -u kubeadmin -p $(oc whoami -t) image-registry.openshift-image-registry.svc:5000
podman login --tls-verify=false -u kubeadmin -p $(oc whoami -t) image-registry.openshift-image-registry.svc:5000
echo

## PUSH 
echo podman push --remove-signatures --tls-verify=false registry.redhat.io/rhel10/bootc-image-builder:10.2  image-registry.openshift-image-registry.svc:5000/openshift/bootc-image-builder:10.2
podman push --remove-signatures --tls-verify=false registry.redhat.io/rhel10/bootc-image-builder:10.2  image-registry.openshift-image-registry.svc:5000/openshift/bootc-image-builder:10.2
echo
echo podman push --remove-signatures --tls-verify=false registry.redhat.io/rhel10/rhel-bootc:10.2 image-registry.openshift-image-registry.svc:5000/openshift/rhel-bootc:10.2
podman push --remove-signatures --tls-verify=false registry.redhat.io/rhel10/rhel-bootc:10.2 image-registry.openshift-image-registry.svc:5000/openshift/rhel-bootc:10.2
echo
echo podman push --remove-signatures --tls-verify=false quay.io/hummingbird-community/bootc-os:mylatest image-registry.openshift-image-registry.svc:5000/openshift/bootc-os:mylatest
podman push --remove-signatures --tls-verify=false quay.io/hummingbird-community/bootc-os:mylatest image-registry.openshift-image-registry.svc:5000/openshift/bootc-os:mylatest


## CLEANUP
podman rmi -a -f
exit
podman logout registry.redhat.io
podman logout image-registry.openshift-image-registry.svc:5000
