# tf-eks-airflow
Airflow running in AWS EKS deployed with terraform and helm

I wanted to compare MWAA and a custom built Airflow stack on EKS to understand the differences, tradeoffs, and cost to run and maintain.  MWAA is dead simple to stand up but has some serious limitations that may or may not impact you.  I will add some notes later on about that comparison.  For now, the plan is to 

- [x] Stand up Airflow using kind per the Airflow instructions: https://airflow.apache.org/docs/helm-chart/stable/quick-start.html 
- [x] Customize the install per those instructions with something that makes sense for my planned use
- [x] Tinker with that running system to learn more
- [ ] Stand up a similar system using the helm chart on AWS with EKS
- [ ] Modify the AWS system to be closer to how we would actually run it in production
- [ ] Continue to tweak and tune, send stats to Prometheus, test Flower vs the k8s runner, etc.
- [ ] Create a workflow to get dags from Git into Airflow somehow (Git to S3)

The goal being to come away with a good idea of whether it makes sense to roll your own Airflow or to just use MWAA and to do some learning and share some code in the process.

## Kind Setup

As mentioned earlier we will use the Airflow quickstart for our setup with some minor modifications.

https://airflow.apache.org/docs/helm-chart/stable/quick-start.html

First, create the cluster and get the chart:

```bash
{
    kind create cluster --image kindest/node:v1.18.15
    helm repo add apache-airflow https://airflow.apache.org
    helm repo update
}
```

Next, let's create our `$NAMESPACE` and `$RELEASE`:

```bash
{
    export NAMESPACE=airflow-namespace
    export RELEASE_NAME=airflow-v1
    kubectl create namespace $NAMESPACE    
}
```

Then we will start airflow with the example dags so we have something to play around with:

```bash
helm install $RELEASE_NAME apache-airflow/airflow \
  --namespace $NAMESPACE \
  --set 'env[0].name=AIRFLOW__CORE__LOAD_EXAMPLES,env[0].value=True'
```

And once that command finishes we can look at what is running (or do this in another window):

```bash
kubectl get pods --namespace $NAMESPACE
helm list --namespace $NAMESPACE
```

Finally, we can expose our port so we can test:

```bash
kubectl port-forward svc/$RELEASE_NAME-webserver 8080:8080 --namespace $NAMESPACE
```

http://localhost:8080

Alright great. That worked just fine.  Let's leave that running and in another shell make some changes to our running Airflow.Let's extend our Airflow capabilities by installing some python packages.  I have a Dockerfile with everything I need in the repo already.

```bash
docker build --tag custom-airflow:0.0.1 .
```

Now we load the image into kind

```bash
kind load docker-image custom-airflow:0.0.1
```

And then upgrade our runtime:

```bash
helm upgrade $RELEASE_NAME apache-airflow/airflow --namespace $NAMESPACE \
    --set images.airflow.repository=custom-airflow \
    --set images.airflow.tag=0.0.1 \
    --set 'env[0].name=AIRFLOW__CORE__LOAD_EXAMPLES,env[0].value=True'    
```

You can run `kubectl get pods --namespace $NAMESPACE` in another window to see the progress and when done check the web console again.

That's it for the kind setup.  There is a lot you can dig into here but this is a good place to start to get familiar with k8s and Airflow.

## Terraform

For the base EKS cluster, I the terraform from this repo: https://github.com/hashicorp/learn-terraform-provision-eks-cluster

First we will spin up the EKS cluster.

```bash
cd terraform/eks
terraform init
terraform plan
# review the plan
terraform apply
```

Configure kubectl: `aws eks --region $(terraform output -raw region) update-kubeconfig --name $(terraform output -raw cluster_name)
`

Optionally you may choose to install the kubernetes console as described in https://learn.hashicorp.com/tutorials/terraform/eks#deploy-and-access-kubernetes-dashboard.

