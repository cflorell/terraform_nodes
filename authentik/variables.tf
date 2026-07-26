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
