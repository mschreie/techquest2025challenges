# TechQuest 2025 / Summit Connect Darmstadt - Lab Automation & Challenge Guide

This repository contains the dynamic Ansible playbooks and challenge documentation for provisioning, validating, and tearing down the **RHEL 10 Image Mode** and **OpenShift Virtualization** workshop environments.

---

## Architecture & Dynamic Configuration

The workshop automation is fully dynamic and decoupled from hardcoded cluster IDs or static user counts. All playbooks discover their runtime targets by inspecting environment variables defined in `./env.sh`:

- **Cluster Resolution**: Reads `MULTICLUSTERID` (or `MUTLICLUSTERID`) and targets the first cluster listed or `TARGET_CLUSTER`.
- **Scaling / Participant Count**: Reads `MAXUSERS` (or `MAXUSER`) and constructs participant namespace ranges (`mtv-user1` through `mtv-userN`) dynamically.
- **Safety Assertions**: All playbooks verify that the active OpenShift session (`oc whoami --show-server`) matches `https://api.cluster-${cluster_id}.dyn.redhatworkshops.io:6443` and that the connected identity is `admin`.
- **Isolated SSH Host Identification**: `virtctl ssh/scp` commands store host keys in a dedicated per-cluster file (`~/.ssh/kubevirt_known_hosts-${cluster_id}`) to prevent collision across multiple clusters.

---

## Prerequisites & Environment Setup

Ensure Ansible and the command-line tools (`oc`, `virtctl`) are available in your path:

```bash
export PATH="$PWD/..:$HOME/.venvs/techquest-ansible/bin:$PATH"
source ./env.sh
```

Ensure your SSH private key has the appropriate permissions:

```bash
chmod 400 ~/.ssh/id_techquest
```

Authenticate your CLI session against the target cluster as `admin`:

```bash
ansible-playbook -i 'localhost,' -c local ansible/login.yml
```

---

## Organizer Workflow: Step-by-Step Cluster Provisioning

Run all playbooks from the repository root using the local inventory:

```bash
ansible-playbook -i 'localhost,' -c local ansible/<playbook_name>.yml
```

### 1. Provision Base Participant VMs (`thesource`)
Provisions the initial management VM `thesource` in each participant namespace (`mtv-user1` ... `mtv-userN`) importing from `$IMAGEBUILDERURL`:
```bash
ansible-playbook -i 'localhost,' -c local ansible/create_thesource.yml
```

### 2. Populate Workspaces and CLI Binaries
Uploads `files/rhel_image_mode-main.zip`, extracts the lab assets into `/root/rhel_image_mode-main`, and installs `oc` and `virtctl` into `/usr/local/bin`:
```bash
ansible-playbook -i 'localhost,' -c local ansible/prepare_thesource.yml
```

### 3. Attach Secondary Network to Participant Workspaces
Applies the `flatnetwork` NetworkAttachmentDefinition (macvlan over `br-ex`, `192.168.113.0/24`) and patches the `nic-flat` bridge interface into `thesource`:
```bash
ansible-playbook -i 'localhost,' -c local ansible/configure_multus.yml
```

### 4. Configure Registry Access & Red Hat Subscriptions
Configures `/etc/containers/registries.conf.d/99-openshift-internal.conf` on each `thesource` VM and registers instances with Red Hat Subscription Manager using `rhsm_org_id` and `rhsm_activation_key`:
```bash
ansible-playbook -i 'localhost,' -c local ansible/configure_thesource.yml
```

### 5. Deploy the Utility Server (`util`)
Creates the `util` VM in the `default` namespace, starts Apache (`httpd`), and exposes the HTTP service via an OpenShift edge Route:
```bash
ansible-playbook -i 'localhost,' -c local ansible/prepare_util.yml
```

### 6. Publish the Workshop Guide & Credentials
Validates participant credentials against `labguide/credentials.yaml` and copies the HTML guide to `/var/www/html` on `util`:
```bash
ansible-playbook -i 'localhost,' -c local ansible/publish_labguide.yml
```
*Verification:*
```bash
ROUTE_URL=$(oc get route httpd -n default -o jsonpath='{"https://"}{.spec.host}{"\n"}')
curl -kI "$ROUTE_URL"
```

### 7. Power On and Assert VM Readiness
Powers on any stopped VM instances across all namespaces and asserts that `util` and all `thesource` instances report `Running` phase and `Ready: True`:
```bash
ansible-playbook -i 'localhost,' -c local ansible/start_prep_vms.yml
ansible-playbook -i 'localhost,' -c local ansible/check_vms.yml
```

### 8. (Optional) Populate Internal Registry Base Images
If the base container images are missing from the shared `openshift` project:
```bash
ansible-playbook -i 'localhost,' -c local ansible/prepare_registry.yml
```
*(Prompts for Red Hat Registry service-account credentials and mirrors `rhel-bootc:10.2` and `bootc-image-builder:10.2`).*

