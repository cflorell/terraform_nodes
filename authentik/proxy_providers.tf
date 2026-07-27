# Applications protected by Authentik forward auth.
#
# Adding an entry here and setting forward_auth: true on the matching
# caddy_reverse_proxies entry in ansible_nodes' host_vars/docker is the whole
# process for protecting a service. The two must agree: external_host below is
# derived from the map key, so the key must equal the Caddy subdomain.
#
# Do not add applications with native clients. Mobile apps, TV clients and
# share links cannot complete an interactive browser login and will break;
# those integrate with Authentik over OIDC instead. Never add the auth host,
# which would place Authentik behind itself.
# Currently empty: every WAN-facing service either has native clients and uses
# OIDC instead, or is LAN-only and needs no Authentik at all. The machinery is
# kept ready because that changes the moment a browser-only service is exposed.
#
#   locals {
#     forward_auth_applications = {
#       example = {
#         display_name = "Example"
#         description  = "What it is"
#         group        = authentik_group.homelab_users.id
#       }
#     }
#   }
locals {
  forward_auth_applications = {}
}

# forward_single: the outpost identifies the application from the Host header,
# so one embedded outpost serves every entry and each keeps its own
# authorization policy. forward_domain would collapse them into a single
# all-or-nothing application.
resource "authentik_provider_proxy" "forward_auth" {
  for_each = local.forward_auth_applications

  name               = "${each.key}-proxy"
  mode               = "forward_single"
  external_host      = "https://${each.key}.${var.porkbun_domain}"
  authorization_flow = data.authentik_flow.provider_authorization.id
  invalidation_flow  = data.authentik_flow.provider_invalidation.id
}

resource "authentik_application" "forward_auth" {
  for_each = local.forward_auth_applications

  name              = each.value.display_name
  slug              = each.key
  protocol_provider = authentik_provider_proxy.forward_auth[each.key].id
  meta_description  = each.value.description
  meta_launch_url   = "https://${each.key}.${var.porkbun_domain}"
}

# Attached one provider at a time so the embedded outpost's own configuration
# stays out of Terraform's hands.
resource "authentik_outpost_provider_attachment" "forward_auth" {
  for_each = local.forward_auth_applications

  outpost           = data.authentik_outpost.embedded.id
  protocol_provider = authentik_provider_proxy.forward_auth[each.key].id
}

# Without a binding an application admits every authenticated user. This
# restricts each one to the group named in the map above.
resource "authentik_policy_binding" "forward_auth_group" {
  for_each = local.forward_auth_applications

  target = authentik_application.forward_auth[each.key].uuid
  group  = each.value.group
  order  = 0
}
