FactoryBot.define do
  factory :profile do
    user
    sequence(:display_name) { |n| "Camille #{n}" }
    public_city { "Lyon" }
    status { "published" }
  end
  factory :category do
    sequence(:name) { |n| "Catégorie #{n}" }
    sequence(:slug) { |n| "categorie-#{n}" }
  end
  factory :listing do
    user { association(:profile).user }
    category
    title { "Un coup de main au jardin" }
    description { "Je vous aide à prendre soin de vos plantes et de votre jardin." }
    city { "Lyon" }
    status { "published" }
    published_at { Time.current }
    service_location_mode { "remote" }
  end
  factory :service_request do
    listing
    requester { association(:profile).user }
    provider { listing.user }
    expires_at { 14.days.from_now }
  end
  factory :review_criterion do
    sequence(:key) { |n| "criterion_#{n}" }
    label { "Communication" }
  end
  factory :content_version do
    author { association(:user, :super_admin) }
    kind { "article" }
    sequence(:slug) { |n| "article-#{n}" }
    title { "La vie du quartier" }
    body { "Un récit original de notre communauté." }
    version { 1 }
  end
end
