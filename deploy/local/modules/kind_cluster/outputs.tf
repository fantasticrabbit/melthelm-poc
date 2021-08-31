output "k8_host" {
    value = kind_cluster.meltano.endpoint
}

output "k8_client_certificate" {
    value = kind_cluster.meltano.client_certificate
}

output "k8_client_key" {
    value = kind_cluster.meltano.client_key
}

output "k8_ca_certificate" {
    value = kind_cluster.meltano.cluster_ca_certificate
}