require "rails_helper"

RSpec.describe "SAML authentication", type: :request do
  before do
    OmniAuth.config.test_mode = true

    OmniAuth.config.mock_auth[:saml] = OmniAuth::AuthHash.new(
      provider: "saml",
      uid: "915619567",
      info: {
        email: "user@temple.edu"
      },
      extra: {
        raw_info: {
          "urn:oid:2.16.840.1.113730.3.1.3" => "915619567"
        }
      }
    )
  end

  after do
    OmniAuth.config.test_mode = false
    OmniAuth.config.mock_auth[:saml] = nil
  end

  it "allows an Alma cataloger to sign in" do
    alma_user = instance_double(
      Alma::User,
      cataloger?: true
    )

    allow(Alma::User)
      .to receive(:find)
      .with("915619567")
      .and_return(alma_user)

    post "/users/auth/saml/callback"

    expect(response).to redirect_to(root_path)
  end
end
