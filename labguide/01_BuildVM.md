# Create a new RHEL 10 Image Mode - VM

[back](/)

## The Ask - in short
You need to create a bootc container image for a new VM which needs to be uploaded in local registry. For the initial boot, you need to transfer it into a qcow2 image, upload that into OCP-V from which you create a image mode based VM.

## Prerequisits
a laptop with:
- Linux with ARM 64
- Linux with x86_64
- MAC with ARM 64
- MAC with x86_64
- Windows with x86_64
and: 
- ssh capable cmd-line interface (shell, putty, etc.)
- the rights to copy and execute executables onto the system. 

## Preparation

### tools on your laptop
You need a command line interface which is ssh capable. There you need `virtctl` and  `oc` bindary. If you do not have these binary  commands,  you can download them from :  
`https://console-openshift-console.apps.cluster-${MYCID}.dyn.redhatworkshops.io/command-line-tools` (login with your userID as found in [credentials.html](credentials.html) and add them in some directoy which is searched by your PATH -settings.  

### non signed certificates
As our environment does not have officially signed certificates you might need 
`--tls-verify=false` added to your commands pulling or pushing sth to a registry or repository.  

### ssh key
Use the following **private ssh-key** to login:
```text
    cat ~/.ssh/id_techquest    
    -----BEGIN OPENSSH PRIVATE KEY-----    
    b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAMwAAAAtzc2gtZW   
    QyNTUxOQAAACDT23/KeynsmCI93ihJG773WeN5UxWoajiGQaG17HtsGgAAAJBDOwwiQzsM   
    IgAAAAtzc2gtZWQyNTUxOQAAACDT23/KeynsmCI93ihJG773WeN5UxWoajiGQaG17HtsGg   
    AAAED9EEPysOPApFPSUNPJa+IXQoihG24ld2nnM/hCeQnWbNPbf8p7KeyYIj3eKEkbvvdZ   
    43lTFahqOIZBobXse2waAAAADXRlY2hxdWVzdDIwMjU=   
    -----END OPENSSH PRIVATE KEY-----   
```
On a MAC as well as on RHEL this file consists of 7 distinct lines.  In most environments you need to change the file attrributes to 400   
`chmod 400 ~/.ssh/id_techquest`
And might also need to ensure seLinux attributs are set correctly:
`restorecon -R ~/.ssh`

## Login to your builderVM called `thesource`
In the following a capital X stands for your team number.  
To receive all user-specific information type your team number into [credentials.html](credentials.html)
This reveals `cluster id` used to identify your OCP cluster. You will also find a UserID and a password.          

**Graphical UI** of OpenShift (just for your info - we will work on CMD-Line) is found at: 
```text
https://console-openshift-console.apps.cluster-{clusterID}.dyn.redhatworkshops.io/
```
CMDLine login to your VM from where you do the work:
```bash
oc login -u {userID} -p {password} https://api.cluster-{clusterID}.dyn.redhatworkshops.io:6443/
virtctl ssh -i ~/.ssh/id_techquest cloud-user@vmi/thesource                       
```
You will get asked about the host fingerprint similar to the following. Please type yes
```text
The authenticity of host 'vmi.thesource.mtv-user2 (<no hostip for proxy command>)' can't be established.
ED25519 key fingerprint is: SHA256:Cj5OTB8YC7348sSdcmTGtFVvvi8X5RUJG2RDWz+P/yU
This key is not known by any other names.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added 'vmi.thesource.mtv-user2' (ED25519) to the list of known hosts.
```

## Preparation within the `thesource` VM
Switch to root and into the prepared container build directory:
```bash
sudo -i 
cd /root/rhel_image_mode-main
```
We will set some variables so that cut & past will work easier later on:

```bash
MYUID={userID}
MYCID={clusterID}
PROJECT="mtv-$MYUID"
```
Hint: replace {userID} and {clusterID} with the values provided by [credentials.html](credentials.html). But leave the last line as it is.

## Log in to the cluster and internal registry 

The OpenShift login on your computer is not shared with `thesource`. Log in again inside the VM. `oc login` prompts for your password:

```bash
oc login -u "$MYUID" "https://api.cluster-${MYCID}.dyn.redhatworkshops.io:6443"
oc project "$PROJECT"
oc whoami
```

You may want to get an overview of the OpenShift environment you logged into. Either use the Web UI (see earlier in this text) and look around. Or use cmd-line tool OC to gain an overview.
Some commands which might help you:

| Command | Explaination |
|:-----|:----------|
|`oc whoami`| show as whom you are logged in |
|`oc whoami --show-console`| show how to login in to web UI|
|`oc whoami --show-token`| show a login token which can be used to gain access|
|`oc projects`| see list of existing projcts. The star marks the currently selected project|
|`oc project`| see the currently selected project and the cluster URL you are connected to|
|`oc get vm`| get list of defined VMs in this project|
|`oc get vmi`| get list of running VMs aka VM instances in this project|
|`oc get services`| get list of network services defined in this project|
|`oc get route`| get list of network routes (reachable form the outside defined in this project|
Hint: you should find 2 VMs (`thesource` and `rhel10imagemode`). `thesource` is the one you logged into via ssh. The other one will only be needed as a fallback and should be switched off.

## Log in to the internal registry 
Use `podman` command to log in to the internal registry using a token provided from oc 
```bash
oc whoami -t | podman login --tls-verify=false \
    -u "$(oc whoami)" --password-stdin \
    image-registry.openshift-image-registry.svc:5000
```
`oc whoami -t` provides a token on STDOUT and forwards it to STDIN of the following command.\n\n
podman login separately authenticates to the local image registry using the username `oc whoami` provides and the token found at STDIN.

## Build the bootc container image 

Please inspect the directory you are in. You should find a `Containerfile` which defines how the container is to be built. This file will need some adoption later.  You will also find a `config.json` which defines the user and password to log into the to be built image mode VM and some other files to ensure things will work smoothly.

The first line of `Containerfile` must use the bootc base image URL provided from the cluster's internal registry:\n\n
The URL is assembled as: registry/namespace/imagename\n\n
Registry: `image-registry.openshift-image-registry.svc:5000`\n\n
Namespace: `/openshift`\n\n
Imagename: `/rhel-bootc:10.2`\n\n


```dockerfile
FROM image-registry.openshift-image-registry.svc:5000/openshift/rhel-bootc:10.2

ADD etc /etc

RUN dnf install -y httpd cloud-init qemu-guest-agent
RUN sed -i -e '$aPermitRootLogin yes' /etc/ssh/sshd_config
RUN systemctl enable httpd
```

Check it, then build from the current directory (`.`):

```bash
grep '^FROM ' Containerfile
podman build -f Containerfile -t localhost/myrhel10:latest .
podman images
```
The last command `podman images` should show a image named localhost/myrhel10:latest. This is in the image registry on the local system (in our case `thesource` VM).

## Upload the bootc image

Tag it with the to be name and internal registry location and push it there:

```bash
podman tag localhost/myrhel10:latest \
    "image-registry.openshift-image-registry.svc:5000/${PROJECT}/myrhel10:latest"

podman push --tls-verify=false \
    "image-registry.openshift-image-registry.svc:5000/${PROJECT}/myrhel10:latest"
```

## optional - Run OS container as a container for testing and QA
Now we have a container image (as any other container image) but it holds a full operating system inside. As an optional step you can now test this OS-container like a classical container in your container runtime environmet by running it:

```bash
podman run -d --rm --name myvm "image-registry.openshift-image-registry.svc:5000/${PROJECT}/myrhel10:latest"
```
We used the following options of `podman run`

| Option  | Explaination |
|:-----|:----------|
| --detach | Run container in background and print container ID |
| --rm | Remove container and any anonymous unnamed volume associated with the container after exit |
| --name string | Assign a name to the container |
This gives you the CMD-line prompt back while the container is running (in the background). When you stop the container it will be removed.

Now connect into it with a bash:
```bash
podman run -it myvm /bin/bash
```
| Option / Argument | Explaination |
|:-----|:----------|
|`-it` |  switches to interactive and pseydotty, which allows to have an interactive connection with your existing shell-environment. |
| /bin/bash | Argument behind the container provides a command which should be executed - a shell in this case |

Hint: Some commands might not be available within the container. Containers built lean and security aware only provided what the minimal neccesary to get the task fullfiled. 

After everything seems ok.  Exit from the container and stop the container again:
```bash
exit
podman stop myvm 
```



## Convert the container image to a QCOW2 disk image
Now we have seen the container OS image running as a container. As we want this container image to look like a boot-disk, we need to convert it into a disk. There are many different kind of disks. We want a qcow2 disk, which is usable by KVM and Openshift-Virtualization.

Red Hat provides a builder tool also provided as a container. So we will run this image-builder container with some parameters and with the OS containerimage location as the argument. The image-builder then has all information. 

We pull the builder and our image first, then run the builder. The result is to be found at `output/qcow2/disk.qcow2`:

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
```
The above step may take some time. So please execute the command before reviewing the options and arguments. Nevertheless worth to review the parameters, so you know what we have done:

| Option / Argument | Explaination |
|:-----|:----------|
| `--tls-verify=false` | Do not verify tls certificates. Needed in this lab environment |
| `--privileged` | Run this container with priviledges, normaly removed from containers |
| `--volume "$PWD/output:/output"` | mount the directory ./output into the container to /output |
| `--volume "$PWD/config.json:/config.json"` | mount the file ./config.json into the container to /config.json |
| `--volume /var/lib/containers/storage:/var/lib/containers/storage` | mount the directory /var/lib/containers/storage into the container to /var/lib/containers/storage |
| `image-registry.openshift-image-registry.svc:5000/openshift/bootc-image-builder:10.2` | The container image which should be run. Every parameter hereafter is read by the container. |
| `--type qcow2` | The output should be a qcow2 image |
| `--config /config.json` | where within the container the config file is found |
| `"image-registry.openshift-image-registry.svc:5000/${PROJECT}/myrhel10:latest"` | The image which should be converted |
| `--output /output` | where within the container the output should be placed. As this dir is mounted form outside the container it will persistent after the container exited |

After the conversion finished, you should find a qcow image:
```bash
ls -lh output/qcow2/disk.qcow2
```

Do not continue until the QCOW2 file exists.

## Upload the QCOW2 disk 
Now we have a qcow2 image in our `thesource` VM. This needs to be provided as a golden image for OpenShift Virtualization. Upload it as a 12 GiB DataVolume in your project:

```bash
virtctl image-upload dv rhel10image --size=12Gi \
    --image-path=output/qcow2/disk.qcow2 \
    --storage-class=ocs-external-storagecluster-ceph-rbd \
    --insecure --force-bind
```

| Cmd / Option / Argument | Explaination |
|:-----|:----------|
| `virtctl image-upload` | The command to upload an image |
| `dv rhel10image` | the target will be a datavolume named rhel10image |
| `--size=12Gi` | the sice of that target will be 12 Gi |
| `--image-path=output/qcow2/disk.qcow2` | the source is the name qcow image |
| `--storage-class=ocs-external-storagecluster-ceph-rbd` | the storage class this datavolume should be placed into |
| `--insecure` | in our environment we don't have singed certificates |
| `--force-bind` | the created disk is forecd to be bound without waiting for a container or VM to request it |

## Create the Image Mode VM 

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

Let's find out what the parts of the commands do:

| Cmd / Option / Argument | Explaination |
|:-----|:----------|
| `test -s cloud.init.txt` | True if file exists and has a size greater than zero |
| `base64 -w 0 cloud.init.txt` | Base64 Encode the content of the file to STDOUT |
| `CLOUD_INIT_USERDATA=$(...)` | let the output of the cmd in brakets be the value of the var CLOUD_INIT_USERDATA |
| `virtctl create vm` | create a json definition file of a VM to STDOUT |
| `--instancetype u1.small` | use instant type u1.small |
| `--name rhel10imagemode` | name the vm rhel10imagemode |
| `--volume-import "type:pvc,src:${PROJECT}/rhel10image,name:rhel10imagemode"` | import a volume, let that volume be a pvc, take the volume `rhel10image` as source, name the new pvc rhel10imagemode |
| `--cloud-init configdrive` | Specify the type cloud-init data source |
| `--cloud-init-user-data "$CLOUD_INIT_USERDATA"` | use the content provided by the Variable given as cloud init user data |
| `\| oc create -f - -n "$PROJECT"` | pipe the json VM definiton to oc create to actually create the object in the named project |
| `-f -` | use STDIN as input-file |

## Check the VM

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

