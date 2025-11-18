This is the repo for two Challenges offered at Red Hat Summit Connect 2025 in Darmstadt. 
The Tool and Entry Point is Catch the Flag Interface "https://red-hat-summit-connect-hands-on-day-2025.ctfd.io/"

This document describes wht to do to get it set up..

The Challenges are integrated into CTF
https://red-hat-summit-connect-hands-on-day-2025.ctfd.io/login
demo-user-1
demo


Both challanges use the same demon environment but different Projects / Namespaces:

Order on demo.redhat.com 
"Experience OpenShift Virtualization Roadshow"

I did that via Slack channel.

You need to feeed the credentails. I got a Webinterface from Marco Klaassen, who sets it up correctly.


For the RHEL Image mode challenge preparation:
You find a desciption of how it works elsewere here:
Guide form a RHEL 9 image mode lab (for reference)
https://docs.google.com/document/d/1TyfZU9dDDPCga2KFfNmyxOZK2aOLtQkdPlZ0a-MUldM/edit?tab=t.0#heading=h.kxfk46hu6ley



* Create a package based RHEL image with at least the following packages:
- podman
- qemu-guest-agent
- cloud-init
i also added (for convenience):
- bash-color-pompt
- buildah
- podman-docker
- podman-remote
- vim-common
- vim-data
- vim-enhanced
The blueprint within image-builder is called: irhel-10-x86_64-10232025-1241 images
You need to build the image as they expire after a couple of hours:
https://console.redhat.com/insights/image-builder
=> Inventory
=> Image Builder
=> BluePrints
RHEL 10 host version 6 (or above)

## Build Image 

build and prepare "normal" RHEL 10 VMs via cmd line 
on my MAC:
cd /Users/mschreie/projects/techquest2025challenges

edit env.sh
define the Custer  ID
set admin password
update the Image URL with the image you just created in the image-builder
run 

bash 01_create_vms.sh
bash 02_ssh_prep_vms.sh
type yes 20 times . the script should do the rest

## ensure bootc-image-builder image and bootc image to be available:
login to one VM:
virtctl -n mtv-userX ssh -i ~/.ssh/id_techquest cloud-user@vmi/thesource
podman login registry.redhat.io

podman pull registry.redhat.io/rhel10/bootc-image-builder:10.0
podman pull registry.redhat.io/rhel10/rhel-bootc:10.0


oc login --insecure-skip-tls-verify=false -u admin -p z0dJ4znJo1JJaxPu https://api.cluster-f78pb.dynamic.redhatworkshops.io:6443

podman login --tls-verify=false -u kubeadmin -p $(oc whoami -t) image-registry.openshift-image-registry.svc:5000

podman push --remove-signatures --tls-verify=false registry.redhat.io/rhel10/bootc-image-builder:10.0  image-registry.openshift-image-registry.svc:5000/openshift/bootc-image-builder:10.0 

podman push --remove-signatures --tls-verify=false registry.redhat.io/rhel10/rhel-bootc:10.0 image-registry.openshift-image-registry.svc:5000/openshift/rhel-bootc:10.0
 


## cleanup:
podman rmi registry.redhat.io/rhel10/bootc-image-builder:10.0
podman rmi registry.redhat.io/rhel10/rhel-bootc:10.0

podman logout
podman logout image-registry.openshift-image-registry.svc:5000
