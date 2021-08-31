terraform {
  required_providers {
    kubernetes = {
        source = "hashicorp/kubernetes"
        version = "2.4.1"
    }
    helm = {
        source = "hashicorp/helm"
        version = "2.2.0"
    }
  }
}

provider "kubernetes" {
  host                   = module.kind_cluster.k8_host
  client_certificate     = module.kind_cluster.k8_client_certificate
  client_key             = module.kind_cluster.k8_client_key
  cluster_ca_certificate = module.kind_cluster.k8_ca_certificate
}

provider "helm" {
  kubernetes {
    host                   = module.kind_cluster.k8_host
    client_certificate     = module.kind_cluster.k8_client_certificate
    client_key             = module.kind_cluster.k8_client_key
    cluster_ca_certificate = module.kind_cluster.k8_ca_certificate
  }
}