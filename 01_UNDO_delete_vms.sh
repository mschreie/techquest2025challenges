. ./env.sh

# create the VMs
for i in {1..20}; do
   virtctl stop thesource -n mtv-user$i  --force --grace-period 0 &
done
for i in {1..20}; do
   oc delete vm thesource -n mtv-user$i  &
done


