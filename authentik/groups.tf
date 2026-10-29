# Authorization groups bound to applications in proxy_providers.tf.
resource "authentik_group" "homelab_users" {
  name  = "homelab-users"
  users = [for u in authentik_user.homelab : tonumber(u.id)]
}

resource "authentik_group" "homelab_admins" {
  name    = "homelab-admins"
  parents = [authentik_group.homelab_users.id]
}

# Immich-only access for shared family accounts. The Immich application binds
# this group alongside homelab-users; its policy engine mode is "any", so the
# bindings are alternative ways in rather than a requirement to be in both.
resource "authentik_group" "immich_family" {
  name  = "immich-family"
  users = [for u in authentik_user.immich_family : tonumber(u.id)]
}
