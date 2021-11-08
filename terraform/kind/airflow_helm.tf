provider "kubernetes" {
    host                   = resource.kind_cluster.default.endpoint
    client_certificate     = resource.kind_cluster.default.client_certificate
    client_key             = resource.kind_cluster.default.client_key
    cluster_ca_certificate = resource.kind_cluster.default.cluster_ca_certificate
}

provider "helm" {
  kubernetes {
    host                   = resource.kind_cluster.default.endpoint
    client_certificate     = resource.kind_cluster.default.client_certificate
    client_key             = resource.kind_cluster.default.client_key
    cluster_ca_certificate = resource.kind_cluster.default.cluster_ca_certificate
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
  name       = var.airflow_name
  repository = "https://airflow.apache.org"
  chart      = var.airflow_name
  namespace  = var.namespace
  timeout    = 120
  lint       = true
/*
  set {
    name    = "env[0].name"
    value   = "AIRFLOW__CORE__LOAD_EXAMPLES"
  }
  
  set {
    name    = "env[0].value"
    value   = "True"
  }

  values = [
    "${file("airflow-values.yaml")}"
  ]
*/
}
