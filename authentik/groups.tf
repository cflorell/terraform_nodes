# Authorization groups bound to applications in proxy_providers.tf.
#
# Neither group sets is_superuser. Authentik ships an "authentik Admins" group
# for that, and conflating "may reach this application" with "may administer
# Authentik" would make every application binding a privilege decision.
resource "authentik_group" "homelab_users" {
  name = "homelab-users"
}

resource "authentik_group" "homelab_admins" {
  name    = "homelab-admins"
  parents = [authentik_group.homelab_users.id]
}
