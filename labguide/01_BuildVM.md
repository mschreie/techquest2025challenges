# Create a new RHEL 10 Image Mode - VM

Category: Red Hat Enterprise Linux


## The Ask - in short
You need to create a bootc container image for a new VM which needs to be uploaded in local registry. For the initial boot, you need to transfer it into a qcow2 image, upload that into OCP-V from which you create a image mode based VM.

## Preparation
You need a command line interface which is ssh capable. There you need `virtctl` and  `oc` bindary. If you do not have these binary  commands,  you can download them from :  
https://console-openshift-console.apps.cluster-${MYCID}.dyn.redhatworkshops.io/command-line-tools (login with your userX as found further down) and add them in some directoy which is searched by your PATH -settings.  

As our environment does not have officially signed certificates you might need 
`--tls-verify=false` added to your commands pulling or pushing sth to a registry or repository.  

Also use the following **private ssh-key** to login:
    cat ~/.ssh/id_techquest    
    -----BEGIN OPENSSH PRIVATE KEY-----    
    b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAMwAAAAtzc2gtZW   
    QyNTUxOQAAACDT23/KeynsmCI93ihJG773WeN5UxWoajiGQaG17HtsGgAAAJBDOwwiQzsM   
    IgAAAAtzc2gtZWQyNTUxOQAAACDT23/KeynsmCI93ihJG773WeN5UxWoajiGQaG17HtsGg   
    AAAED9EEPysOPApFPSUNPJa+IXQoihG24ld2nnM/hCeQnWbNPbf8p7KeyYIj3eKEkbvvdZ   
    43lTFahqOIZBobXse2waAAAADXRlY2hxdWVzdDIwMjU=   
    -----END OPENSSH PRIVATE KEY-----   
In most environments this file should consist of 3 lines with no additional whitespaces. In most environments you need to change the file attrributes to 400   
`chmod 400 ~/.ssh/id_techquest`

## Login
In the following a capital X stands for your Group Number.  
To receive all user-specific information type your team ID into https://red.ht/ctfd-2025-cred-virt    
This should provide a URL wich includes a individual identity string. This string is the `cluster id`used later. You will also find a Username and a password.          
## Build and create the Image Mode VM

Run the following commands **inside `thesource`**, as `root`, in `/root/rhel_image_mode-main`. Replace `user1` if your assigned username is different. Set the project once:

```bash
MYUID=user1
MYCID=mpfcp
PROJECT="mtv-$MYUID"
cd /root/rhel_image_mode-main
```

### 1. Log in to the cluster and internal registry (Cost 1)

The OpenShift login on your computer is not shared with `thesource`. Log in again inside the VM. `oc login` prompts for your password:

```bash
oc login -u "$MYUID" "https://api.cluster-${MYCID}.dyn.redhatworkshops.io:6443"
oc project "$PROJECT"
oc whoami
```

Log in Podman to the cluster's internal registry using the token from that `oc` session:
In the following a capital X stands for your Group Number.  
To receive all user-specific information type your team ID into https://red.ht/ctfd-2025-cred-virt    
This should provide a URL wich includes a individual identity string. This string is the `cluster id`used later. You will also find a Username and a password.          

## Build and create the Image Mode VM

Run the following commands **inside `thesource`**, as `root`, in `/root/rhel_image_mode-main`. Replace `user1` if your assigned username is different. Set the project once:

```bash
MYUID=user1
MYCID=mpfcp
PROJECT="mtv-$MYUID"
cd /root/rhel_image_mode-main
```

### 1. Log in to the cluster and internal registry (Cost 1)

The OpenShift login on your computer is not shared with `thesource`. Log in again inside the VM. `oc login` prompts for your password:

```bash
oc login -u "$MYUID" "https://api.cluster-${MYCID}.dyn.redhatworkshops.io:6443"
oc project "$PROJECT"
oc whoami
```

Log in Podman to the cluster's internal registry using the token from that `oc` session:

```bash
oc whoami -t | podman login --tls-verify=false \
    -u "$(oc whoami)" --password-stdin \
    image-registry.openshift-image-registry.svc:5000
```

`oc login` authenticates the CLI. `podman login` separately authenticates Podman to the image registry.

### 2. Build the bootc image (Cost 3)

The first line of `Containerfile` must use the bootc base image copied to the cluster's internal registry:

```dockerfile
FROM image-registry.openshift-image-registry.svc:5000/openshift/rhel-bootc:10.2
```

Check it, then build from the current directory (`.`):

```bash
grep '^FROM ' Containerfile
podman build -f Containerfile -t localhost/myrhel10:latest .
podman images
```

### 3. Upload the bootc image (Cost 3)

Tag it with your project and push it to the internal registry:

```bash
podman tag localhost/myrhel10:latest \
    "image-registry.openshift-image-registry.svc:5000/${PROJECT}/myrhel10:latest"

podman push --tls-verify=false \
    "image-registry.openshift-image-registry.svc:5000/${PROJECT}/myrhel10:latest"
```

Use the same image name, `myrhel10`, in the remaining steps; do not substitute `bootc_image`.

### 4. Convert it to a QCOW2 disk (Cost 8)

Pull the builder and your image first, then run the builder. The result is `output/qcow2/disk.qcow2`:

```bash
podman pull --tls-verify=false \
    image-registry.openshift-image-registry.svc:5000/openshift/bootc-image-builder:10.2
podman pull --tls-verify=false \
    "image-registry.openshift-image-registry.svc:5000/${PROJECT}/myrhel10:latest"

podman run --rm --tls-verify=false --privileged \
    --volume "$PWD/output:/output" \
    --volume "$PWD/config.json:/config.json" \
    --volume /var/lib/containers/storage:/var/lib/containers/storage \
    image-registry.openshift-image-registry.svc:5000/openshift/bootc-image-builder:10.2 \
    --type qcow2 --config /config.json \
    "image-registry.openshift-image-registry.svc:5000/${PROJECT}/myrhel10:latest" \
    --output /output

ls -lh output/qcow2/disk.qcow2
```

