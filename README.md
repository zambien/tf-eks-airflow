# tf-eks-airflow
Airflow running in AWS EKS deployed with terraform and helm

I wanted to compare MWAA and a custom built Airflow stack on EKS to understand the differences, tradeoffs, and cost to run and maintain.  MWAA is dead simple to stand up but has some serious limitations that may or may not impact you.  I will add some notes later on about that comparison.  For now, the plan is to 

- [ ] Stand up Airflow using kind per the Airflow instructions: https://airflow.apache.org/docs/helm-chart/stable/quick-start.html 
- [ ] Customize the install per those instructions with something that makes sense for my planned use
- [ ] Tinker with that running system to learn more
- [ ] Stand up a similar system using the helm chart on AWS with EKS
- [ ] Modify the AWS system to be closer to how we would actually run it in production
- [ ] Continue to tweak and tune, send stats to Prometheus, test Flower vs the k8s runner, etc.

The goal being to come away with a good idea of whether it makes sense to roll your own Airflow or to just use MWAA and to do some learning and share some code in the process.
