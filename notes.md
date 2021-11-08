# deploy airflow on k8s using helm without packaged db

To keep everything simple we use the default namespace

Create the cluster and set it in kubectl

```
kind create cluster --name airflow --config terraform/kind/kind-config.yaml
kubectl cluster-info --context kind-airflow
```

Get your charts

```
helm repo add apache-airflow https://airflow.apache.org
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
```

Run postgres

```bash
helm install db \
  --set postgresqlPassword=itsnotasecret,postgresqlDatabase=airflow \
    bitnami/postgresql
```

Run airflow without the included db:

```bash
helm install airflow apache-airflow/airflow \
  -f terraform/kind/airflow-values.yaml \
  --set 'env[0].name=AIRFLOW__CORE__LOAD_EXAMPLES,env[0].value=True'
```

Once it comes up forward the ports:

```
export WEBSERVER_POD_NAME=$(kubectl get pods -l "component=webserver,tier=airflow" -o jsonpath="{.items[0].metadata.name}")
kubectl port-forward $WEBSERVER_POD_NAME 8080:8080
```


