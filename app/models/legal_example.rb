# Editable demonstration content transcribed from the supplied maquette.
class LegalExample
  def self.attributes_for(slug)
    JSON.parse(Rails.root.join("config/studio/legal_examples.json").read).fetch(slug)
  end

  def self.document(slug)
    ContentVersion.new(attributes_for(slug).merge(kind: "legal", slug: slug))
  end
end
