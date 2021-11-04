# tf-eks-airflow
Airflow running in AWS EKS deployed with terraform and helm

I wanted to compare MWAA and a custom built Airflow stack on EKS to understand the differences, tradeoffs, and cost to run and maintain.  MWAA is dead simple to stand up but has some serious limitations that may or may not impact you.  I will add some notes later on about that comparison.  For now, the plan is to 

- [x] Stand up Airflow using kind per the Airflow instructions: https://airflow.apache.org/docs/helm-chart/stable/quick-start.html 
- [x] Customize the install per those instructions with something that makes sense for my planned use
- [x] Tinker with that running system to learn more
- [x] Stand up a similar system using the helm chart on AWS with EKS using helm and/or terraform
- [ ] Modify the AWS system to be closer to how we would actually run it in production
- [ ] Continue to tweak and tune, send stats to Prometheus, test Flower vs the k8s runner, etc.
- [ ] Create a workflow to get dags from Git into Airflow somehow (Git to S3)

The goal being to come away with a good idea of whether it makes sense to roll your own Airflow or to just use MWAA and to do some learning and share some code in the process.

## Prereqs

Prior to starting you should have the following installed:

* kubectl
* Helm (3)
* awscli
* kind
* terraform

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

Configure kubectl: `aws eks --region $(terraform output -raw region) update-kubeconfig --name $(terraform output -raw cluster_name)`

Optionally you may choose to install the kubernetes console as described in https://learn.hashicorp.com/tutorials/terraform/eks#deploy-and-access-kubernetes-dashboard.

## Deploy Airflow on EKS manually

First let's do a deployment on EKS manually using kubectl.  We will do a lot of the same things that we did with kind... which makes sense because it is all k8s!

```bash
{
    export NAMESPACE=airflow-namespace
    export RELEASE_NAME=airflow-v1
    kubectl create namespace $NAMESPACE
}
```

Then we will start airflow in EKS this time with the example dags so we have something to play around with:

```bash
helm repo add apache-airflow https://airflow.apache.org
helm repo update
helm install $RELEASE_NAME apache-airflow/airflow \
  --namespace $NAMESPACE \
  --set 'env[0].name=AIRFLOW__CORE__LOAD_EXAMPLES,env[0].value=True'
```

Once again we can look at the status:
```bash
kubectl get pods --namespace $NAMESPACE
helm list --namespace $NAMESPACE
```

Once everything is running we can connect port forward to the EKS web server as follows:

```bash
export WEBSERVER_POD_NAME=$(kubectl get pods --namespace $NAMESPACE -l "component=webserver,tier=airflow" -o jsonpath="{.items[0].metadata.name}")
kubectl port-forward --namespace $NAMESPACE $WEBSERVER_POD_NAME 8080:8080
```

If you want to connect to the Kubernetes admin console:

```bash
kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep service-controller-token | awk '{print $1}')
```

And then you can `kubectl proxy` to get to the console with the token.

Well that was pretty nifty but I guess we'd rather not have to type in a bunch of commands to deploy. Let's tear down our airflow deployment but leave EKS running.

`helm uninstall $RELEASE_NAME -n $NAMESPACE`

Verify that everything is gone...

`kubectl get pods --namespace $NAMESPACE`

And once it is we can remove the namespace we created:

`kubectl delete namespace $NAMESPACE`

Alright, all cleaned up. Now let's deploy Airflow with Terraform

## Deploy Airflow with Terraform

Change directory to the airflow folder under terraform:

`cd terraform/airflow`

Now run the terraform

```bash
terraform init
terraform plan
# review the plan
terraform apply
```

We can watch everything come up as we have been:

```bash
kubectl get pods --namespace $NAMESPACE
```

We can port forward as we did before:

```bash
export WEBSERVER_POD_NAME=$(kubectl get pods --namespace $NAMESPACE -l "component=web,app=airflow" -o jsonpath="{.items[0].metadata.name}")
kubectl port-forward --namespace $NAMESPACE $WEBSERVER_POD_NAME 8080:8080
```

## Cleanup

We don't want to leave our AWS resources or even kind configured as we shouldn't waste resources or money.  Below find how to clean everything up.

### kind

To remove our kind resources, simply run `kind delete clusters kind`

### AWS

If we simply want to kill everything with fire we can run a destroy on the EKS cluster. The separate folder with airflow only creates resources within EKS so deleting EKS will fully cleanup our resources.

