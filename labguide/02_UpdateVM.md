# Atomic Updates & Patching with RHEL Image Mode (`bootc`)

[back](/)

## Overview: Updating an Image Mode VM

In traditional Linux administration, updating servers means SSH-ing into running machines, running `dnf install` or `dnf update`, editing configuration files in place, and hoping nothing drifts over time.

With **RHEL Image Mode (`bootc`)**, your entire operating system is managed like a cloud-native container:
* The OS root filesystem (`/usr`) is **immutable** (read-only).
* Every software installation or system configuration change happens declaratively inside a **`Containerfile`**.
* Updates are delivered **atomically** as container image layers using `bootc upgrade`, complete with instant, built-in **rollback**.

---

## Before You Start: Which VM Should You Use?

By now, you should have a RHEL 10 Image Mode VM ready in your OpenShift project (`mtv-$MYUID`):

* **Did you complete Lab 1?** Use the VM you built yourself: **`rhel10imagemode`**.
* **Did you get stuck or run out of time in Lab 1?** No problem at all! Use the pre-provisioned backup VM already sitting in your namespace: **`prep10imagemode`**. *(Remember: `prep10imagemode` is switched off by default to save cluster resources, so start it first if you haven't already.)*

> **Important:** Both `rhel10imagemode` and `prep10imagemode` start out as minimal RHEL 10 Image Mode systems **without a web server (`httpd`) installed**. In this lab, you will install Apache atomically by updating your container image!

### Set Your Target VM Variable

1. **On your laptop terminal**, set your credentials and choose which VM name you are using (`rhel10imagemode` or `prep10imagemode`):
   ```bash
   MYUID={userID}
   MYCID={clusterID}
   PROJECT="mtv-$MYUID"

   # Use "rhel10imagemode" if you finished Lab 1, or "prep10imagemode" if using the fallback VM:
   TARGET_VM="rhel10imagemode"
   ```

2. **If you are using `prep10imagemode`, start it now and wait for it to become Ready:**
   ```bash
   virtctl start "$TARGET_VM" -n "$PROJECT"
   oc wait --for=condition=Ready "vmi/$TARGET_VM" -n "$PROJECT" --timeout=5m
   ```

3. **Check your running VMs and their IP addresses:**
   ```bash
   oc get vmi -n "$PROJECT" -o wide
   ```

---

## Update 1: Install & Enable the Apache Web Server (`httpd`) Atomically

Because `/usr` is read-only on an Image Mode VM, you cannot run `dnf install httpd` inside `$TARGET_VM`. Instead, you will define the web server in your `Containerfile` on `thesource`, push the new image to the internal OpenShift registry, and let `bootc` deploy it.

### Step 1: Update the `Containerfile` on `thesource`

1. **Connect to your builder VM (`thesource`)** from your laptop:
   ```bash
   virtctl -n "$PROJECT" ssh -i ~/.ssh/id_techquest cloud-user@vmi/thesource
   ```

2. **Switch to `root`, enter the build directory, and set your variables**:
   ```bash
   sudo -i
   cd /root/rhel_image_mode-main

   MYUID={userID}
   MYCID={clusterID}
   PROJECT="mtv-$MYUID"
   ```

3. **Update `Containerfile`** to install `httpd`, enable the systemd service at boot, and create a custom `index.html` welcome page:
   ```bash
   cat << 'EOF' > Containerfile
   FROM image-registry.openshift-image-registry.svc:5000/openshift/rhel-bootc:10.2

   ADD etc /etc

   RUN dnf install -y httpd cloud-init qemu-guest-agent && \
       dnf clean all

   RUN sed -i -e '$aPermitRootLogin yes' /etc/ssh/sshd_config
   RUN systemctl enable httpd

   RUN echo "<h1>Welcome on the new image mode webserver!</h1>" > /var/www/html/index.html
   EOF
   ```

### Step 2: Build and Push the Updated Image

1. **Log in to OpenShift and the internal container registry**:
   ```bash
    oc login -u "$MYUID" "https://api.cluster-${MYCID}.dyn.redhatworkshops.io:6443"
   oc project "$PROJECT"

   oc whoami -t | podman login --tls-verify=false \
       -u "$(oc whoami)" --password-stdin \
       image-registry.openshift-image-registry.svc:5000
   ```

2. **Build the new container image and push it to your project registry**:
   ```bash
   podman build -f Containerfile -t localhost/myrhel10:latest .

   podman tag localhost/myrhel10:latest \
       "image-registry.openshift-image-registry.svc:5000/${PROJECT}/myrhel10:latest"

   podman push --tls-verify=false \
       "image-registry.openshift-image-registry.svc:5000/${PROJECT}/myrhel10:latest"
   ```

### Step 3: Apply the Atomic Upgrade on Your Image Mode VM

1. **From your laptop terminal**, connect via SSH to your target Image Mode VM (`rhel10imagemode` or `prep10imagemode`):
   ```bash
   virtctl -n "$PROJECT" ssh -i ~/.ssh/id_techquest "cloud-user@vmi/$TARGET_VM"
   ```

2. **Inside your Image Mode VM**, switch to `root` and inspect the current deployment before upgrading:
   ```bash
   sudo -i
   bootc status
   curl localhost || echo "No web server running yet!"
   ```
   Notice that `curl localhost` fails because `httpd` is not installed yet.

3. **Authenticate to the OpenShift internal registry** so `bootc` can pull your new image:
   ```bash
   MYUID={userID}
   MYCID={clusterID}
   PROJECT="mtv-$MYUID"

   oc login -u "$MYUID" "https://api.cluster-${MYCID}.dyn.redhatworkshops.io:6443"

   oc whoami -t | podman login --tls-verify=false \
       -u "$(oc whoami)" --password-stdin \
       image-registry.openshift-image-registry.svc:5000

   # Copy Podman credentials so bootc (ostree) can access the internal registry
   mkdir -p /etc/ostree
   cp /run/containers/0/auth.json /etc/ostree/auth.json
   chmod 600 /etc/ostree/auth.json
   ```

4. **Point `bootc` to your updated image (if using `prep10imagemode`) and run `bootc upgrade`:**
   * If you are on **`rhel10imagemode`** (already tracking `${PROJECT}/myrhel10:latest`):
     ```bash
     bootc upgrade
     ```
   * If you are on **`prep10imagemode`** (switch it to track your newly built image):
     ```bash
     bootc switch --transport registry "image-registry.openshift-image-registry.svc:5000/${PROJECT}/myrhel10:latest"
     ```

5. **Reboot into the new OS image**:
   ```bash
   systemctl reboot
   ```

### Step 4: Verify the Web Server and Rollback Capability

1. **Wait ~30 seconds, then reconnect to your VM** from your laptop:
   ```bash
   virtctl -n "$PROJECT" ssh -i ~/.ssh/id_techquest "cloud-user@vmi/$TARGET_VM"
   ```

2. **Verify `bootc status` and test Apache**:
   ```bash
   sudo bootc status
   systemctl is-active httpd
   curl -s localhost
   ```
   * `sudo bootc status` now shows your updated image under **`Booted image`** and your original image preserved under **`Rollback image`**!
   * `curl -s localhost` outputs: `<h1>Welcome on the new image mode webserver!</h1>`].

