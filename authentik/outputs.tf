# These exist so `terraform plan` proves end to end that the provider
# authenticated, the embedded outpost was found and the built-in flows resolve,
# before any resource depends on them.

output "embedded_outpost_id" {
  description = "UUID of the embedded outpost that proxy providers attach to."
  value       = data.authentik_outpost.embedded.id
}

output "authorization_flow_id" {
  description = "UUID of the flow proxy providers use for authorization."
  value       = data.authentik_flow.provider_authorization.id
}

output "invalidation_flow_id" {
  description = "UUID of the flow proxy providers use for invalidation."
  value       = data.authentik_flow.provider_invalidation.id
}

output "group_ids" {
  description = "Authorization group UUIDs, bound to applications as policies."
  value = {
    homelab_users  = authentik_group.homelab_users.id
    homelab_admins = authentik_group.homelab_admins.id
  }
}

output "forward_auth_applications" {
  description = "External host per protected application. Each must match a caddy_reverse_proxies entry with forward_auth: true in ansible_nodes."
  value       = { for k, v in authentik_provider_proxy.forward_auth : k => v.external_host }
}
