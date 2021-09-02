# Dev ENV vars
locals {
  meltano_env_variables = []
}

# Create local kubernetes cluster
module "kind_cluster" {
  source = "./modules/kind_cluster"
}

module "dev_images" {
  source = "./modules/dev_images"
  depends_on = [module.kind_cluster]
}

module "postgres" {
  source = "./modules/postgres"
  depends_on = [module.kind_cluster]
}

resource "helm_release" "meltano" {
  name        = "meltano"
  repository  = "../helm/"
  chart       = "meltano"
  namespace   = "meltano"
  version     = "0.1.0"
  wait        = false
  # values = [
  #   "${file("values.yml")}"
  # ]

  set {
    name  = "extraEnv"
    value = yamlencode(local.meltano_env_variables)
  }

  # This is not a chart value, but just a way to trick helm_release into running every time.
  # Without this, helm_release only updates the release if the chart version (in Chart.yaml) has been updated
  set {
    name  = "timestamp"
    value = timestamp()
  }

  depends_on = [module.postgres]
}

resource "helm_release" "airflow" {
  name        = "airflow"
  repository  = "../helm/"
  chart       = "airflow"
  namespace   = "meltano"
  version     = "0.1.0"
  wait        = false
  # values = [
  #   "${file("values.yml")}"
  # ]

  # This is not a chart value, but just a way to trick helm_release into running every time.
  # Without this, helm_release only updates the release if the chart version (in Chart.yaml) has been updated
  set {
    name  = "timestamp"
    value = timestamp()
  }

  depends_on = [module.postgres]
}