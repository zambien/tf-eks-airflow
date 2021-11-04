# /bin/bash

echo "host                   = \"$(kubectl config view --minify --flatten --context=kind-airflow \
 | yq e '.clusters[0].cluster.server' -)\"" > terraform.tfvars

echo "client_certificate     = \"$(kubectl config view --minify --flatten --context=kind-airflow \
 | yq e '.users[0].user.client-certificate-data' -)\"" >>terraform.tfvars

echo "client_key             = \"$(kubectl config view --minify --flatten --context=kind-airflow \
| yq e '.users[0].user.client-key-data' -)\"" >> terraform.tfvars

echo "cluster_ca_certificate = \"$(kubectl config view --minify --flatten --context=kind-airflow \
| yq e '.clusters[0].cluster.certificate-authority-data' -)\"" >> terraform.tfvars
