
#!/bin/sh
cluster_id=$1
user=$2
password=$3
ssl_ready=$4


export KUBECONFIG=./installer/${cluster_id}/auth/kubeconfig
htpasswd -c -B -b ./installer/${cluster_id}/auth/${user}.htpasswd ${user} ${password}
htpasswd -b ./installer/${cluster_id}/auth/${user}.htpasswd ${user} ${password}
oc create secret generic htpass-secret --from-file=htpasswd=./installer/${cluster_id}/auth/${user}.htpasswd -n openshift-config
oc apply -f  ./admin-user/scripts/htprovider.yaml
oc adm policy add-cluster-role-to-user cluster-admin ${user}
oc delete secrets kubeadmin -n kube-system