3. *(Optional)* Test from **`thesource`** using the VM's cluster or Multus IP (`oc get vmi -n "$PROJECT" -o wide`):
   ```bash
   curl http://<IP_OF_YOUR_IMAGEMODE_VM>
   ```

---

## Update 2: Customize the Message of the Day (`/etc/motd`)

Now that you have seen how cleanly `bootc` installs an entire service, try a second atomic update: adding a custom login banner (`/etc/motd`) for administrators.

1. **Back on `thesource` (`/root/rhel_image_mode-main`)**, append a custom `/etc/motd` to your `Containerfile`:
   ```bash
   cat << 'EOF' >> Containerfile

   RUN cat << 'MOTD' > /etc/motd
   =================================================================
     RHEL 10 Image Mode (bootc) - Managed Web Server
     All OS changes are immutable and version-controlled!
   =================================================================
   MOTD
   EOF
   ```

2. **Rebuild and push** the updated image to the internal registry:
   ```bash
   podman build -f Containerfile -t localhost/myrhel10:latest .
   podman tag localhost/myrhel10:latest \
       "image-registry.openshift-image-registry.svc:5000/${PROJECT}/myrhel10:latest"
   podman push --tls-verify=false \
       "image-registry.openshift-image-registry.svc:5000/${PROJECT}/myrhel10:latest"
   ```

