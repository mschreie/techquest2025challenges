# RHEL 10 Image Mode (`bootc`) Workshop

Welcome to the hands-on workshop for **Red Hat Enterprise Linux 10 Image Mode (`bootc`)** on **OpenShift Virtualization**.

---

## Lab Modules

1. **[Lab 1: Build and Deploy a RHEL 10 Image Mode VM](01_BuildVM.md)**  
   Create a `bootc` container image from a `Containerfile`, convert it into a bootable QCOW2 virtual disk using `bootc-image-builder`, upload it to OpenShift, and launch your VM (`rhel10imagemode`).

2. **[Lab 2: Atomic Updates & Patching with `bootc`](02_UpdateVM.md)**  
   Perform declarative OS updates on your running Image Mode VM (`rhel10imagemode` or the `prep10imagemode` backup VM) by installing Apache (`httpd`), customizing your web page, and updating `/etc/motd` via `bootc upgrade`.

---

## Team Credentials

* **[Team Credentials Lookup](credentials.html)**  
  Enter your team number to retrieve your assigned **Cluster ID**, **User ID**, and **Password**.