# Production keys belong to credentials or the Rails encryption environment variables.
# Local keys are derived from the app secret, never from a value committed to Git.
unless Rails.env.production?
  %i[primary_key deterministic_key key_derivation_salt].each do |key|
    Rails.application.config.active_record.encryption.public_send("#{key}=",
      Rails.application.key_generator.generate_key("seos-encryption-#{key}", 32).unpack1("H*"))
  end
end

%i[primary_key deterministic_key key_derivation_salt].each do |key|
  value = ENV["ACTIVE_RECORD_ENCRYPTION_#{key.to_s.upcase}"]
  Rails.application.config.active_record.encryption.public_send("#{key}=", value) if value.present?
end
