# The image mode VM is up and running. Great

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
