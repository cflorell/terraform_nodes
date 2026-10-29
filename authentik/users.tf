# People with access to homelab applications.
#
# Declaring them here keeps group membership, which is what actually authorizes
# access to an application, reviewable in Git rather than clicked in a UI.
resource "authentik_user" "homelab" {
  for_each = var.homelab_users

  username  = each.key
  name      = each.value.name
  email     = each.value.email
  is_active = true
}

# Shared accounts used only to view albums in Immich. They are deliberately
# not members of homelab-users: access comes from the immich-family group,
# which only the Immich application binds.
#
# Passwords are not managed here. Set one in the Authentik admin UI after the
# first apply, otherwise the account cannot complete a login.
resource "authentik_user" "immich_family" {
  for_each = var.immich_family_users

  username  = each.key
  name      = each.value.name
  email     = each.value.email
  is_active = true
}
