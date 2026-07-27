# Multi-factor enforcement on the login flow.

data "authentik_stage" "totp_setup" {
  name = "default-authenticator-totp-setup"
}

data "authentik_stage" "webauthn_setup" {
  name = "default-authenticator-webauthn-setup"
}

resource "authentik_stage_authenticator_validate" "mfa" {
  name = "default-authentication-mfa-validation"

  not_configured_action = "configure"

  # Offered when an account has no device yet. Recovery codes
  # (default-authenticator-static-setup) are deliberately absent: they are a
  # backup for an existing factor, not a factor to enrol as the only one.
  configuration_stages = [
    data.authentik_stage.totp_setup.id,
    data.authentik_stage.webauthn_setup.id,
  ]

  # Restated at current values so adoption does not reset them. device_classes
  # stays broad so any already-enrolled device type still satisfies the check,
  # including recovery codes.
  device_classes = [
    "static",
    "totp",
    "webauthn",
    "duo",
    "sms",
    "email",
  ]

  last_auth_threshold        = "seconds=0"
  webauthn_user_verification = "preferred"

  email_otp_throttling_factor  = 1
  sms_otp_throttling_factor    = 1
  totp_otp_throttling_factor   = 1
  static_otp_throttling_factor = 1
}
