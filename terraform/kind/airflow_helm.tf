provider "kubernetes" {
    host                   = var.host
    client_certificate     = base64decode(var.client_certificate)
    client_key             = base64decode(var.client_key)
    cluster_ca_certificate = base64decode(var.cluster_ca_certificate)
}

provider "helm" {
  kubernetes {
    host                   = var.host
    client_certificate     = base64decode(var.client_certificate)
    client_key             = base64decode(var.client_key)
    cluster_ca_certificate = base64decode(var.cluster_ca_certificate)
  }
}

resource "helm_release" "postgres" {
  name        = var.postgres_name
  repository  = "https://charts.bitnami.com/bitnami"
  chart       = "postgresql"
  namespace   = var.namespace

  set {
    name  = "postgresqlPassword"
    value = var.postgres_pass
  }

  set {
    name  = "postgresqlDatabase"
    value = var.postgres_db
  }
}

data "template_file" "airflow_values" {
  template = "${file("${path.module}/airflow-values.yaml.tpl")}"
  vars = {
    postgres_name     = var.postgres_name
    postgres_pass     = var.postgres_pass
    postgres_database = var.postgres_db
  }
}

resource "helm_release" "airflow" {
  name       = "airflow"
  repository = "https://airflow.apache.org"
  chart      = "airflow"
  namespace  = var.namespace
  timeout    = 90
  lint       = true

  set {
    name    = "env[0].name"
    value   = "AIRFLOW__CORE__LOAD_EXAMPLES"
  }
  
  set {
    name    = "env[0].value"
    value   = "True"
  }

  values = [
    "${file("${path.module}/airflow-values.yaml")}"
  ]  
}
