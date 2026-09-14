require "rails_helper"

RSpec.describe Chains do
  let(:user) { create(:profile).user }
  let(:admin) { create(:user, :super_admin) }
  before { point_rules; load Rails.root.join("db/community_seeds.rb") }

  it "dépasse dix maillons, interdit branches, auto-validation et boucles, et fige le contrat" do
    chain = Chains.create!(actor: user, name: "Le relais")
    provider = user
    12.times do
      service, token = Chains.invite!(chain: chain, actor: provider, description: "Aide rendue")
      expect(service.invitation_token_digest).not_to eq(token)
      expect { Chains.invite!(chain: chain, actor: provider, description: "Branche") }.to raise_error(Exchanges::Invalid)
      expect { Chains.confirm!(service: service, actor: provider) }.to raise_error(Exchanges::Invalid)
      beneficiary = create(:user)
      2.times { Chains.confirm!(service: service, actor: beneficiary) }
      expect { Chains.confirm!(service: service, actor: create(:user)) }.to raise_error(Exchanges::Invalid)
      provider = beneficiary
    end
    expect(chain.chain_services.where(status: "confirmed").count).to eq(12)
    expect(ChainReward.sum(:points)).to eq(120)
    expect(PointOperation.count).to eq(12)
    expect { ChainReward.first.update!(points: 99) }.to raise_error(ActiveRecord::ReadOnlyRecord)
    service, = Chains.invite!(chain: chain, actor: provider, description: "Suite")
    expect { Chains.confirm!(service: service, actor: user) }.to raise_error(Exchanges::Invalid)
    expect { chain.update!(creator: admin) }.to raise_error(ActiveRecord::StatementInvalid)
    expect { chain.chain_services.first.update!(description: "Réécrit") }.to raise_error(ActiveRecord::StatementInvalid)
  end

  it "expire les invitations, protège le prestataire et permet la médiation" do
    chain = Chains.create!(actor: user, name: "Entraide")
    service, = Chains.invite!(chain: chain, actor: user, description: "Aide")
    expect { Chains.invite!(chain: chain, actor: admin, description: "Vol") }.to raise_error(Pundit::NotAuthorizedError)
    travel_to 8.days.from_now do
      expect { Chains.confirm!(service: service, actor: admin) }.to raise_error(Exchanges::Invalid)
      service, = Chains.invite!(chain: chain, actor: user, description: "Nouvelle invitation")
    end
    expect(chain.chain_services.where(status: "expired").count).to eq(1)
    user.update!(status: "suspended")
    expect { Chains.confirm!(service: service, actor: admin) }.to raise_error(Exchanges::Invalid)
    expect { Chains.create!(actor: user, name: "Non") }.to raise_error(Pundit::NotAuthorizedError)
    expect { Chains.moderate!(chain: chain, actor: user, status: "closed", reason: "Non") }.to raise_error(Pundit::NotAuthorizedError)
    expect { Chains.moderate!(chain: chain, actor: admin, status: "unknown", reason: "Non") }.to raise_error(Exchanges::Invalid)
    user.update!(status: "active")
    Chains.moderate!(chain: chain, actor: admin, status: "disputed", reason: "Médiation")
    expect { Chains.confirm!(service: service, actor: admin) }.to raise_error(Exchanges::Invalid)
    expect { Chains.invite!(chain: chain, actor: user, description: "Non") }.to raise_error(Exchanges::Invalid)
    Chains.moderate!(chain: chain, actor: admin, status: "active", reason: "Résolu")
    Chains.confirm!(service: service, actor: admin)
  end

  it "simule, publie les profondeurs bornées et respecte les plafonds individuels et mensuels" do
    version = ChainRuleVersion.create!(name: "Trois derniers", effective_at: 1.hour.from_now, reward_scope: "last_n_eligible", rewarded_previous_links: 3, max_points_per_member: 15, max_points_per_link: 25)
    expect { Chains.rule!(version: version, actor: user, action: "simulate", reason: "Non") }.to raise_error(Pundit::NotAuthorizedError)
    expect { Chains.rule!(version: version, actor: admin, action: "publish", reason: "Non") }.to raise_error(Exchanges::Invalid)
    Chains.rule!(version: version, actor: admin, action: "simulate", reason: "Mesure")
    expect(version.simulation["maximum_per_validation"]).to eq(25)
    expect { Chains.rule!(version: version, actor: admin, action: "unknown", reason: "Non") }.to raise_error(Exchanges::Invalid)
    Chains.rule!(version: version, actor: admin, action: "publish", reason: "Recette")
    expect { version.update!(points_per_validation: 100) }.to raise_error(ActiveRecord::ReadOnlyRecord)
    travel_to 2.hours.from_now do
      chain = Chains.create!(actor: user, name: "Profondeur")
      provider = user
      5.times do
        service, = Chains.invite!(chain: chain, actor: provider, description: "Service")
        provider = create(:user)
        Chains.confirm!(service: service, actor: provider)
        expect(service.chain_rewards.sum(:points)).to be <= 25
      end
      expect(ChainReward.where(recipient: user).sum(:points)).to eq(15)
      expect(ChainReward.where(points: 0)).to exist
      expect(chain.chain_rule_version).to eq(version)
    end
    limited = ChainRuleVersion.create!(name: "Deux", effective_at: 3.hours.from_now, length_mode: "limited", max_links: 2, reward_scope: "all_eligible")
    Chains.rule!(version: limited, actor: admin, action: "simulate", reason: "Mesure")
    Chains.rule!(version: limited, actor: admin, action: "publish", reason: "Recette")
    travel_to 4.hours.from_now do
      chain = Chains.create!(actor: user, name: "Limite")
      provider = user
      2.times do
        service, = Chains.invite!(chain: chain, actor: provider, description: "Service")
        provider = create(:user)
        Chains.confirm!(service: service, actor: provider)
      end
      expect { Chains.invite!(chain: chain, actor: provider, description: "Non") }.to raise_error(Exchanges::Invalid)
      expect(PointEntry.joins(:point_operation).where(point_account: PointAccount.for!(user), point_operations: { kind: "chain_reward" }).sum(:amount)).to eq(30)
    end
    expect(ChainRuleVersion.new(name: "Non", effective_at: Time.current, reward_scope: "all_eligible")).not_to be_valid
    expect(ChainRuleVersion.new(name: "Non", effective_at: Time.current, max_links: 10)).not_to be_valid
  end
end
