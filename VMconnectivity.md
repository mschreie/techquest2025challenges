NAME: VM connectivity
Category: OpenShift Virtualization
VALUE: 25 
Scoring: static

Flag: regex:
You are the visitor number: \d+\n*\s*(<br />)?I'm the server WINWEB0[12]%?



## What to do
You will find 3 VMs: 2 frontend VMs called `winweb01` and `winweb02 `and 1 backend `database` VM with a mysql running on port `3306`.    
You need to ensure connectivety to the frontend web servers from outside OpenShift via the existing route and ensure connectivity to the backend from inside OpenShift.   
You will find a route (as mentioned) and a service,  preconfigured, but not yet complete.  Please make sure that both things work:  
* connectivity with the given route to the winweb servers
* connectivity to the database. a mysql database listening on port 3306,

## Login
In the following a capital X stands for your Group Number.  
TIn the following a capital X stands for your Group Number.  
To receive all user-specific information type your team ID into https://red.ht/ctfd-2025-cred-virt    
This should provide a URL wich includes a individual identity string. This string is the `cluster id`used later. You will also find a Username and a password.          
    MYUID=userX   
    MYPASSWD=YYYYYY   
    MYCID=ZZZZZ   
		
Your can login to your OpenShift environment via    
https://console-openshift-console.apps.cluster-${MYCID}.dynamic.redhatworkshops.io
Login as user `$MYUID` with the password `$MYPASSWD`.   

Or via CMD-Line you can download the `oc`-binary from https://console-openshift-console.apps.cluster-${MYCID}.dynamic.redhatworkshops.io/command-line-tools and log in with:   
`oc login --insecure-skip-tls-verify=false -u $MYUID -p $MYPASSWD https://api.cluster-${MYCID}.dynamic.redhatworkshops.io:6443`

In both cases please only work within the project `vmimported-userX`. 

Please ensure fair play as all teams have the same password.  
## Success
When using curl / wget / webbrowser to connect to your frontend via the route you should receive some answer. 

Please submit the challenge and cut & past the answer in the comment text field. Do not care about font colour or font style / font size. 
## Hints

connection to database
Cost: 8
To connect to the database server you need a service.
This service needs to be called `database`  and should be defined like this:
```
apiVersion: v1   
kind: Service   
metadata:   
  name: database    
  namespace: vmimported-user1    
spec:    
  selector:    
    kubevirt.io/domain: database     
  ports:    
  - protocol: TCP    
    port: 3306   
    targetPort: 3306  
```		


connection to winweb0[12]
Cost: 8


There is a route defined pointing to the service `webapp`. Therefore the service need to be named `webapp`.  It might be defined like this.
```
apiVersion: v1
kind: Service
metadata:
  name: webapp
  namespace: vmimported-userX
spec:
  selector:
    env: webapp
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
```
Now we defined the selector `env: webapp` which needs to be preent with the VMs we want to reach. Therefore we need to add a Label to the VM
Within the VM yaml you need to locate the `spec.template.metadata` path. Most likely within that path you will find an Attribute `creationTimestamp: ` (this is for your reference and orientation).
At the same level as the `creationTimestamp` add the following `labels:`-section.
```
labels:
    env: webapp
		app: winweb01
```
After changing the labels the VMs need to powercycle for the change to take effect.

