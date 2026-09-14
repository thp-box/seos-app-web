FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "membre#{n}@example.test" }
    password { "UnMotDePasseSolide!42" }
    confirmed_at { Time.current }
    status { :active }
    trait(:admin) { role { :admin } }
    trait(:super_admin) { role { :super_admin } }
    trait :unconfirmed do
      confirmed_at { nil }
      status { :pending }
    end
  end
  factory :admin_permission_grant do
    association :user, factory: [ :user, :admin ]
    association :granted_by, factory: [ :user, :super_admin ]
    permission { "users.read" }
    granted_at { Time.current }
    expires_at { 1.day.from_now }
    reason { "Gestion quotidienne" }
  end
  factory :organization do
    sequence(:name) { |n| "Entraide #{n}" }
    sequence(:slug) { |n| "entraide-#{n}" }
    kind { :association }
    status { :verified }
  end
  factory :organization_membership do
    user
    organization
    role { :editor }
  end
end
