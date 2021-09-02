# Create a local Kubernetes cluster for Meltano
resource "kind_cluster" "meltano" {
  name = "meltano-cluster"
  kind_config {
    kind        = "Cluster"
    api_version = "kind.x-k8s.io/v1alpha4"
    # Add ref to local Docker Registry (created below)
    containerd_config_patches = [
      <<-TOML
      [plugins."io.containerd.grpc.v1.cri".registry.mirrors."registry:5000"]
        endpoint = ["http://registry:5000"]
      TOML
    ]
    # Add control-plane Node
    node {
      role = "control-plane"
      # Configure Ingress
      kubeadm_config_patches = [
        <<-TOML
        kind: InitConfiguration
        nodeRegistration:
          kubeletExtraArgs:
            node-labels: "ingress-ready=true"
        TOML
      ]
      extra_port_mappings {
        container_port = 80
        host_port      = 80
        protocol       = "TCP"
      }
      extra_port_mappings {
        container_port = 443
        host_port      = 443
        protocol       = "TCP"
      }
      extra_port_mappings {
        container_port = 5432
        host_port      = 5432
        protocol       = "TCP"
      }
    }
    # Add worker Node
    node {
      role = "worker"
      kubeadm_config_patches = [
        <<-TOML
        kind: JoinConfiguration
        nodeRegistration:
          kubeletExtraArgs:
            node-labels: "has-cpu=true"
        TOML
      ]
      # Mount orchestrate folder as airflow_root
      # This is used later in the Airflow Helm chart to provide 'live' access to dags
      extra_mounts {
        host_path      = abspath("../../orchestrate/")
        container_path = "/airflow_root"
      }
    }
  }
  provisioner "local-exec" {
    # Install kind-specific nginx ingress controller
    # TODO: Can this be moved to helm?
    command = <<-EOT
      kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
      kubectl wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=300s
    EOT
  }
}

# Deploy prometheus for monitoring
resource "kubernetes_namespace" "prometheus" {
  metadata {
    name = "prometheus"
  }
  depends_on = [kind_cluster.meltano]
  count = "${var.include_prometheus == true ? 1 : 0}"
}

resource "helm_release" "prometheus" {
  name        = "prometheus"
  repository  = "https://prometheus-community.github.io/helm-charts"
  chart       = "prometheus"
  namespace   = "prometheus"
  wait        = false
  depends_on = [kubernetes_namespace.prometheus]
  count = "${var.include_prometheus == true ? 1 : 0}"
}

# Start a registry container
resource "docker_container" "registry" {
  name    = "registry"
  image   = "registry:2"
  restart = "always"
  ports {
    internal = "5000"
    external = "5000"
  }
  networks_advanced {
    name = "kind"
  }
  depends_on = [kind_cluster.meltano]
  lifecycle {
    ignore_changes = [image]
  }
}

# Create Meltano namespace
resource "kubernetes_namespace" "meltano" {
  metadata {
    name = "meltano"
  }
  depends_on = [kind_cluster.meltano]
}