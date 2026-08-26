class ApplicationController < ActionController::Base
  include Authentication

  allow_unauthenticated_access if: -> {
    !Rails.configuration.x.require_cataloger_access
  }

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes
end