Do not continue until the QCOW2 file exists.

### 5. Upload the QCOW2 disk (Cost 7)

Upload it as a 12 GiB DataVolume in your project:

```bash
virtctl image-upload dv rhel10image --size=12Gi \
    --image-path=output/qcow2/disk.qcow2 \
    --storage-class=ocs-external-storagecluster-ceph-rbd \
    --insecure --force-bind
```

### 6. Create the Image Mode VM (Costs 2 + 3 + 5)

`cloud.init.txt` supplies the SSH public key for the new VM. Encode it and create the VM from the uploaded DataVolume:

```bash
test -s cloud.init.txt
CLOUD_INIT_USERDATA=$(base64 -w 0 cloud.init.txt)

virtctl create vm --instancetype u1.small --name rhel10imagemode \
    --volume-import "type:pvc,src:${PROJECT}/rhel10image,name:rhel10imagemode" \
    --cloud-init configdrive \
    --cloud-init-user-data "$CLOUD_INIT_USERDATA" |
    oc create -f - -n "$PROJECT"
```

The `src:` value must contain a colon. The command creates a new VM, so do not rerun it if `rhel10imagemode` already exists.

### 7. Check the VM

Wait for it to be ready and check its status:

```bash
oc wait --for=condition=Ready vmi/rhel10imagemode -n "$PROJECT" --timeout=10m
oc get vmi rhel10imagemode -n "$PROJECT" -o wide
```

From your computer, connect with `virtctl` and verify bootc and Apache:

```bash
virtctl -n "$PROJECT" ssh -i ~/.ssh/id_techquest cloud-user@vmi/rhel10imagemode
```

Inside the VM:

```bash
sudo bootc status
curl localhost
```

`podman images`.

You can upload the image with the following command:

```bash
podman push --tls-verify=false image-registry.openshift-image-registry.svc:5000/mtv-userX/bootc_image
```

SOLUTION:

```bash
podman tag localhost/myrhel10:latest image-registry.openshift-image-registry.svc:5000/mtv-user1/myrhel10:latest
podman push --tls-verify=false image-registry.openshift-image-registry.svc:5000/mtv-user1/myrhel10:latest
```

transformation of the bootc container image into a qcow2 image
Cost 8

```bash
podman run  --tls-verify=false --privileged  --volume ./output:/output  --volume ./config.json:/config.json --volume /var/lib/containers/storage:/var/lib/containers/storage image-registry.openshift-image-registry.svc:5000/openshift/bootc-image-builder:10.2  --type qcow2  --config /config.json image-registry.openshift-image-registry.svc:5000/mtv-userX/bootc_image --output /output
```

SOLUTION:

```bash
podman run --tls-verify=false --privileged  --volume ./output:/output  --volume ./config.json:/config.json --volume /var/lib/containers/storage  image-registry.openshift-image-registry.svc:5000/openshift/bootc-image-builder:10.2 --type qcow2 --config /config.json image-registry.openshift-image-registry.svc:5000/mtv-user1/myrhel10 --output /output
```

qcow2 image upload
Cost 3

You need the command

```bash
virtctl image-upload dv ....
```

qcow2 image upload
Cost 7

To upload the image to a datavolume called rhel10image, the command would look like this:

```bash
virtctl image-upload dv rhel10image --size=12Gi  --image-path=output/qcow2/disk.qcow2 --storage-class=ocs-external-storagecluster-ceph-rbd --insecure --force-bind
```

SOLUTION:

```bash
virtctl image-upload dv rhel10image --size=12Gi  --image-path=output/qcow2/disk.qcow2 --storage-class=ocs-external-storagecluster-ceph-rbd --insecure --force-bind
```

Create a new image-mode VM
Cost 2

creating a OCP VM at CLI is a 2 step process:
use `virtctl create vm...` to create a yaml file.
Use `oc create -f <this yaml file> ...` to create the VM.

IMPORTANT:

Ensure the VM to be created in your project `mtv-userX`

Ensure ssh key injection
Cost 3

`cat cloud.init.txt`

```yaml
#cloud-config
ssh_authorized_keys:
     - ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINPbf8p7KeyYIj3eKEkbvvdZ43lTFahqOIZBobXse2wa techquest2025
```

`CLOUD_INIT_USERDATA=$(base64 -w 0 cloud.init.txt)`
`virtctl create vm ...  --cloud-init configdrive  --cloud-init-user-data $CLOUD_INIT_USERDATA`

Create new image-mode VM
Cost 5

`virtctl create vm --instancetype u1.small --name rhel10imagemode --volume-import type:pvc,src:mtv-userX/rhel10image,name:rhel10imagemode --cloud-init configdrive  --cloud-init-user-data $CLOUD_INIT_USERDATA  | oc create -f - -n mtv-userX`

while:

- `rhel10imagemode` is the name of the VM to be built.
- `rhel10image` is the name of the DV you uploaded the qcow image into.

SOLUTION:

```bash
CLOUD_INIT_USERDATA=$(base64 -w 0 cloud.init.txt)
echo $CLOUD_INIT_USERDATA
virtctl create vm --instancetype u1.small --name rhel10imagemode --volume-import type:pvc,src:mtv-user1/rhel10image,name:rhel10imagemode --cloud-init configdrive  --cloud-init-user-data $CLOUD_INIT_USERDATA  | oc create -f - -n mtv-user1
```

