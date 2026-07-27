variable "authentik_url" {
  description = "Base URL of the Authentik instance as served by Caddy, e.g. https://auth.example.com."
  type        = string
}

variable "authentik_token" {
  description = "Authentik API token. Provisioned by AUTHENTIK_BOOTSTRAP_TOKEN in ansible_nodes' authentik env template, so the same value lives in both secret stores."
  type        = string
  sensitive   = true
}

variable "porkbun_domain" {
  description = "Wildcard domain Caddy serves. Protected applications are reached at <app>.<porkbun_domain>."
  type        = string
}

variable "homelab_users" {
  description = "People granted access to homelab applications, keyed by Authentik username. Real names and addresses live in tfvars because this repository is public. The address must match the account in each downstream application: OIDC auto-registration matches on email, and a mismatch creates a second, empty account instead of linking the existing one."
  type = map(object({
    name  = string
    email = string
  }))
  default = {}
}

variable "immich_oidc_client_id" {
  description = "OIDC client ID for Immich. Must match immich_oidc_client_id in ansible_nodes' secrets.sops.yaml."
  type        = string
}

variable "immich_oidc_client_secret" {
  description = "OIDC client secret for Immich. Must match immich_oidc_client_secret in ansible_nodes' secrets.sops.yaml."
  type        = string
  sensitive   = true
}

variable "authorization_flow_slug" {
  description = "Built-in flow proxy and OIDC providers use to authorize a request. Implicit consent skips the per-application approval prompt, which suits a single-household deployment."
  type        = string
  default     = "default-provider-authorization-implicit-consent"
}

variable "invalidation_flow_slug" {
  description = "Built-in flow providers use on logout. This is the provider-scoped flow (\"Logged out of application\"), not default-invalidation-flow, which logs the session out of Authentik itself."
  type        = string
  default     = "default-provider-invalidation-flow"
}
