# The embedded outpost ships with Authentik and runs inside the server
# container, so there is no separate container to deploy and nothing here
# creates it. It is read rather than managed: adopting it into state would put
# Terraform in charge of every one of its settings, including ones configured
# elsewhere.
#
# Proxy providers are attached to it individually via
# authentik_outpost_provider_attachment in proxy_providers.tf, which leaves the
# rest of the outpost untouched.
data "authentik_outpost" "embedded" {
  name = "authentik Embedded Outpost"
}
