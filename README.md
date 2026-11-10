# RHEL image mode lab

This repository is the image mode lab for Red Hat Summit Connect 2026 in Darmstadt. It builds on "Experience OpenShift Virtualization Roadshow (2026)" from the Red Hat demo platform.

Order that offering on demo.redhat.com. Request more than one cluster through the Slack channel. A cluster for about 20 participants works for about 14 people practicing image mode.

Each participant uses a classic RHEL VM, `thesource`, to build an image mode VM and later update it. A separate `util` VM on each cluster serves the lab guide. Files in the local `labguide/` directory are published to that web server.

We will also provide an image mode vm, so a participant can continue with the update task, even if the build task did not work out or takes longer as expected.

## Build the qcow disk images for the 2 participant VMs (thesource and imagemode)

Use image bulder, which is found here: https://console.redhat.com/insights/image-builder
Upload the image definitions found in this repo under files/

files/rhel-10-x86_64-20261110.json
files/rhel-10-x86_64-imagemode-20261110.json

and build the two images. This takes a moment.

For your information:
In both qcow image definitions:

Includes:
- podman
- qemu-guest-agent
- cloud-init

Also useful:

- bash-color-prompt
- buildah
- podman-docker
- podman-remote
- vim-common
- vim-data
- vim-enhanced

Only in the "thesource" image:
Only in the "imagemode" image:


Built images expire after a few days, so create fresh images and copy the URLs before preparing the clusters.
Ensure the URLs of the images are not swapped! 

## Prepare the clusters

Cluster ids, admin passwords, the image URL, and the Red Hat subscription settings are described in [ansible/README.md](ansible/README.md). That guide is the procedure for logging in and preparing every cluster.

## References

- RHEL 9 image mode lab notes: https://docs.google.com/document/d/1TyfZU9dDDPCga2KFfNmyxOZK2aOLtQkdPlZ0a-MUldM/edit
- Fedora Hummingbird Linux announcement: https://www.redhat.com/en/about/press-releases/fedora-hummingbird-linux-brings-agentic-linux-builders
- How Hummingbird applies the model to a full OS: https://fedoramagazine.org/fedora-hummingbird-linux-taking-the-hummingbird-model-to-the-full-os/
- Hummingbird images: https://quay.io/repository/hummingbird-community/bootc-os
