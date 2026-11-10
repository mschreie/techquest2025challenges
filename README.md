# RHEL image mode lab

This repository is the image mode lab for Red Hat Summit Connect 2026 in Darmstadt. It builds on "Experience OpenShift Virtualization Roadshow (2026)" from the Red Hat demo platform.

Order that offering on demo.redhat.com. Request more than one cluster through the Slack channel. A cluster for about 20 participants works for about 14 people practicing image mode.

Each participant uses a classic RHEL VM, `thesource`, to build an image mode VM and later update it. A separate `util` VM on each cluster serves the lab guide. Files in the local `labguide/` directory are published to that web server.

## Build the participant image

Create a package-based RHEL image in Image Builder with at least:

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

The blueprint in this repository is `imagebuilder-blueprint/rhel-10-x86_64-20251229.json`. Upload it in the console if it is not already there:

https://console.redhat.com/insights/image-builder

Use RHEL 10 host version 6 or newer. Built images expire after a few days, so create a fresh image and copy its URL before preparing the clusters.

## Prepare the clusters

Cluster ids, admin passwords, the image URL, and the Red Hat subscription settings are described in [ansible/README.md](ansible/README.md). That guide is the procedure for logging in and preparing every cluster.

## References

- RHEL 9 image mode lab notes: https://docs.google.com/document/d/1TyfZU9dDDPCga2KFfNmyxOZK2aOLtQkdPlZ0a-MUldM/edit
- Fedora Hummingbird Linux announcement: https://www.redhat.com/en/about/press-releases/fedora-hummingbird-linux-brings-agentic-linux-builders
- How Hummingbird applies the model to a full OS: https://fedoramagazine.org/fedora-hummingbird-linux-taking-the-hummingbird-model-to-the-full-os/
- Hummingbird images: https://quay.io/repository/hummingbird-community/bootc-os
