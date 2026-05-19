# outputs.tf

output "node_nat_ips" {
  description = "External NAT IPs for all nodes (volatile on spot preemption)"
  value = {
    for k, v in google_compute_instance.node :
    k => try(v.network_interface[0].access_config[0].nat_ip, null)
  }
}

output "node_internal_ips" {
  description = "Internal network IPs (stable across preemptions)"
  value = {
    for k, v in google_compute_instance.node :
    k => v.network_interface[0].network_ip
  }
}

output "node_self_links" {
  description = "Self-links for use in firewall rules and Rancher registration"
  value = {
    for k, v in google_compute_instance.node : k => v.self_link
  }
}

output "node_instance_ids" {
  description = "GCP numeric instance IDs (stable, useful for log correlation)"
  value = {
    for k, v in google_compute_instance.node : k => v.instance_id
  }
}

output "node_statuses" {
  description = "Current instance status (RUNNING/TERMINATED/STAGING)"
  value = {
    for k, v in google_compute_instance.node : k => v.current_status
  }
}

output "node_is_preemptible" {
  description = "Confirms spot/preemptible provisioning model per node"
  value = {
    for k, v in google_compute_instance.node :
    k => v.scheduling[0].preemptible
  }
}

# yes claude helped with this
