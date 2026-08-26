class User < ApplicationRecord
  has_secure_password validations: false
  has_many :sessions, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  def self.from_omniauth(auth)
    user = find_or_initialize_by(uid: auth.uid)

    user.assign_attributes(
      email_address: auth.info.email,
      provider: auth.provider,
      first_name: auth.info.first_name,
      last_name: auth.info.last_name
    )

    user.save!
    user
  end
end
