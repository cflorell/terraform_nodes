# Immich authenticates against Authentik over OIDC rather than forward auth.
# Its mobile apps and share links cannot complete an interactive browser login,
# which forward auth would require on every request.

# Signing key for RS256 id_tokens. Without one Authentik signs with HS256, which
# does not match Immich's default signingAlgorithm.
data "authentik_certificate_key_pair" "default" {
  name = "authentik Self-signed Certificate"
}

data "authentik_property_mapping_provider_scope" "oidc" {
  managed_list = [
    "goauthentik.io/providers/oauth2/scope-openid",
    "goauthentik.io/providers/oauth2/scope-email",
    "goauthentik.io/providers/oauth2/scope-profile",
  ]
}

# client_id and client_secret are supplied rather than generated, so the same
# values can live in ansible_nodes' secrets.sops.yaml for Immich's config
# without reading them back out of Terraform state.
resource "authentik_provider_oauth2" "immich" {
  name          = "immich"
  client_id     = var.immich_oidc_client_id
  client_secret = var.immich_oidc_client_secret
  client_type   = "confidential"

  authorization_flow = data.authentik_flow.provider_authorization.id
  invalidation_flow  = data.authentik_flow.provider_invalidation.id
  signing_key        = data.authentik_certificate_key_pair.default.id
  property_mappings  = data.authentik_property_mapping_provider_scope.oidc.ids

  # Must be set explicitly. The Terraform provider documents this attribute as
  # generated, but leaving it unset creates the provider with an empty list,
  # which makes Authentik reject every authorization request with a bare
  # "invalid_request" while logging "Invalid grant_type for provider".
  # authorization_code is the flow Immich uses; refresh_token lets sessions
  # renew without sending the user back through the browser.
  grant_types = [
    "authorization_code",
    "refresh_token",
  ]

  # The mobile scheme is what lets the Immich app complete the login. Without
  # it the web client works and the app silently fails at the callback.
  allowed_redirect_uris = [
    {
      matching_mode = "strict"
      url           = "https://immich.${var.porkbun_domain}/auth/login"
    },
    {
      matching_mode = "strict"
      url           = "https://immich.${var.porkbun_domain}/user-settings"
    },
    {
      matching_mode = "strict"
      url           = "https://immich.${var.porkbun_domain}/api/oauth/mobile-redirect"
    },
    {
      matching_mode = "strict"
      url           = "app.immich:///oauth-callback"
    },
  ]
}

resource "authentik_application" "immich" {
  name              = "Immich"
  slug              = "immich"
  protocol_provider = authentik_provider_oauth2.immich.id
  meta_description  = "Photo and video library"
  meta_launch_url   = "https://immich.${var.porkbun_domain}"
}

resource "authentik_policy_binding" "immich_group" {
  target = authentik_application.immich.uuid
  group  = authentik_group.homelab_users.id
  order  = 0
}
