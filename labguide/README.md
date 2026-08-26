# RHEL Image Mode on OpenShift Virt Lab

Welcome to our RHEL Image mode lab, offered at Red Hat Summit Connect 2026 in Darmstadt. 

You will find a classical RHEL 10 VM, which you have root access to. From there you will build a RHEL Image mode VM. If that VM is up and running you will update this VM. 
You will find 2 additonal guides explaining each of these exersices: One to build the VM, the other to update it. 

# Environment & Login
Before starting, we provide some information on the environment and on how to log in:

The VMs are running  on OpenShift Virtualization in a Project called mtv-userX. While X is your individual User-Number on that OpenShift Cluster. To connect to a VM you need to use `virtctl` 
The command is:
`virtctl ssh .....`
For `virtctl` to work properly, you first need to log in to the cluster via `oc` command. 

You need a command line interface which is ssh capable. There you need `virtctl` and  `oc` bindary. If you do not have these binary  commands,  you can download them from :  

https://console-openshift-console.apps.cluster-${MYCID}.dyn.redhatworkshops.io/command-line-tools (login with your userX as found further down) and add the binaries in some directoy which is searched by your PATH -settings.  

As you are on RHEL based systems, `podman` is the command mainly used to work with containers (not docker).
As our environment does not have officially signed certificates you might need `--tls-verify=false` added to your `podman` commands, when pulling or pushing sth. to a registry or repository.  

Also use the following **private ssh-key** to login:
    cat ~/.ssh/id_techquest    
    -----BEGIN OPENSSH PRIVATE KEY-----    
    b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAMwAAAAtzc2gtZW   
    QyNTUxOQAAACDT23/KeynsmCI93ihJG773WeN5UxWoajiGQaG17HtsGgAAAJBDOwwiQzsM   
    IgAAAAtzc2gtZWQyNTUxOQAAACDT23/KeynsmCI93ihJG773WeN5UxWoajiGQaG17HtsGg   
    AAAED9EEPysOPApFPSUNPJa+IXQoihG24ld2nnM/hCeQnWbNPbf8p7KeyYIj3eKEkbvvdZ   
    43lTFahqOIZBobXse2waAAAADXRlY2hxdWVzdDIwMjU=   
    -----END OPENSSH PRIVATE KEY-----   
In most environments this file should consist of 3 lines with no additional whitespaces nor line breaks. In most environments you need to change the file attrributes to 400   
`chmod 400 ~/.ssh/id_techquest`

## Login
In the following a capital X stands for your Group Number.  

You find the credentials in: ./credentials.yaml
This should provide a URL wich includes a individual identity string. This string is the `cluster id`used later. You will also find a Username and a password.          
    MYUID=userX   
    MYPASSWD=YYYYYY   
    MYCID=ZZZZZ   

You got a "normal" RHEL 10 VM running in an OCP-V environment from where you do most of the work.  You need to login to OCP first:   
`oc login -u $MYUID -p $MYPASSWD https://api.cluster-${MYCID}.dyn.redhatworkshops.io:6443`

Ensure you are in the correct project:   
`oc project mtv-$MYUID`   

then log in to your vm:   
`virtctl -n mtv-$MYUID ssh -i ~/.ssh/id_techquest cloud-user@vmi/thesource`

If you want to, you can login to the OpenShift Web-UI, (but this exersice does not need this):    
https://console-openshift-console.apps.cluster-${MYCID}.dyn.redhatworkshops.io    
    user: $MYUID    
    password:  $MYPASSWD    

All your work should be done in project  **mtv-userX**.   

Please ensure fair play as all teams have the same password.  


## References:
For your interest and broader knowledge, please find some references:

The Fedora Humingbird Liunx anouncement:
https://www.redhat.com/en/about/press-releases/fedora-hummingbird-linux-brings-agentic-linux-builders
and a description / how to:
https://fedoramagazine.org/fedora-hummingbird-linux-taking-the-hummingbird-model-to-the-full-os/
And a download link:
https://quay.io/repository/hummingbird-community/bootc-os