---

## Post-Challenge Configuration: Image Mode Multus

Once participants complete their build and launch their `rhel10imagemode` VMs, configure secondary network attachment dynamically across all participant namespaces:

```bash
ansible-playbook -i 'localhost,' -c local ansible/configure_imagemode_multus.yml
```
*Note: This playbook inspects each namespace idempotently and skips any participant who has not yet launched `rhel10imagemode`.*

---

## Participant Walkthrough: RHEL 10 Image Mode Challenge

### Step 1: Connect to the Workspace
```bash
virtctl -n mtv-user1 ssh -i ~/.ssh/id_techquest cloud-user@vmi/thesource
```
Switch to root and enter the workspace directory:
```bash
sudo -i
cd /root/rhel_image_mode-main
```

### Step 2: Authenticate to OpenShift & Registry
```bash
MYUID=user1
MYCID=$(oc whoami --show-server | sed -E 's/.*cluster-([^.]+)\..*/\1/')
PROJECT="mtv-$MYUID"

oc login -u "$MYUID" "https://api.cluster-${MYCID}.dyn.redhatworkshops.io:6443"
oc project "$PROJECT"

oc whoami -t | podman login --tls-verify=false \
    -u "$(oc whoami)" --password-stdin \
    image-registry.openshift-image-registry.svc:5000
```

### Step 3: Build & Push the Bootable Container Image
```bash
podman build -f Containerfile -t localhost/myrhel10:latest .
podman tag localhost/myrhel10:latest "image-registry.openshift-image-registry.svc:5000/${PROJECT}/myrhel10:latest"
podman push --tls-verify=false "image-registry.openshift-image-registry.svc:5000/${PROJECT}/myrhel10:latest"
```

### Step 4: Convert Bootc Container to QCOW2 Disk
```bash
podman run --rm --tls-verify=false --privileged \
    --volume "$PWD/output:/output" \
    --volume "$PWD/config.json:/config.json" \
    --volume /var/lib/containers/storage:/var/lib/containers/storage \
    image-registry.openshift-image-registry.svc:5000/openshift/bootc-image-builder:10.2 \
    --type qcow2 --config /config.json \
    "image-registry.openshift-image-registry.svc:5000/${PROJECT}/myrhel10:latest" \
    --output /output
```

### Step 5: Upload Disk & Launch the Virtual Machine
```bash
# Upload DataVolume
virtctl image-upload dv rhel10image --size=12Gi \
    --image-path=output/qcow2/disk.qcow2 \
    --storage-class=ocs-external-storagecluster-ceph-rbd \
    --insecure --force-bind

# Encode cloud-init user data
CLOUD_INIT_USERDATA=$(base64 -w 0 cloud.init.txt)

# Launch VM
virtctl create vm --instancetype u1.small --name rhel10imagemode \
    --volume-import "type:pvc,src:${PROJECT}/rhel10image,name:rhel10imagemode" \
    --cloud-init configdrive \
    --cloud-init-user-data "$CLOUD_INIT_USERDATA" |
    oc create -f - -n "$PROJECT"

oc wait --for=condition=Ready vmi/rhel10imagemode -n "$PROJECT" --timeout=10m
```

### Step 6: Verify the Running Image Mode Instance
From your bastion or local host:
```bash
virtctl -n mtv-user1 ssh -i ~/.ssh/id_techquest cloud-user@vmi/rhel10imagemode
```
Inside `rhel10imagemode`:
```bash
sudo bootc status
curl localhost
```

### Step 7: Performing a Bootc Upgrade
1. In `thesource`, edit `Containerfile` (e.g., customize `/var/www/html/index.html`).
2. Rebuild and push to `image-registry.openshift-image-registry.svc:5000/${PROJECT}/myrhel10:latest`.
3. In `rhel10imagemode`, execute:
   ```bash
   sudo bootc upgrade
   sudo systemctl reboot
   ```
4. Verify changes after reboot:
   ```bash
   sudo bootc status
   curl localhost
   ```

---

## Teardown & Environment Reset

`ansible/cleanup_lab.yml` unregisters Red Hat subscriptions, releases disk locks, strips Kubernetes storage protection finalizers, and deletes VMs, DataVolumes, PVCs, secrets, and routes.

### Dry Run (Inspection Mode)
Inspects active subscriptions and planned deletion targets without destroying any resources:
```bash
ansible-playbook -i 'localhost,' -c local ansible/cleanup_lab.yml
```

### Confirmed Teardown
To perform a complete cluster reset:
```bash
ansible-playbook -i 'localhost,' -c local ansible/cleanup_lab.yml -e "confirm_cleanup=true"
```
