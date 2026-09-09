require 'rails_helper'

RSpec.describe User, type: :model do
  describe ".from_omniauth" do
    let(:auth) do
      OmniAuth::AuthHash.new(
        uid: "abc123",
        provider: "azure_activedirectory_v2",
        info: {
          email: "USER@temple.edu",
          first_name: "David",
          last_name: "Kinzer"
        }
      )
    end

    it "creates a user from omniauth data" do
      user = described_class.from_omniauth(auth)

      expect(user).to have_attributes(
        uid: "abc123",
        provider: "azure_activedirectory_v2",
        email_address: "user@temple.edu",
        first_name: "David",
        last_name: "Kinzer"
      )
    end

    it "updates an existing user with the same uid" do
      user = described_class.create!(
        uid: "abc123",
        provider: "old-provider",
        email_address: "old@temple.edu"
      )

      expect {
        described_class.from_omniauth(auth)
      }.not_to change(described_class, :count)

      expect(user.reload).to have_attributes(
        provider: "azure_activedirectory_v2",
        email_address: "user@temple.edu",
        first_name: "David",
        last_name: "Kinzer"
      )
    end
  end

  describe "email normalization" do
    it "strips whitespace and downcases the email address" do
      user = described_class.create!(
        uid: "123",
        email_address: "  USER@TEMPLE.EDU  "
      )

      expect(user.email_address).to eq("user@temple.edu")
    end
  end
end
