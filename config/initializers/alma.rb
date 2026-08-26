Alma.configure do |config|
  config.apikey = Rails.application.credentials.dig(:alma, :api_key)
end

Rails.application.reloader.to_prepare do
  # Instance method overrides
  Alma::Bib.prepend(Alma::BibOverrides) unless Alma::Bib < Alma::BibOverrides
  Alma::BibHolding.prepend(Alma::BibHoldingOverrides) unless Alma::BibHolding < Alma::BibHoldingOverrides
  Alma::ResultSet.prepend(Alma::ResultSetOverrides) unless Alma::ResultSet < Alma::ResultSetOverrides
  Alma::User.prepend(Alma::UserOverrides) unless Alma::User < Alma::UserOverrides

  # Class method overrides.
  Alma::Bib.singleton_class.prepend(Alma::BibClassOverrides) unless
    Alma::Bib.singleton_class < Alma::BibClassOverrides
end