3. **Upgrade and reboot** your Image Mode VM (`$TARGET_VM`):
   ```bash
   virtctl -n "$PROJECT" ssh -i ~/.ssh/id_techquest "cloud-user@vmi/$TARGET_VM" \
       -c "sudo bootc upgrade && sudo systemctl reboot"
   ```

4. **Reconnect via SSH** and see your new Message of the Day banner appear right upon login:
   ```bash
   virtctl -n "$PROJECT" ssh -i ~/.ssh/id_techquest "cloud-user@vmi/$TARGET_VM"
   ```

---

## Slide Recap: Why RHEL Image Mode (`bootc`) Changes Everything

| Capability | Traditional Package Mode (`dnf`) | RHEL Image Mode (`bootc`) |
| :--- | :--- | :--- |
| **Source of Truth** | Imperative shell scripts, manual edits, config drift | Declarative `Containerfile` stored in Git |
| **OS & Apps Delivery** | Separate OS patching and application deployment | Unified, tested OCI container image |
| **Immutability** | Writable `/usr`; accidental changes break consistency | Read-only `/usr`; predictable behavior across all VMs |
| **Updates & Patching** | `dnf update` on live systems (risk of partial state) | Atomic `bootc upgrade` + clean reboot |
| **Recovery / Rollback** | Complex LVM snapshots or painful manual downgrades | Instant one-command rollback (`sudo bootc rollback`) |



## OLD CONTENT

# Update an existing RHEL 10 Image Mode - VM

[back](/)

## The Ask - in short
Change sth in the container image by changing the Containerfile and building a new image. Upload this image to the same location as the previous and use this image as an update to your existing image mode VM.
This exersize can be fullfilled by eitehr using the VM you built in the previous step or take the one we prepared for you (rhel10imagemode)


You can find the ip-addresses of your VMs like this:
oc get vmi -n mtv-user1 -o wide

connect to the VM "thesource" and ask your webserver of rhel10imagemode  - it should provide the default welcome message apache webservers provide

Now let your webserver provide your personal greeting:
Patch your imagemode server by adding a file
/var/www/html/index.html
Welcome on the new image mode webserver!


SOLUTION
* alter/update Containerfile
vi ....
* run container build
podman build -f Containerfile -t myrhel10:latest
* push to registry
podman tag myrhel10:latest image-registry.openshift-image-registry.svc:5000/mtv-user1/myrhel10:latest
podman push image-registry.openshift-image-registry.svc:5000/mtv-user1/myrhel10:latest

on the rhel10imagemode VM:
* login to registry .... 
	* oc needed
~/bin/oc login -u user1 -p knNVx57U7izN0P1d https://api.cluster-dn94p.dyn.redhatworkshops.io:6443
podman login --tls-verify=false -u $(~/bin/oc whoami) -p $(~/bin/oc whoami -t) image-registry.openshift-image-registry.svc:5000

* make that login work for bootc command
cp /run/containers/0/auth.json /etc/ostree/auth.json
chmod 600 /etc/ostree/auth.json
bootc upgrade

last step not
systemctl reboot

thereafter:
cloud-user@rhel10imagemode ~]$ sudo bootc status
● Booted image: image-registry.openshift-image-registry.svc:5000/mtv-user1/myrhel10
        Digest: sha256:dd4282060546b3b50d8fac398268f6a03d4f7189df0669e308ac104f485f257a (amd64)
       Version: 10.2 (2026-08-20T14:09:15Z)

  Rollback image: image-registry.openshift-image-registry.svc:5000/mtv-user1/myrhel10
          Digest: sha256:c6f803aa592bb45629b7c44a937cc33aa20d71a11aa6e6c1467d854ae5c6f96a (amd64)
         Version: 10.2 (2026-08-20T14:09:15Z)
   UpdateVersion: 10.2 (2026-08-20T14:09:15Z)
    UpdateDigest: sha256:dd4282060546b3b50d8fac398268f6a03d4f7189df0669e308ac104f485f257a
[cloud-user@rhel10imagemode ~]$ 
... but webserver did not show index.html
