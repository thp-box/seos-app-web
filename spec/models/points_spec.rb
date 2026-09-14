require "rails_helper"

RSpec.describe "Registre Points Services", :"F-040", :"F-041", :"F-042", :"F-043" do
  let(:user) { create(:profile).user }
  let(:admin) { create(:user, :super_admin) }
  before { point_rules }

  it "inscrit deux écritures équilibrées et empêche toute modification directe du registre ou des soldes" do
    operation = fund_points(user, 30)
    expect(operation.point_entries.sum(:amount)).to eq(0)
    expect(PointAccount.for!(user).balance).to eq(30)
    expect(PointAccount.sum(:balance)).to eq(0)
    [ operation, operation.point_entries.first ].each do |record|
      expect { record.destroy! }.to raise_error(record.is_a?(PointOperation) ? ActiveRecord::DeleteRestrictionError : ActiveRecord::ReadOnlyRecord)
      expect { record.class.where(id: record.id).delete_all }.to raise_error(ActiveRecord::StatementInvalid)
      expect { record.class.where(id: record.id).update_all(created_at: 1.day.ago) }.to raise_error(ActiveRecord::StatementInvalid)
    end
    expect { PointAccount.for!(user).update!(balance: 900) }.to raise_error(ActiveRecord::StatementInvalid)
    expect { PointAccount.create!(user: create(:user), balance: 10) }.to raise_error(ActiveRecord::StatementInvalid)
    expect { operation.point_entries.create!(point_account: PointAccount.for!(create(:user)), amount: 1, balance_after: 1) }.to raise_error(ActiveRecord::StatementInvalid)
    pending = PointOperation.create!(kind: "admin_adjustment", source: user, reason: "Test", idempotency_key: "pending")
    expect { pending.update!(status: "committed", committed_at: Time.current) }.to raise_error(ActiveRecord::StatementInvalid, /unbalanced/)
    expect { PointOperation.create!(kind: "admin_adjustment", source: user, reason: "Test", idempotency_key: "bad", status: "committed") }.to raise_error(ActiveRecord::StatementInvalid)
  end

  it "rejoue la même opération sans double crédit et refuse les collisions de sens ou de montant" do
    debit, credit = PointAccount.system!, PointAccount.for!(user)
    arguments = { debit: debit, credit: credit, amount: 30, key: "same", kind: "welcome_reward", source: user, reason: "Accueil" }
    operation = Points::Ledger.post!(**arguments)
    expect(Points::Ledger.post!(**arguments)).to eq(operation)
    expect { Points::Ledger.post!(**arguments.merge(amount: 31)) }.to raise_error(Exchanges::Invalid)
    [ 0, -1, 1.5, "30", 1_000_000 ].each { |amount| expect { Points::Ledger.post!(**arguments.merge(amount: amount)) }.to raise_error(Exchanges::Invalid) }
    expect { Points::Ledger.post!(**arguments.merge(debit: credit)) }.to raise_error(Exchanges::Invalid)
    expect(PointAccount.for!(user).balance).to eq(30)
  end

  %w[offer request].each do |intent|
    it "transfère au prestataire réel après deux confirmations pour une annonce #{intent}" do
      provider = create(:profile).user
      fund_points(user, 50)
      request = points_exchange(payer: user, provider: provider, intent: intent)
      request.listing.update!(intent: intent == "offer" ? "request" : "offer", exchange_mode: "gift")
      Exchanges.transition!(request: request, actor: user, action: "confirm", version: request.agreement_version)
      expect(PointAccount.for!(user).balance).to eq(50)
      Exchanges.transition!(request: request, actor: provider, action: "confirm", version: request.agreement_version)
      expect(PointAccount.for!(user).balance).to eq(30)
      expect(PointAccount.for!(provider).balance).to eq(20)
      expect(request.reload).to be_completed
      expect { Exchanges.transition!(request: request, actor: provider, action: "confirm", version: request.agreement_version) }.not_to change(PointOperation, :count)
      expect { Points::Settlement.call!(request, actor: admin) }.to raise_error(Pundit::NotAuthorizedError)
    end
  end

  it "annule la seconde confirmation si le solde est insuffisant, puis permet de la reprendre" do
    request = points_exchange(payer: user)
    expect { Points::Settlement.call!(request, actor: user) }.to raise_error(Exchanges::Invalid)
    expect { Exchanges.transition!(request: request, actor: user, action: "confirm", version: 0) }.to raise_error(Exchanges::Invalid)
    Exchanges.transition!(request: request, actor: user, action: "confirm", version: request.agreement_version)
    expect { Exchanges.transition!(request: request, actor: request.provider, action: "confirm", version: request.agreement_version) }.to raise_error(Exchanges::Invalid, /insuffisant/)
    expect(request.reload.provider_confirmed_at).to be_nil
    expect(request).to be_awaiting_confirmation
    fund_points(user)
    Exchanges.transition!(request: request, actor: request.provider, action: "confirm", version: request.agreement_version)
    expect(request.reload).to be_completed
  end

  it "bloque un transfert en litige et une confirmation portant sur un ancien montant" do
    request = points_exchange(payer: user)
    fund_points(user)
    old_version = request.agreement_version
    Exchanges.transition!(request: request, actor: user, action: "propose", terms: { scheduled_at: 1.day.from_now.iso8601, location: "Appel", mode: "remote", points: 25 })
    Exchanges.transition!(request: request, actor: request.provider, action: "agree", version: request.agreement_version)
    expect { Exchanges.transition!(request: request, actor: user, action: "confirm", version: old_version) }.to raise_error(Exchanges::Invalid)
    Exchanges.transition!(request: request, actor: user, action: "confirm", version: request.agreement_version)
    report = Report.create!(reporter: user, reportable: request, reason: "Litige")
    expect { Exchanges.transition!(request: request, actor: request.provider, action: "confirm", version: request.agreement_version) }.to raise_error(Exchanges::Invalid, /litige/)
    expect(request.reload.provider_confirmed_at).to be_nil
    report.update!(status: "resolved")
    Exchanges.transition!(request: request, actor: request.provider, action: "confirm", version: request.agreement_version)
    expect(PointAccount.for!(user).balance).to eq(75)
  end

  it "compense sans effacer l’original et refuse le découvert, les tiers et les inversions d’inverse" do
    original = fund_points(user, 30)
    expect { Points::Ledger.reverse!(original, actor: user, reason: "Test") }.to raise_error(Pundit::NotAuthorizedError)
    inverse = Points::Ledger.reverse!(original, actor: admin, reason: "Correction motivée")
    expect(inverse.reversed_operation).to eq(original)
    expect(PointAccount.for!(user).balance).to eq(0)
    expect(Points::Ledger.reverse!(original, actor: admin, reason: "Rejeu")).to eq(inverse)
    expect { Points::Ledger.reverse!(inverse, actor: admin, reason: "Test") }.to raise_error(Exchanges::Invalid)
    original = fund_points(user, 30)
    Points::Ledger.post!(debit: PointAccount.for!(user), credit: PointAccount.for!(create(:user)), amount: 30, key: "spent", kind: "service_transfer", source: user, reason: "Dépensé")
    expect { Points::Ledger.reverse!(original, actor: admin, reason: "Test") }.to raise_error(Exchanges::Invalid)
    expect(original.reload.reversal).to be_nil
  end

  it "prévisualise et confirme les petits ajustements, impose une seconde personne pour les gros" do
    manager = create(:user, :admin)
    create(:admin_permission_grant, user: manager, permission: "points.adjust")
    expect { Points::Adjustments.preview!(user: user, actor: user, amount: 5, reason: "Test") }.to raise_error(Pundit::NotAuthorizedError)
    preview = Points::Adjustments.preview!(user: user, actor: manager, amount: 50, reason: "Aide exceptionnelle")
    expect(preview.balance_before).to eq(0)
    expect { Points::Adjustments.commit!(preview, actor: user) }.to raise_error(Pundit::NotAuthorizedError)
    operation = Points::Adjustments.commit!(preview, actor: manager)
    expect(Points::Adjustments.commit!(preview, actor: manager)).to eq(operation)
    large = Points::Adjustments.preview!(user: user, actor: admin, amount: 101, reason: "Médiation")
    expect { Points::Adjustments.commit!(large, actor: admin) }.to raise_error(Pundit::NotAuthorizedError)
    Points::Adjustments.commit!(large, actor: create(:user, :super_admin))
    expect(PointAccount.for!(user).balance).to eq(151)
    negative = Points::Adjustments.preview!(user: user, actor: manager, amount: -1, reason: "Correction")
    Points::Adjustments.commit!(negative, actor: manager)
    expect(PointAccount.for!(user).balance).to eq(150)
    stale = Points::Adjustments.preview!(user: user, actor: manager, amount: 1, reason: "Test")
    fund_points(user, 1)
    expect { Points::Adjustments.commit!(stale, actor: manager) }.to raise_error(Exchanges::Invalid)
    expired = Points::Adjustments.preview!(user: user, actor: manager, amount: 1, reason: "Test")
    travel 11.minutes
    expect { Points::Adjustments.commit!(expired, actor: manager) }.to raise_error(Exchanges::Invalid)
  end

  it "accorde l’accueil une fois et exige un profil publié et un compte confirmé actif" do
    user.profile.update!(status: "draft")
    expect { Points::Rewards.welcome!(user) }.to raise_error(Exchanges::Invalid)
    user.profile.update!(status: "published")
    user.update!(status: "suspended")
    expect { Points::Rewards.welcome!(user) }.to raise_error(Exchanges::Invalid)
    user.update!(status: "active")
    Points::Rewards.welcome!(user)
    expect { Points::Rewards.welcome!(user) }.not_to change(PointOperation, :count)
    expect(PointAccount.for!(user).balance).to eq(30)
  end

  it "récompense une nouvelle annonce et trois demandes acceptées une fois, sans payer le brouillon" do
    create(:listing, user: user, status: "draft")
    Points::Rewards.sync!(user)
    expect(PointOperation.where(kind: "achievement_reward")).not_to exist
    listing = create(:listing, user: user)
    3.times { create(:service_request, requester: user, status: "accepted") }
    Points::Rewards.sync!(user)
    expect(PointAccount.for!(user).balance).to eq(20)
    expect { Points::Rewards.sync!(user) }.not_to change(PointOperation, :count)
    listing.update!(status: "paused")
    expect { Points::Rewards.sync!(user) }.not_to change(PointOperation, :count)
  end

  it "fige le barème des preuves, exige une revue indépendante et limite les répétitions mensuelles" do
    claim = Points::Rewards.submit!(user: user, kind: "share", evidence: "Publication faite ce mois, référence privée")
    expect(claim.amount).to eq(10)
    expect { Points::Rewards.submit!(user: user, kind: "share", evidence: "Doublon") }.to raise_error(ActiveRecord::RecordNotUnique)
    expect { Points::Rewards.review!(claim, actor: user, decision: "approved", reason: "Test") }.to raise_error(Pundit::NotAuthorizedError)
    expect { Points::Rewards.review!(claim, actor: admin, decision: "unknown", reason: "Test") }.to raise_error(Exchanges::Invalid)
    Points::Rewards.review!(claim, actor: admin, decision: "approved", reason: "Preuve vérifiée")
    expect { Points::Rewards.review!(claim, actor: admin, decision: "approved", reason: "Rejeu") }.not_to change(PointOperation, :count)
    expect { Points::Rewards.review!(claim, actor: admin, decision: "rejected", reason: "Test") }.to raise_error(Exchanges::Invalid)
    written = Points::Rewards.submit!(user: user, kind: "written", evidence: "Texte du témoignage")
    Points::Rewards.review!(written, actor: admin, decision: "rejected", reason: "Précisez le contexte")
    expect(written.reload.point_operation).to be_nil
    chain = Points::Rewards.submit!(user: user, kind: "chain", evidence: "Références de services validés")
    Points::Rewards.review!(chain, actor: admin, decision: "approved", reason: "Services vérifiés")
    expect(chain.reload.point_operation.kind).to eq("chain_reward")
    expect { Points::Rewards.submit!(user: user, kind: "payment", evidence: "Interdit") }.to raise_error(Exchanges::Invalid)
    travel_to 1.month.from_now.beginning_of_month
    expect { Points::Rewards.submit!(user: user, kind: "share", evidence: "Nouveau mois") }.to change(PointRewardClaim, :count).by(1)
  end

  it "crédite seulement la quête du principal, une fois dans sa vie malgré plusieurs filleuls" do
    sponsor = exempt_sponsor(user)
    2.times do
      newbie = create(:user)
      travel 2.minutes
      referral = support(newbie, sponsor: sponsor)
      newbie.update!(created_at: 31.days.ago)
      2.times { completed_exchange(newbie) }
      referral.update!(status: "confirmed", qualified_at: Time.current)
    end
    Points::Rewards.sync!(sponsor)
    expect(PointAccount.for!(sponsor).balance).to eq(15)
    expect(PointOperation.where(kind: "referral_reward").count).to eq(1)
    expect { Points::Rewards.sync!(sponsor) }.not_to change(PointOperation, :count)
  end

  it "lie la progression d’une série à sa version et ne compte chaque transfert qu’une fois" do
    fund_points(user, 200)
    rule = PointRuleVersion.current("engagement")
    6.times do
      request = completed_exchange(user)
      Points::Ledger.post!(debit: PointAccount.for!(user), credit: PointAccount.for!(request.provider), amount: 1, key: "transfer:#{request.id}", kind: "service_transfer", source: request, reason: "Test", rule: PointRuleVersion.current("valuation"))
      Points::Rewards.sync!(user)
    end
    expect(PointCycleProgress.where(user: user).count).to eq(2)
    first, second = PointCycleProgress.where(user: user).order(:cycle_number)
    expect(first.point_rule_version).to eq(rule)
    expect(first.point_operation.point_entries.where(amount: 1..).sum(:amount)).to eq(25)
    expect(second.operation_ids.size).to eq(1)
    expect { Points::Rewards.sync!(user) }.not_to change(PointOperation, :count)
    expect(Points::Rewards.level(user, rule)).to eq("silver")
  end

  it "valide les tranches continues, les bornes, les paramètres et une estimation déterministe" do
    rule = PointRuleVersion.current("valuation")
    expect(rule.estimate(0)["points_from"]).to eq(10)
    expect(rule.estimate(2000)["points_to"]).to eq(10)
    expect(rule.estimate(2001)["points_to"]).to eq(20)
    expect(rule.estimate(10_000)["points_to"]).to eq(50)
    [ -1, "20", 1_000_000_000 ].each { |n| expect { rule.estimate(n) }.to raise_error(Exchanges::Invalid) }
    [ {}, { "brackets" => [] }, { "brackets" => [ { "from_cents" => 1, "to_cents" => 2000, "points_from" => 10, "points_to" => 10 } ] } ].each do |config|
      expect(PointRuleVersion.new(family: "valuation", name: "Invalide", effective_at: Time.current, configuration: config)).not_to be_valid
    end
    config = PointRuleVersion::DEFAULT_ENGAGEMENT.deep_dup.merge("cycle_size" => 0)
    expect(PointRuleVersion.new(family: "engagement", name: "Invalide", effective_at: Time.current, configuration: config)).not_to be_valid
  end

  it "simule, planifie et restaure une version sans modifier une opération historique" do
    original = Points::Rewards.welcome!(user)
    config = PointRuleVersion::DEFAULT_ENGAGEMENT.deep_dup.merge("welcome" => 40)
    draft = PointRuleVersion.create!(family: "engagement", name: "V2", configuration: config, effective_at: 1.hour.from_now, created_by: admin)
    expect { Points::Rules.simulate!(draft, actor: user, reason: "Test") }.to raise_error(Pundit::NotAuthorizedError)
    expect { Points::Rules.publish!(draft, actor: admin, reason: "Test") }.to raise_error(Exchanges::Invalid)
    Points::Rules.simulate!(draft, actor: admin, reason: "Comparer les émissions")
    expect(draft.simulation["result"]["welcome"]).to eq(40)
    expect { Points::Rules.publish!(draft, actor: user, reason: "Test") }.to raise_error(Pundit::NotAuthorizedError)
    Points::Rules.publish!(draft, actor: admin, reason: "Simulation approuvée")
    expect(PointRuleVersion.current("engagement")).not_to eq(draft)
    travel 61.minutes
    expect(PointRuleVersion.current("engagement")).to eq(draft)
    expect(original.reload.point_entries.where(amount: 1..).sum(:amount)).to eq(30)
    expect { draft.update!(name: "Autre") }.to raise_error(ActiveRecord::ReadOnlyRecord)
    expect { PointRuleVersion.where(id: draft.id).update_all(name: "Autre") }.to raise_error(ActiveRecord::StatementInvalid)
    expect { PointRuleVersion.where(id: draft.id).delete_all }.to raise_error(ActiveRecord::StatementInvalid)
    expect { Points::Rules.rollback!(draft, actor: user, reason: "Test") }.to raise_error(Pundit::NotAuthorizedError)
    rollback = Points::Rules.rollback!(original.point_rule_version, actor: admin, reason: "Retour au barème initial")
    travel 2.minutes
    expect(PointRuleVersion.current("engagement")).to eq(rollback)
    expect(Points::Rewards.welcome!(user)).to eq(original)
    valuation = PointRuleVersion.create!(family: "valuation", name: "V2 repères", effective_at: 1.day.from_now, configuration: PointRuleVersion::DEFAULT_VALUATION)
    Points::Rules.simulate!(valuation, actor: admin, reason: "Bornes vérifiées")
    expect(valuation.simulation["result"].size).to eq(200)
  end

  it "diffère les récompenses au plafond sans annuler celles déjà acquises, puis reprend au mois suivant" do
    configuration = PointRuleVersion::DEFAULT_ENGAGEMENT.deep_dup.merge("monthly_cap" => 30)
    PointRuleVersion.create!(family: "engagement", name: "Plafond de test", status: "published", effective_at: Time.current, published_at: Time.current, configuration: configuration)
    Points::Rewards.welcome!(user)
    3.times { create(:listing, user: user) }
    PointRewardsJob.perform_now(user.id)
    expect(PointAccount.for!(user).balance).to eq(30)
    claim = Points::Rewards.submit!(user: user, kind: "share", evidence: "Partage de ce mois")
    expect { Points::Rewards.review!(claim, actor: admin, decision: "approved", reason: "Valide") }.to raise_error(Exchanges::Invalid, /plafond/)
    expect(claim.reload.status).to eq("pending")
    travel_to 1.month.from_now.beginning_of_month
    PointRewardsJob.perform_now(user.id)
    expect(PointAccount.for!(user).balance).to eq(60)
    expect(PointOperation.where(kind: "achievement_reward").count).to eq(3)
  end

  it "calcule les niveaux au moment de chaque série, même si le worker traite vingt transferts ensemble" do
    fund_points(user, 200)
    20.times do
      request = completed_exchange(user)
      Points::Ledger.post!(debit: PointAccount.for!(user), credit: PointAccount.for!(request.provider), amount: 1, key: "transfer:#{request.id}", kind: "service_transfer", source: request, reason: "Test", rule: PointRuleVersion.current("valuation"))
    end
    Points::Rewards.sync!(user)
    bonuses = PointCycleProgress.where(user: user).order(:cycle_number).map { |progress| progress.point_operation.point_entries.where(amount: 1..).sum(:amount) }
    expect(bonuses).to eq([ 25, 25, 25, 30 ])
    expect(Points::Rewards.level(user, PointRuleVersion.current("engagement"))).to eq("gold")
    expect { PointMaintenanceJob.perform_now }.to have_enqueued_job(PointRewardsJob).at_least(:once)
  end

  it "ne change pas un barème après simulation et refuse trous et chevauchements" do
    version = PointRuleVersion.create!(family: "valuation", name: "Projet", configuration: PointRuleVersion::DEFAULT_VALUATION, effective_at: 1.day.from_now)
    Points::Rules.simulate!(version, actor: admin, reason: "Test")
    version.update!(effective_at: 2.days.from_now)
    expect { Points::Rules.publish!(version, actor: admin, reason: "Test") }.to raise_error(Exchanges::Invalid)
    config = PointRuleVersion::DEFAULT_VALUATION.deep_dup
    config["brackets"][1]["from_cents"] = 2000
    expect(PointRuleVersion.new(family: "valuation", name: "Chevauchement", effective_at: Time.current, configuration: config)).not_to be_valid
    config["brackets"][1]["from_cents"] = 2002
    expect(PointRuleVersion.new(family: "valuation", name: "Trou", effective_at: Time.current, configuration: config)).not_to be_valid
    expect { Points::Rules.rollback!(version, actor: admin, reason: "Test") }.to raise_error(Exchanges::Invalid)
    expect { Points::Rules.simulate!(PointRuleVersion.current("valuation"), actor: admin, reason: "Test") }.to raise_error(Exchanges::Invalid)
  end

  it "protège les aperçus et preuves contre les changements après validation" do
    adjustment = Points::Adjustments.preview!(user: user, actor: admin, amount: 1, reason: "Test")
    expect { adjustment.update!(amount: 1000) }.to raise_error(ActiveRecord::StatementInvalid)
    claim = Points::Rewards.submit!(user: user, kind: "video", evidence: "Référence du témoignage filmé")
    expect { claim.update!(amount: 1000) }.to raise_error(ActiveRecord::StatementInvalid)
    Points::Rewards.review!(claim.reload, actor: admin, decision: "approved", reason: "Vérifié")
    expect { claim.update!(status: "pending") }.to raise_error(ActiveRecord::StatementInvalid)
  end

  it "applique aussi le plafond chaîne à des preuves de mois anciens validées ensemble" do
    claims = 4.times.map do |index|
      PointRewardClaim.create!(user: user, point_rule_version: PointRuleVersion.current("engagement"), kind: "chain", period_key: "historical-#{index}", evidence: "Preuve historique #{index}", amount: 10)
    end
    claims.first(3).each { |claim| Points::Rewards.review!(claim, actor: admin, decision: "approved", reason: "Maillons vérifiés") }
    expect { Points::Rewards.review!(claims.last, actor: admin, decision: "approved", reason: "Maillons vérifiés") }.to raise_error(Exchanges::Invalid, /chaînes/)
    expect(PointAccount.for!(user).balance).to eq(30)
    expect(claims.last.reload.status).to eq("pending")
  end
end
