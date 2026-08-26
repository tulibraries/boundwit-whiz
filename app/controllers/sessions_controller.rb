class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[
    new
    saml
    failure
  ]

  skip_before_action :verify_authenticity_token, only: :saml

  def new
  end

  def saml
    auth = request.env.fetch("omniauth.auth")

    auth.uid =
      auth.extra.raw_info[
        "urn:oid:2.16.840.1.113730.3.1.3"
      ]

    user = User.from_omniauth(auth)
    alma_user = Alma::User.find(auth.uid)

    unless alma_user.cataloger?
      redirect_to new_session_path,
        alert: "You must have the Cataloger role in Alma to use this application."
    end

    start_new_session_for user

    redirect_to root_path,
      notice: "Signed in with Temple Single Sign On."
  end

  def failure
    redirect_to new_session_path,
      alert: "Temple Single Sign On failed."
  end

  def destroy
    terminate_session
    redirect_to new_session_path, status: :see_other
  end

  private
end
