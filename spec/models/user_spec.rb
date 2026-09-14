require "rails_helper"
RSpec.describe User, :"F-003", type: :model do
  it "normalise l'e-mail et assure son unicité jusque dans SQLite" do
    user = create(:user, email: "  Alice@Example.Test ")
    expect(user.email).to eq("alice@example.test")
    expect(build(:user, email: "ALICE@example.test")).not_to be_valid
    expect { User.insert_all!([ user.attributes.except("id").merge("email" => "ALICE@example.test") ]) }.to raise_error(ActiveRecord::StatementInvalid)
  end

  it "refuse les rôles arbitraires, même en accès SQL" do
    expect(build(:user, role: "association")).not_to be_valid
    user = create(:user)
    expect { user.update_column(:role, "association") }.to raise_error(ActiveRecord::StatementInvalid)
  end

  it "ne réactive jamais un compte suspendu à sa confirmation" do
    user = create(:user, :unconfirmed, status: :suspended)
    user.confirm
    expect(user.reload).to be_suspended
    expect(user).not_to be_active_for_authentication
  end

  it "masque le domaine et la quasi-totalité de l'identifiant" do
    expect(build(:user, email: "confidentiel@association.fr").masked_email).to eq("c***@***")
  end
end
