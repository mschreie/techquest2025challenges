# Now for Summit connect 2026

This is the repo for an Imagre mode lab offered at Red Hat Summit Connect 2026 in Darmstadt. 

This document describes what to do to get it set up..


Order on demo.redhat.com 
"Experience OpenShift Virtualization Roadshow"

I did that via Slack channel.

You need to provide the credentails to the participants. Mayb by creating a web-server on the demo platform and provide a short-url to that webserver?


## For the RHEL Image mode preparation:
You find a desciption of how it works elsewere:
Guide form a RHEL 9 image mode lab (for reference)
https://docs.google.com/document/d/1TyfZU9dDDPCga2KFfNmyxOZK2aOLtQkdPlZ0a-MUldM/edit?tab=t.0#heading=h.kxfk46hu6ley

The Fedora Humingbird Liunx anouncement:
https://www.redhat.com/en/about/press-releases/fedora-hummingbird-linux-brings-agentic-linux-builders
and a description / how to:
https://fedoramagazine.org/fedora-hummingbird-linux-taking-the-hummingbird-model-to-the-full-os/
And a download link:
https://quay.io/repository/hummingbird-community/bootc-os

### For the management VM (from where all the work is done):
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
The blueprint within image-builder is called: irhel-10-x86_64-10232025-1241 images.
If you do not find the blueprint in the portal, you might want to upload the blueprint out of this repository from 
	imagebuilder-blueprint/rhel-10-x86_64-20251229.json
You need to build the image as they expire after a couple of hours:
https://console.redhat.com/insights/image-builder
=> Inventory
=> Image Builder
=> BluePrints
RHEL 10 host version 6 (or above)

### Build Image 

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
type yes 20 times. The script should do the rest.
bash 03_create_utilVM.sh

### ensure bootc-image-builder image and bootc image to be available:
this is done through the script prepRegistry.sh on one of the VMs in each cluster.

and this script is executed_ from 03_create_utilVM.sh
so there is no additional todo
