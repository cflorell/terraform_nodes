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
