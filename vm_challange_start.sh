# It makes sense to start the VMs once as it takes some time to deploy the VM disk (the pvc). 
for ((i=1;i<=14;i++)); do
virtctl start -n vmimported-user$i winweb02
virtctl start -n vmimported-user$i winweb01
virtctl start -n vmimported-user$i database
done


