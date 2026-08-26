# spec/lib/alma/user_spec.rb
require "rails_helper"

RSpec.describe Alma::User do
  it "includes the user override" do
    expect(described_class.ancestors).to include(Alma::UserOverrides)
  end

  describe "#cataloger?" do
    def build_user(parsed_response)
      response = instance_double(
        HTTParty::Response,
        parsed_response: parsed_response,
        code: 200
      )

      described_class.new(response)
    end

    it "returns false when the user has no roles" do
      user = build_user(
        "user_role" => nil
      )

      expect(user.cataloger?).to be false
    end

    it "returns true when the user has the Cataloger role" do
      user = build_user(
        "user_role" => [
          {
            "role_type" => {
              "desc" => "Cataloger"
            }
          }
        ]
      )

      expect(user.cataloger?).to be true
    end

    it "returns false when the user does not have the Cataloger role" do
      user = build_user(
        "user_role" => [
          {
            "role_type" => {
              "desc" => "Circulation Desk Operator"
            }
          }
        ]
      )

      expect(user.cataloger?).to be false
    end

    it "returns true when Cataloger is one of several roles" do
      user = build_user(
        "user_role" => [
          {
            "role_type" => {
              "desc" => "Circulation Desk Operator"
            }
          },
          {
            "role_type" => {
              "desc" => "Cataloger"
            }
          }
        ]
      )

      expect(user.cataloger?).to be true
    end
  end
end
