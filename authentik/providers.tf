terraform {
  required_version = ">= 1.6.0"
  backend "http" {}

  required_providers {
    authentik = {
      source  = "goauthentik/authentik"
      version = "~> 2026.5"
    }
  }
}

# The URL is the public Caddy hostname rather than the LXC address, so the
# wildcard Let's Encrypt cert verifies and no insecure flag is needed. The auth
# host is never placed behind forward auth, so no redirect intercepts the API.
provider "authentik" {
  url   = var.authentik_url
  token = var.authentik_token
}
