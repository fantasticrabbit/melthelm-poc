resource "helm_release" "postgres" {
  name        = "postgresql"
  repository  = "https://charts.bitnami.com/bitnami"
  chart       = "postgresql"
  namespace   = "meltano"
  version     = "10.5.3"
  wait        = true

  set {
    name  = "postgresqlDatabase"
    value = "postgres"
  }

  set {
    name  = "postgresqlUsername"
    value = "postgres"
  }

  set {
    name  = "postgresqlPassword"
    value = "postgres"
  }

  set {
    name = "initdbScripts.init\\.sql"
    value = <<EOF
  CREATE DATABASE meltano OWNER postgres;
  CREATE DATABASE airflow OWNER postgres;
  EOF
  }

  # This is not a chart value, but just a way to trick helm_release into running every time.
  # Without this, helm_release only updates the release if the chart version (in Chart.yaml) has been updated
  set {
    name  = "timestamp"
    value = timestamp()
  }
}