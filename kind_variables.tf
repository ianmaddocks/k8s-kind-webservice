# variables.tf

variable "kind_cluster_name" {
  type        = string
  description = "The name of the cluster."
  default     = "webapp-db"
}

variable "kind_cluster_config_path" {
  type        = string
  description = "The location where this cluster's kubeconfig will be saved to."
  default     = "~/.kube/config"
}