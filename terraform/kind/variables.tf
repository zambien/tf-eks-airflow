variable "host" {
  type = string
}

variable "client_certificate" {
  type = string
}

variable "client_key" {
  type = string
}

variable "cluster_ca_certificate" {
  type = string
}

variable "namespace" {
  type = string
  default = "default"
}

variable "airflow_name" {
  type = string
  default = "airflow"
}

variable "postgres_db" {
  type = string
  default = "airflow"
}

variable "postgres_name" {
  type = string
  default = "db"
}

variable "postgres_pass" {
  type = string
  default = "itsnotasecret"
}
