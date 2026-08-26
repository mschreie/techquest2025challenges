# RHEL image mode - LAB


This is the repo provides an Image mode lab offered at Red Hat Summit Connect 2026 in Darmstadt. 
It build on "Experience OpenShift Virtualization Roadshow (2026)" from the Red Hat Demo platform.

This document describes what to do to get it set up.


Order on demo.redhat.com 
"Experience OpenShift Virtualization Roadshow (2026)"

You need to do that via Slack channel if you want more than one cluster. Roughly a 20 participants cluster works for 14 participants practicing the image mode. 

We also create a "util" VM which hosts a webserver to provide the lab guide and any additonal infos needed.
Anything you store in the local labguide directory will be available via that webserver. 


## Some references:
You find a desciption of how it works elsewere:
Guide form a RHEL 9 image mode lab (for reference)
https://docs.google.com/document/d/1TyfZU9dDDPCga2KFfNmyxOZK2aOLtQkdPlZ0a-MUldM/edit?tab=t.0#heading=h.kxfk46hu6ley

The Fedora Humingbird Liunx anouncement:
https://www.redhat.com/en/about/press-releases/fedora-hummingbird-linux-brings-agentic-linux-builders
and a description / how to:
https://fedoramagazine.org/fedora-hummingbird-linux-taking-the-hummingbird-model-to-the-full-os/
And a download link:
https://quay.io/repository/hummingbird-community/bootc-os

## How it works:
Every participant has acces to a classic RHEL VM from where an image mode VM is built and in a later step updated.

## Preparation
### For the management VM (from where all the work is done):
* Create a package based RHEL image with at least the following packages:
- podman
- qemu-guest-agent
- cloud-init
also added (for convenience):
- bash-color-pompt
- buildah
- podman-docker
- podman-remote
- vim-common
- vim-data
- vim-enhanced
The blueprint within image-builder is called: rhel-10-x86_64-10232025-1241 images.
If you do not find the blueprint in the portal, you might want to upload the blueprint out of this repository from 
	imagebuilder-blueprint/rhel-10-x86_64-20251229.json
You need to build the image as they expire after a couple of days:
https://console.redhat.com/insights/image-builder
=> Inventory
=> Image Builder
=> BluePrints
RHEL 10 host version 6 (or above)

### Build Image 

build and prepare "normal" RHEL 10 VMs via cmd line 
on your local MAC within the directory where this repo got downloaded to:
cd /Users/mschreie/projects/techquest2025challenges

edit env.sh
define the Cluster  IDs
set admin passwords
update the Image URL with the image you just created in the image-builder
run 
`bash 00_login.sh
bash 01_create_vms.sh
bash 02_ssh_prep_vms.shi`
type yes 20 times. The script should do the rest.
`bash 03_create_utilVM.sh`
The script 03_create_utilVM.sh creates an additonal "util" VM to host the documentation and copies and executes prepRegistry.sh on that host which loads bootc images into local OpenShift registry, to avoid access issues.

For initial upload or any lab guide change run.
`bash 10_UpdateLabGuide`


