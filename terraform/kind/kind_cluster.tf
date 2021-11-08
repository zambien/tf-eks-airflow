provider "kind" {}

# creating a cluster with kind of the name "test-cluster" with kubernetes version v1.18.4 and two nodes
resource "kind_cluster" "default" {
    name = var.airflow_name
    node_image = "kindest/node:v1.18.15"
    kind_config {
        kind        = "Cluster"
        api_version = "kind.x-k8s.io/v1alpha4"

      node {
        role = "control-plane"
      }

      node {
          role = "worker"
      }

      node {
          role = "worker"
      }      
    }
}