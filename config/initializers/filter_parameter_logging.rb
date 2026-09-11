# Be sure to restart your server when you modify this file.

# Configure parameters to be partially matched (e.g. passw matches password) and filtered from the log file.
# Use this to limit dissemination of sensitive information.
# See the ActiveSupport::ParameterFilter documentation for supported notations and behaviors.
Rails.application.config.filter_parameters += [
  :legal_name, :registration_number, :legal_email, :private_address,
  :evidence, :quote, :transcript, :description, :display_name_snapshot, :public_location_snapshot, :proof, :video,
  :referral_codes, :statement, :decision,
  :passw, :email, :secret, :token, :_key, :crypt, :salt, :certificate, :otp, :ssn, :cvv, :cvc, :phone, :address, :latitude, :longitude, :reason, :user_agent, :message, :body, :details, :agreement, :location, :bio, :ratings
]

Rails.application.config.filter_parameters += [ :code, :id_token, :access_token, :refresh_token, :client_secret, :credential, :receipt_token ]
