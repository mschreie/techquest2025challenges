NAME: RHEL 10 Image Mode - VM
Category: Red Hat Enterprise Linux
Value: 40
Scoring: Static

Flag: regex:
Booted image: image-registry.openshift-image-registry.svc:5000/mtv-user\d+.*(\n)*\s+Digest: sha256:.*(\n)*\s+Version:

## The Ask - in short
You need to create a bootc container image for a new VM which needs to be uploaded in local registry. For the initial boot, you need to transfer it into a qcow2 image, upload that into OCP-V from which you create a image mode based VM.

## Preparation
You need a command line interface which is ssh capable. There you need `virtctl` and  `oc` bindary. If you do not have these binary  commands,  you can download them from :  
https://console-openshift-console.apps.cluster-${MYCID}.dynamic.redhatworkshops.io/command-line-tools (login with your userX as found further down) and add them in some directoy which is searched by your PATH -settings.  

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
    MYUID=userX   
    MYPASSWD=YYYYYY   
    MYCID=ZZZZZ   

You got a "normal" RHEL 10 VM running in an OCP-V environment from where you do most of the work.  You need to login to OCP first:   
`oc login -u $MYUID -p $MYPASSWD https://api.cluster-${MYCID}.dynamic.redhatworkshops.io:6443`

Ensure you are in the correct project:   
`oc project mtv-$MYUID`   

then log in to your vm:   
`virtctl -n mtv-$MYUID ssh -i ~/.ssh/id_techquest cloud-user@vmi/thesource`

If want to, you can login to the OpenShift Web-UI, (but this exersice does not need this):    
https://console-openshift-console.apps.cluster-${MYCID}.dynamic.redhatworkshops.io    
    user: $MYUID    
    password:  $MYPASSWD    

All your work should be done in project  **mtv-userX**.   

Please ensure fair play as all teams have the same password.  

## The Environment
The RHEL VM you logged in to is a package based RHEL VM, called "thesource". You are able to sudo to root.  
You will find a directory `/root/rhel_image_mode-main` with some helpful files to create bootc container image and the qcow image. You might need to alter the Containerfile slightly.   
You will mainly use `podman` to create and upload the bootc image..
You will find the following images within your OCP local registry:  
The base image to create your bootc image from:   
`image-registry.openshift-image-registry.svc:5000/openshift/rhel-bootc:10.0` 
The image builder to convert your bootc container into a qcow image for very frist boot:   
`image-registry.openshift-image-registry.svc:5000/openshift/bootc-image-builder:10.0`   
To gain access to the local registry you must be logged in with oc command to the OpenShift platfrom `oc login ....`.     
Then login to the registry as user `$MYUID` with the `session token` of your oc sesseion. If you can pull the images the login to the registry was successful. 

## The Ask - in long
You need to create a bootc container image for a new VM which need to be uploaded in local registry. For the initial boot, you need to transfer it into a qcow2 image, upload that into a PVC of OCP-V from which you create a VM.  
This involves 
* the creation of a bootc image (via `podman`, `Containerfile`, and bootc base image)
* the upload into local registy into your own project space `image-registry.openshift-image-registry.svc:5000/mtv-userX`
* the transformation of the bootc container image into a `qcow2` image via image-builder container
* the upload of this qcow image into ocp-v as a Datavolume with the storage class `ocs-external-storagecluster-ceph-rbd`. Please make the DV 12 GiB large and ensure it to be bound. `virtctl` will be your friend.   
* the creation of a new VM from that image within your Project `mtv-userX`.
			*  Ensure to use instance type `u1.small`
			*  ensure ssh-autorized key will be injected via cloud-init. 

## Success
If everything went right you should have a new VM and be able to access it from your local CLI via `virtctl ssh ...` with the ssh-key used previously. 
Within the VM run `bootc status` and paste the output into the comment text field of this challange. Do not care about font colour or font style / font size.

## Hints:
registry login
Cost 1
`oc login -u $MYUID -p $MYPASSWD https://api.cluster-${MYCID}.dynamic.redhatworkshops.io:6443`<br>
`podman login --tls-verify=false -u $MYUID -p $(oc whoami -t) image-registry.openshift-image-registry.svc:5000`

Building a bootc image
Cost 3
Within your VM as root-user in the directory rhel_image_mode-main you need to run  
`podman build`.   
The `FROM` derective needs to point to the bootc  base image availabe in the OCP environment (found in the description of this challange).
You also need to be logged in to the registry with `podman login` 
Before you succed with `podman login` you need an `oc login` first.   
With `podman login`ensure to use the correct username `$MYUID`and your session key as mentiond in the text.

bootc container image upload
Cost 3
You created a bootc image. Which you can check via
`podman images`. 
You can upload the image with the following command:
`podman push --tls-verify=false image-registry.openshift-image-registry.svc:5000/mtv-userX/bootc_image`

transformation of the bootc container image into a qcow2 image
Cost 8
`podman run  --tls-verify=false --privileged  --volume ./output:/output  --volume ./config.json:/config.json --volume /var/lib/containers/storage:/var/lib/containers/storage image-registry.openshift-image-registry.svc:5000/openshift/bootc-image-builder:10.0  --type qcow2  --config /config.json image-registry.openshift-image-registry.svc:5000/mtv-userX/bootc_image --output /output`

qcow2 image upload
Cost 3
You need the command 
`virtctl image-upload dv ....`

qcow2 image upload
Cost 7
To upload the image to a datavolume called rhel10image, the command would look like this:
`virtctl image-upload dv rhel10image --size=12Gi  --image-path=output/qcow2/disk.qcow2 --storage-class=ocs-external-storagecluster-ceph-rbd --insecure --force-bind`

Create a new image-mode VM
Cost 2
creating a OCP VM at CLI is a 2 step process:
use `virtctl create vm...` to create a yaml file.
Use `oc create -f <this yaml file> ...` to creaet the VM.   
IMPORTANT:   
Ensure the VM to be created in your project `mtv-userX`

Ensure ssh key injection
Cost 3
`cat cloud.init.txt` 
`#cloud-config
ssh_authorized_keys:
   - ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINPbf8p7KeyYIj3eKEkbvvdZ43lTFahqOIZBobXse2wa techquest2025`   

`CLOUD_INIT_USERDATA=$(base64 -w 0 cloud.init.txt)`   
`virtctl create vm ...  --cloud-init configdrive  --cloud-init-user-data $CLOUD_INIT_USERDATA`

Create new image-mode VM
Cost 5
`virtctl create vm --instancetype u1.small --name rhel10imagemode --volume-import type:pvc,src:mtv-userX/rhel10image,name:rhel10imagemode --cloud-init configdrive  --cloud-init-user-data $CLOUD_INIT_USERDATA  | oc create -f - -n mtv-userX`
while:
* `rhel10imagemode` is the name of the VM to be built.
* `rhel10image` is the name of the DV you uploaded the qcow image into.

