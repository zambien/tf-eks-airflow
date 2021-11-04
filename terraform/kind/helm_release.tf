provider "helm" {
  kubernetes {
    host                   = var.host
    client_certificate     = base64decode(var.client_certificate)
    client_key             = base64decode(var.client_key)
    cluster_ca_certificate = base64decode(var.cluster_ca_certificate)
  }
}
resource "helm_release" "airflow" {
  name       = "airflow"
  repository = "https://airflow-helm.github.io/charts"
  chart      = "airflow"
  namespace  = "default"

  set {
    name  = "AIRFLOW__CORE__LOAD_EXAMPLES"
    value = "True"
  }
}
