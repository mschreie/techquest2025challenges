# Atomic Updates & Patching with RHEL Image Mode (`bootc`)

[back](/)

## Overview: Updating an Image Mode VM

In traditional Linux administration, updating servers means SSH-ing into running machines, running `dnf install` or `dnf update`, editing configuration files in place, and hoping nothing drifts over time.

With **RHEL Image Mode (`bootc`)**, your entire operating system is managed like a cloud-native container:

* The OS root filesystem (`/usr`) is **immutable** (read-only).
* Every software installation or system configuration change happens declaratively inside a **`Containerfile`**.
* Updates are delivered **atomically** as container image layers using `bootc upgrade`, complete with instant, built-in **rollback**.

---

## Before you start: Where are you comming from?
Have you done [Exersice 1](01_BuildVM.md) already?  
In this case you have logged in to OpenShift and to the `thesource` VM.  
If you did not please run through steps 2. to 7. in [Exersice 1](01_BuildVM.md) to login and prepare your environment and then come back here

## Before You Start: Which VM Should You Use?

By now, you should have a RHEL 10 Image Mode VM ready in your OpenShift project (`mtv-$MYUID`):

* **Did you complete Lab 1?** Use the VM you built yourself: **`rhel10imagemode`**.
* **Did you get stuck or run out of time in Lab 1?** No problem at all! Use the pre-provisioned backup VM already sitting in your namespace: **`prep10imagemode`**. *(Remember: `prep10imagemode` is switched off by default to save cluster resources, so start it first if you haven't already (see below).)*

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

## Update 1: Customize the Message of the Day (`/etc/motd`)

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

3. Alter your containerfile by appending a custom `/etc/motd`:
   ```bash
   cat << 'EOF' >> Containerfile

   RUN tee -a /etc/motd  << 'MOTD'
   =================================================================
     RHEL 10 Image Mode (bootc) - Managed Web Server
     All OS changes are immutable and version-controlled!
   =================================================================
   MOTD
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
   ```

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

4. **Point `bootc` to your updated image (if using `prep10imagemode`) or run `bootc upgrade`:**
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

### Step 4: Verify the motd change and Rollback Capability

1. **Wait ~30 seconds, then reconnect to your VM** from your laptop:
   ```bash
   virtctl -n "$PROJECT" ssh -i ~/.ssh/id_techquest "cloud-user@vmi/$TARGET_VM"
   ```

2. **Verify `bootc status` and view motd**:
   ```bash
   sudo bootc status
   sudo -i
   cat /etc/motd
   ```
   * `sudo bootc status` now shows your updated image under **`Booted image`** and your original image preserved under **`Rollback image`**!
   * `sudo -i` should print the new message we defined.
   * `cat /etc/motd` will show that exact same message once more.

---

## Update 2: Install & Enable the Apache Web Server (`httpd`) Atomically

Now that you have seen how `bootc` updates OS and OS configuration, try a second atomic update: adding a web service.

Because `/usr` is read-only on an Image Mode VM, you cannot run `dnf install httpd` inside `$TARGET_VM`. Instead, you will define the web server in your `Containerfile` on `thesource`, push the new image to the internal OpenShift registry, and let `bootc` deploy it.

1. **Back on `thesource` (`/root/rhel_image_mode-main`)**, Update `Containerfile` to install `httpd`, enable systemd service at boot, and create a custom `index.html` welcome page:
   ```bash
   tee Containerfile << 'EOF' 
   FROM image-registry.openshift-image-registry.svc:5000/openshift/rhel-bootc:10.2

   ADD etc /etc

   RUN dnf install -y httpd cloud-init qemu-guest-agent && \
       dnf clean all

   RUN sed -i -e '$aPermitRootLogin yes' /etc/ssh/sshd_config
   RUN systemctl enable httpd

   RUN echo "<h1>Welcome on the new image mode webserver!</h1>" > /var/www/html/index.html

   RUN tee -a /etc/motd  << 'MOTD'
   =================================================================
     RHEL 10 Image Mode (bootc) - Managed Web Server
     All OS changes are immutable and version-controlled!
   =================================================================
   MOTD
   EOF
   ```
   Hint: While with tee (or cat respectively) we can accidentally overwrite earlier changes. In real life we would apply a diff (a patch) to ensure only intended change are made.

2. **Rebuild and push** the updated image to the internal registry:
   ```bash
   podman build -f Containerfile -t localhost/myrhel10:latest .
   podman tag localhost/myrhel10:latest \
       "image-registry.openshift-image-registry.svc:5000/${PROJECT}/myrhel10:latest"
   podman push --tls-verify=false \
       "image-registry.openshift-image-registry.svc:5000/${PROJECT}/myrhel10:latest"
   ```

3. Inspect the current deployment before upgrading your Image Mode VM ($TARGET_VM): 
   ```bash
   virtctl -n "$PROJECT" ssh -i ~/.ssh/id_techquest "cloud-user@vmi/$TARGET_VM" \
       -c "sudo bootc status && curl localhost || echo "No web server running yet!"
   ```
   Notice that `curl localhost` fails because `httpd` is not installed yet.

4. Upgrade and reboot your Image Mode VM ($TARGET_VM):
   ```bash
   virtctl -n "$PROJECT" ssh -i ~/.ssh/id_techquest "cloud-user@vmi/$TARGET_VM" \
       -c "sudo bootc upgrade && sudo systemctl reboot"
   ```

5. **Reconnect via SSH** and check webservice
   ```bash
   virtctl -n "$PROJECT" ssh -i ~/.ssh/id_techquest "cloud-user@vmi/$TARGET_VM" \
       -c "sudo bootc status && systemctl is-active httpd && curl -s localhost"
   ```

   * `sudo bootc status` now shows your updated image under **`Booted image`** and your original image preserved under **`Rollback image`**!
   * `curl -s localhost` outputs: `<h1>Welcome on the new image mode webserver!</h1>`].

6. *(Optional)* Test from **`thesource`** using the VM's cluster or Multus IP (`oc get vmi -n "$PROJECT" -o wide`):
   ```bash
   curl http://<IP_OF_YOUR_IMAGEMODE_VM>
   ```


---

## Slide Recap: Why RHEL Image Mode (`bootc`) Changes Everything

| Capability | Traditional Package Mode (`dnf`) | RHEL Image Mode (`bootc`) |
| :--- | :--- | :--- |
| **Source of Truth** | Imperative shell scripts, manual edits, config drift | Declarative `Containerfile` stored in Git |
| **OS & Apps Delivery** | Separate OS patching and application deployment | Unified, tested OCI process, can be one or disjoint container images |
| **Immutability** | Writable `/usr`; accidental changes break consistency | Read-only `/usr`; predictable behavior across all VMs |
| **Updates & Patching** | `dnf update` on live systems (risk of partial state) | Atomic `bootc upgrade` + clean reboot |
| **Recovery / Rollback** | Complex LVM snapshots or painful manual downgrades | Instant one-command rollback (`sudo bootc rollback`) |
