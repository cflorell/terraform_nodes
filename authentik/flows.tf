# Built-in flows referenced by proxy and OIDC providers. These ship with
# Authentik, so they are read rather than created. Confirm the slugs under
# Flows and Stages > Flows if a plan reports one as not found; the variables
# in variables.tf allow overriding them without editing this file.

data "authentik_flow" "provider_authorization" {
  slug = var.authorization_flow_slug
}

data "authentik_flow" "provider_invalidation" {
  slug = var.invalidation_flow_slug
}
