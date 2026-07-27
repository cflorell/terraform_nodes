# Authorization groups bound to applications in proxy_providers.tf.
resource "authentik_group" "homelab_users" {
  name  = "homelab-users"
  users = [for u in authentik_user.homelab : tonumber(u.id)]
}

resource "authentik_group" "homelab_admins" {
  name    = "homelab-admins"
  parents = [authentik_group.homelab_users.id]
}
