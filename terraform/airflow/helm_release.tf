provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
    exec {
      api_version = "client.authentication.k8s.io/v1alpha1"
      args        = ["eks", "get-token", "--cluster-name", data.aws_eks_cluster.cluster.name]
      command     = "aws"
    }
  }
}

resource "helm_release" "airflow" {
  name       = "airflow"
  repository = "https://airflow-helm.github.io/charts"
  chart      = "airflow"
  namespace  = "airflow"

  set {
    name  = "AIRFLOW__CORE__LOAD_EXAMPLES"
    value = "True"
  }
  
  /* TBD
  values = [
    file("${path.module}/airflow-values.yaml")
  ]
  */

  /* TBD
  set_sensitive {
    name  = "some.secret"
    value = var.some_secret_value
  }
  */
}
