if Rails.env.development?
  { "aide-a-la-personne" => "Aide à la personne", "services-creatifs" => "Services créatifs", "bien-etre" => "Bien-être", "transport" => "Transport" }.each do |slug, name|
    Category.find_or_create_by!(slug: slug) { |category| category.name = name }
  end
end
