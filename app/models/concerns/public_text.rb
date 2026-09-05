module PublicText
  extend ActiveSupport::Concern
  CONTACT_PATTERN = /[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}|(?:\+33|0)[1-9](?:[ .-]?\d{2}){4}/i
  def validate_public_text(*fields)
    fields.each do |field|
      errors.add(field, "ne doit pas contenir de téléphone ou d’e-mail") if public_send(field).to_s.match?(CONTACT_PATTERN)
    end
  end
end
