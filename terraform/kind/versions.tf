terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
    }
    kind = {
      source = "kyma-incubator/kind"
      version = "0.0.10"
    }
  }
  required_version = "> 1.0.0"
}
