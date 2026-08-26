Rails.application.config.middleware.use OmniAuth::Builder do
  idp_metadata_parser = OneLogin::RubySaml::IdpMetadataParser.new
  idp_metadata = idp_metadata_parser.parse_remote_to_hash(Rails.configuration.omniauth["saml_idp_metadata_url"])

  provider :saml, idp_metadata.merge(
    compress_request: false,
    certificate: Rails.configuration.omniauth["saml_certificate"],
    private_key: Rails.configuration.omniauth["saml_private_key"],
    assertion_consumer_service_url: Rails.configuration.omniauth["assertion_consumer_service_url"],
    idp_sso_service_url: Rails.configuration.omniauth["idp_sso_service_url"],
    issuer: Rails.configuration.omniauth["saml_issuer"],
    idp_slo_service_binding: :redirect,
    idp_sso_service_binding: :post,
    request_attributes: {},
    name_identifier_format:  "urn:oasis:names:tc:SAML:2.0:nameid-format:persistent",
    attribute_statements: {
      uid:         [ "urn:oid:2.16.840.1.113730.3.1.3" ],
      nickname:    [ "urn:oid:0.9.2342.19200300.100.1.1" ],
      email:       [ "urn:oid:0.9.2342.19200300.100.1.3" ],
      first_name:  [ "urn:oid:1.3.6.1.4.1.44987.1.1.2.1.24" ],
      last_name:   [ "urn:oid:1.3.6.1.4.1.44987.1.1.2.1.25" ]
    },
    security: {
      authn_requests_signed: true,
      want_assertions_signed: true,
      want_assertions_encrypted: true,
      metadata_signed: false,
      digest_method: "http://www.w3.org/2001/04/xmlenc#sha256",
      signature_method: "http://www.w3.org/2001/04/xmldsig-more#rsa-sha256"
    }
  )
end

OmniAuth.config.logger = Rails.logger

OmniAuth.config.request_validation_phase =
  OmniAuth::AuthenticityTokenProtection.new(
    key: :_csrf_token
  )

# Doing this to keep consitant with what we do in librarysearch
OmniAuth.config.path_prefix = "/users/auth"

OmniAuth.config.on_failure = Proc.new do |env|
  SessionsController.action(:failure).call(env)
end
