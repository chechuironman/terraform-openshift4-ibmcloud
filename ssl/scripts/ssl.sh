#!/bin/sh
ALT=$1
APIKEY=$2
BASE_DOMAIN=$3
SECRET_GROUP_ID=$4
CA=$5
SERVICE_URL=$6
MASTER_READY=$7
# SERVICE_URL="https://"${SERVICE_URL_}
echo $ALT
echo $APIKEY
echo $BASE_DOMAIN
echo $SECRET_GROUP_ID
echo $CA
echo $SERVICE_URL
echo $MASTER_READY 

echo $(pwd) && export KUBECONFIG=./installer/${ALT}/auth/kubeconfig




TOKEN=$(curl -X POST 'https://iam.cloud.ibm.com/identity/token' -H 'Content-Type: application/x-www-form-urlencoded' -d 'grant_type=urn:ibm:params:oauth:grant-type:apikey&apikey='${APIKEY}''  | jq -r .access_token)
# echo "TOKEN -> ${TOKEN}"
ibmcloud login --apikey ${APIKEY} 
echo "ibmcloud secrets-manager secrets --secret-type public_cert --service-url ${SERVICE_URL} |  grep wonder |  while read c1  c2 c3; do echo"
SECRET_ID=$(ibmcloud secrets-manager secrets --secret-type public_cert --service-url ${SERVICE_URL} |  grep ${ALT} |  while read c1  c2 c3;  do echo $c2; done)
# echo "SECRET_ID ->  ${SECRET_ID}"
if [  -z  $SECRET_ID ]; then
  OUTPUT=$(curl -X POST "${SERVICE_URL}/api/v1/secrets/public_cert"     -H "Authorization: Bearer $TOKEN"     -H "Accept: application/json"     -H "Content-Type: application/json"     -d '{
      "metadata": {
        "collection_type": "application/vnd.ibm.secrets-manager.secret+json",
        "collection_total": 1
      },
      "resources": [
        {
          "name": "'${ALT}'",
          "description": "Extended description for my secret.",
          "secret_group_id": "'${SECRET_GROUP_ID}'",
          "ca": "'${CA}'",
          "dns": "'${BASE_DOMAIN}'",
          "labels": [
            "dev"
          ],
          "common_name": "'${BASE_DOMAIN}'",
          "alt_names": [
            "*.apps.'${ALT}'.'${BASE_DOMAIN}'"
          ],
          "bundle_certs": true,
          "key_algorithm": "RSA2048",
          "rotation": {
            "auto_rotate": false,
            "rotate_keys": false
          }
        }
      ]
    }')

echo "OUTPUT -> ${OUTPUT}"
echo "SERVICE_URL -> ${SERVICE_URL}"
ID=$(echo $OUTPUT | jq -r .resources[0].id)
echo $ID
else
  ID=${SECRET_ID}
  
fi 

ibmcloud login --apikey $APIKEY

CERTIFICATE=$(ibmcloud secrets-manager secret --output json --secret-type public_cert --id ${ID} --service-url ${SERVICE_URL} | jq -r .resources[0].secret_data.certificate)
while [ "$CERTIFICATE" = "null" ]; do
        sleep 10
        CERTIFICATE=$(ibmcloud secrets-manager secret --output json --secret-type public_cert --id ${ID} --service-url ${SERVICE_URL} | jq -r .resources[0].secret_data.certificate)
done
ibmcloud secrets-manager secret --output json --secret-type public_cert --id ${ID} --service-url ${SERVICE_URL} | jq -r .resources[0].secret_data.certificate > ${ALT}.pem

ibmcloud secrets-manager secret --output json --secret-type public_cert --id ${ID} --service-url ${SERVICE_URL} | jq -r .resources[0].secret_data.private_key > ${ALT}.key

INGRESS_READY=$(oc get ingresscontroller default -n openshift-ingress-operator | tail -n +2 | awk '{print $1}')

while [ "$INGRESS_READY" != "default" ]; do
  INGRESS_READY=$(oc get ingresscontroller default -n openshift-ingress-operator | tail -n +2 | awk '{print $1}')
  sleep 30 
done

oc --kubeconfig=./installer/${ALT}/auth/kubeconfig create secret tls router-certs --cert=./${ALT}.pem --key=./${ALT}.key -n openshift-ingress

oc --kubeconfig=./installer/${ALT}/auth/kubeconfig patch ingresscontroller default -n openshift-ingress-operator --type=merge --patch='{"spec":{ "defaultCertificate":{ "name":"router-certs" }}}'
  