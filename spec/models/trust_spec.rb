require "rails_helper"

RSpec.describe "Parrainage et Trust", :"F-030", :"F-031", :"F-032", :"F-033" do
  let(:user) { create(:profile).user }

  it "n’émet que pour un membre actif confirmé et expérimenté, ou exempté explicitement" do
    expect(Referrals.eligible?(user)).to be(false)
    expect { Referrals.issue!(user) }.to raise_error(Exchanges::Invalid)
    user.update!(created_at: 31.days.ago)
    2.times { completed_exchange(user) }
    expect(Referrals.eligible?(user)).to be(true)
    user.update!(status: :suspended)
    expect(Referrals.eligible?(user)).to be(false)
    user.update!(status: :active, confirmed_at: nil)
    expect(Referrals.eligible?(user)).to be(false)
  end

  it "stocke uniquement le condensat, limite les émissions et les codes disponibles" do
    sponsor = exempt_sponsor
    raw = Referrals.issue!(sponsor)
    expect(ReferralCode.last.code_digest).to eq(Digest::SHA256.hexdigest(raw))
    expect(ReferralCode.last.attributes.values).not_to include(raw)
    expect { Referrals.issue!(sponsor) }.to raise_error(Exchanges::Invalid)
    4.times do
      travel 2.minutes
      Referrals.issue!(sponsor)
    end
    travel 2.minutes
    expect { Referrals.issue!(sponsor) }.to raise_error(Exchanges::Invalid)
    ReferralCode.update_all(claimed_at: Time.current)
    expect { Referrals.issue!(sponsor) }.to raise_error(Exchanges::Invalid)
    travel 25.hours
    expect { Referrals.issue!(sponsor) }.to change(ReferralCode, :count).by(1)
  end

  it "refuse code expiré, réutilisé, inconnu, auto-parrainage et fenêtre dépassée" do
    sponsor = exempt_sponsor
    raw = Referrals.issue!(sponsor)
    expect { Referrals.claim!(sponsor, raw) }.to raise_error(Exchanges::Invalid)
    ReferralCode.last.update!(expires_at: 1.second.ago)
    expect { Referrals.claim!(user, raw) }.to raise_error(Exchanges::Invalid)
    ReferralCode.last.update!(expires_at: 1.day.from_now)
    Referrals.claim!(user, raw)
    expect { Referrals.claim!(create(:user), raw) }.to raise_error(Exchanges::Invalid)
    expect { Referrals.claim!(user, "inconnu") }.to raise_error(Exchanges::Invalid)
    expect { Referrals.claim!(user, "") }.to raise_error(Exchanges::Invalid)
    user.update!(created_at: 7.days.ago)
    expect { Referrals.claim!(user, raw) }.to raise_error(Exchanges::Invalid)
  end

  it "annule tout le lot en cas de doublon et conserve exactement un principal parmi dix soutiens" do
    sponsor = exempt_sponsor
    first = Referrals.issue!(sponsor)
    travel 2.minutes
    second = Referrals.issue!(sponsor)
    expect { Referrals.claim!(user, [ first, second ].join("\n")) }.to raise_error(Exchanges::Invalid)
    expect(Referral.count).to eq(0)
    expect(ReferralCode.available.count).to eq(2)
    10.times { support(user) }
    expect(Referral.where(primary_referrer: true).count).to eq(1)
    Referrals.primary!(user, Referral.last)
    expect(Referral.where(primary_referrer: true).pluck(:id)).to eq([ Referral.last.id ])
    expect { support(user) }.to raise_error(Exchanges::Invalid)
    expect { Referrals.primary!(create(:user), Referral.last) }.to raise_error(Pundit::NotAuthorizedError)
    travel 8.days
    expect { Referrals.primary!(user, Referral.last) }.to raise_error(Exchanges::Invalid)
  end

  it "retire immédiatement une objection autorisée, notifie et garde une trace motivée" do
    referral = support(user)
    expect { Referrals.object!(user, referral, "Code volé") }.to raise_error(Pundit::NotAuthorizedError)
    expect { Referrals.object!(referral.referrer, referral, "") }.to raise_error(ActiveRecord::RecordInvalid)
    expect(referral.reload.status).to eq("provisional")
    Referrals.object!(referral.referrer, referral, "Usage non autorisé")
    expect(referral.reload.status).to eq("objected")
    expect(AuditLog.last.action).to eq("referral.objected")
    expect(Referral.valid_support.count).to eq(0)
    expect { Referrals.object!(referral.referrer, referral, "Encore") }.to raise_error(Exchanges::Invalid)
  end

  it "confirme après 72 heures et qualifie sans créditer des points après deux non-parrains" do
    referral = support(user)
    Referrals.mature!
    expect(referral.reload.status).to eq("provisional")
    travel 73.hours
    expect { Referrals.object!(referral.referrer, referral, "Trop tard") }.to raise_error(Exchanges::Invalid)
    Referrals.mature!
    expect(referral.reload.status).to eq("confirmed")
    completed_exchange(user, partner: referral.referrer)
    completed_exchange(user)
    travel 31.days
    Referrals.mature!
    expect(referral.reload.qualified_at).to be_nil
    completed_exchange(user)
    Referrals.mature!
    expect(referral.reload.qualified_at).to be_present
    expect { Referrals.mature! }.not_to change(Notification, :count)
  end

  [ [ 0, nil ], [ 1, 53 ], [ 3, 58 ], [ 5, 62 ], [ 10, 69 ] ].each do |count, expected|
    it "reproduit le repère #{count} parrainages : #{expected || 'sans note'}" do
      count.times { support(user) }
      result, = TrustCalculator.new(user: user, version: trust_version).call
      expect(result["score"]).to eq(expected)
      expect(result["dimensions"]).to eq({})
      expect(result["categories"]).to eq({})
      expect(result["confidence_label"]).to eq("Données limitées")
    end
  end

  it "ignore avis cachés, non applicables et clés inconnues, puis prend les notes révélées" do
    request = completed_exchange(user)
    review = Review.create!(service_request: request, author: request.provider, reviewee: user, completion_answer: "yes", would_reengage: true, reveal_at: 14.days.from_now)
    %w[communication punctuality custom].each do |key|
      criterion = ReviewCriterion.find_by(key: key) || create(:review_criterion, key: key)
      review.review_ratings.create!(review_criterion: criterion, dimension_snapshot: key, label_snapshot: key, rating: key == "punctuality" ? nil : 5, not_applicable: key == "punctuality")
    end
    TrustSources.sync!(user)
    expect(TrustEvent.count).to eq(1)
    review.update!(reveal_at: 1.second.ago)
    TrustSources.sync!(user)
    expect(TrustEvent.count).to eq(2)
    expect { TrustSources.sync!(user) }.not_to change(TrustEvent, :count)
    criterion = ReviewCriterion.find_by!(key: "communication")
    criterion.update!(key: "renamed")
    expect(TrustEvent.last.dimension).to eq("communication")
    review.update!(removed_at: Time.current)
    result, contributions = TrustCalculator.new(user: user, version: trust_version).call
    expect(contributions.count { |row| row["excluded"] }).to eq(0)
    review.update!(invalidated_at: Time.current)
    _, contributions = TrustCalculator.new(user: user, version: TrustAlgorithmVersion.first).call
    expect(contributions.count { |row| row["excluded"] }).to eq(1)
  end

  it "exige les deux confirmations, puis publie catégorie et dimensions après diversité suffisante" do
    category = create(:category)
    freeze_time do
      4.times { completed_exchange(user, category: category) }
      fake = completed_exchange(user)
      fake.update!(provider_confirmed_at: nil)
      TrustSources.sync!(user)
      expect(TrustEvent.count).to eq(4)
      result, = TrustCalculator.new(user: user, version: trust_version).call
      expect(result["status"]).to eq("published")
      expect(result["categories"].keys).to eq([ category.id.to_s ])
      expect(result["dimensions"]["reliability"]["score"]).to eq(75)
      expect(result["partners"]).to eq(4)
    end
  end

  it "plafonne une paire répétée et ne fabrique pas de diversité" do
    partner = create(:profile).user
    20.times { completed_exchange(user, partner: partner) }
    TrustSources.sync!(user)
    result, rows = TrustCalculator.new(user: user, version: trust_version).call
    expect(result["score"]).to be_nil
    expect(result["exchange_weight"]).to be <= 2.5
    expect(rows.sum { |row| row["weight"] }).to be_within(1e-9).of(2.5)
    expect(rows.map { |row| row["pair_factor"] }.first(3)).to eq([ 1, 0.5, 0.2 ])
  end

  it "borne chaque auteur à 15 % avec assez de diversité et réduit la récence" do
    freeze_time do
      partner = create(:profile).user
      10.times { completed_exchange(user, partner: partner, at: 548.days.ago) }
      7.times { completed_exchange(user, at: 548.days.ago) }
      TrustSources.sync!(user)
      calculator = TrustCalculator.new(user: user, version: trust_version)
      result, rows = calculator.call
      total = rows.sum { |row| row["weight"] }
      expect(rows.group_by { |row| row["actor_id"] }.values.map { |items| items.sum { |row| row["weight"] } }.max).to be <= total * 0.15 + 1e-8
      expect(rows.first["recency_factor"]).to eq(0.5)
      expect(calculator.call).to eq([ result, rows ])
      _, old = TrustCalculator.new(user: user, version: TrustAlgorithmVersion.first, at: 10.years.from_now).call
      expect(old.first["recency_factor"]).to eq(0.25)
    end
  end

  it "conserve les snapshots, recalcule les corrections et protège l’historique en SQL" do
    freeze_time do
      version = trust_version
      completed_exchange(user)
      TrustRecalculationJob.perform_now(user.id)
      original = TrustScoreSnapshot.last
      expect { TrustRecalculationJob.perform_now(user.id) }.not_to change(TrustScoreSnapshot, :count)
      event = TrustEvent.last
      admin = create(:user, :super_admin)
      TrustGovernance.correct!(event, actor: admin, excluded: true, reason: "Échange erroné")
      TrustRecalculationJob.perform_now(user.id)
      expect(TrustScoreSnapshot.count).to eq(2)
      expect(TrustScoreSnapshot.last.result["exchange_count"]).to eq(0)
      expect(original.reload.result["exchange_count"]).to eq(1)
      [ event, original, TrustEventCorrection.last ].each do |record|
        expect { record.destroy! }.to raise_error(ActiveRecord::ReadOnlyRecord)
        expect { record.class.where(id: record.id).delete_all }.to raise_error(ActiveRecord::StatementInvalid, /immutable trust history/)
        expect { record.class.where(id: record.id).update_all(created_at: 1.day.ago) }.to raise_error(ActiveRecord::StatementInvalid, /immutable trust history/)
      end
      TrustGovernance.correct!(event, actor: admin, excluded: false, reason: "Correction annulée")
      TrustRecalculationJob.perform_now(user.id)
      expect(user.reload.trust_profile.public_result["exchange_count"]).to eq(1)
      version.update!(status: "retired")
      expect(user.trust_profile.reload.public_result).to be_nil
    end
  end

  it "soumet les évolutions à simulation, seconde approbation, ombre et retour de version" do
    creator = create(:user, :super_admin)
    reviewer = create(:user, :super_admin)
    version = trust_version(status: "draft", creator: creator)
    expect { TrustGovernance.transition!(version, actor: user, action: "simulate", reason: "Test") }.to raise_error(Pundit::NotAuthorizedError)
    expect { TrustGovernance.transition!(version, actor: creator, action: "approve", reason: "Test") }.to raise_error(Exchanges::Invalid)
    expect { TrustGovernance.transition!(version, actor: creator, action: "activate", reason: "Test") }.to raise_error(Exchanges::Invalid)
    expect { TrustGovernance.transition!(version, actor: creator, action: "shadow", reason: "Test") }.to raise_error(Exchanges::Invalid)
    expect { TrustGovernance.transition!(version, actor: creator, action: "rollback", reason: "Test") }.to raise_error(Exchanges::Invalid)
    expect { TrustGovernance.transition!(version, actor: creator, action: "unknown", reason: "Test") }.to raise_error(Exchanges::Invalid)
    TrustGovernance.transition!(version, actor: creator, action: "simulate", reason: "Repères vérifiés")
    expect(version.simulation["referral_scores"]).to eq([ 53, 58, 62, 69 ])
    expect { TrustGovernance.transition!(version, actor: creator, action: "simulate", reason: "Test") }.to raise_error(Exchanges::Invalid)
    TrustGovernance.transition!(version, actor: reviewer, action: "approve", reason: "Simulation et dossier AIPD examinés")
    TrustGovernance.transition!(version, actor: reviewer, action: "shadow", reason: "Calcul de comparaison")
    expect { TrustGovernance.transition!(version, actor: reviewer, action: "activate", reason: "Test") }.to raise_error(Exchanges::Invalid)
    User.where(status: "active").each { |person| TrustRecalculationJob.perform_now(person.id) }
    expect(TrustProfile.count).to eq(0)
    TrustGovernance.transition!(version, actor: reviewer, action: "activate", reason: "Ombre vérifiée")
    version.update!(status: "retired")
    other = trust_version
    TrustGovernance.transition!(version, actor: reviewer, action: "rollback", reason: "Retour à la formule précédente")
    expect(other.reload.status).to eq("retired")
    expect { version.update!(configuration: {}) }.to raise_error(ActiveRecord::RecordInvalid)
    expect { TrustAlgorithmVersion.where(id: version.id).update_all(explanation: "Changement furtif") }.to raise_error(ActiveRecord::StatementInvalid)
  end

  it "n’accepte un recours qu’après correction et notifie la décision motivée" do
    trust_version
    completed_exchange(user)
    TrustRecalculationJob.perform_now(user.id)
    appeal = TrustAppeal.create!(user: user, trust_score_snapshot: TrustScoreSnapshot.last, statement: "Échange attribué à tort", response_due_at: 7.days.from_now)
    admin = create(:user, :super_admin)
    expect { TrustGovernance.decide!(appeal, actor: user, action: "accepted", reason: "Test") }.to raise_error(Pundit::NotAuthorizedError)
    expect { TrustGovernance.correct!(TrustEvent.last, actor: user, excluded: true, reason: "Test") }.to raise_error(Pundit::NotAuthorizedError)
    expect { TrustGovernance.decide!(appeal, actor: admin, action: "accepted", reason: "Test") }.to raise_error(Exchanges::Invalid)
    expect { TrustGovernance.decide!(appeal, actor: admin, action: "unknown", reason: "Test") }.to raise_error(Exchanges::Invalid)
    TrustGovernance.decide!(appeal, actor: admin, action: "investigating", reason: "Vérification des éléments")
    TrustGovernance.correct!(TrustEvent.last, actor: admin, excluded: true, reason: "Erreur établie")
    TrustGovernance.decide!(appeal, actor: admin, action: "accepted", reason: "Preuve exclue, calcul corrigé")
    expect(appeal.reload.assigned_to).to eq(admin)
    expect(appeal.decided_at).to be_present
    expect { TrustGovernance.decide!(appeal, actor: admin, action: "rejected", reason: "Test") }.to raise_error(Exchanges::Invalid)
    expect(TrustAppeal.new(user: admin, trust_score_snapshot: TrustScoreSnapshot.last, statement: "intrusion")).not_to be_valid
  end

  it "détecte cadence, paires et cycles sans jamais modifier le score public, et expire les signaux" do
    partner = create(:profile).user
    10.times { completed_exchange(user, partner: partner) }
    TrustRiskDetection.call(user)
    expect(TrustRiskAssessment.pluck(:signal)).to contain_exactly("exchange_burst", "repeated_pair")
    expect { TrustRiskDetection.call(user) }.not_to change(TrustRiskAssessment, :count)
    sponsor = exempt_sponsor(user)
    first = support(create(:user), sponsor: sponsor)
    # Synthetic cycle built at the data boundary; ordinary eligibility blocks this attack.
    code = ReferralCode.create!(owner: first.referred_user, code_digest: SecureRandom.hex, expires_at: 1.day.from_now)
    Referral.create!(referral_code: code, referrer: first.referred_user, referred_user: user, position: 1, claimed_at: Time.current, objection_deadline_at: 3.days.from_now)
    TrustRiskDetection.call(user)
    expect(TrustRiskAssessment.where(signal: "referral_cycle")).to exist
    expect(TrustProfile.count).to eq(0)
    travel 32.days
    TrustMaintenanceJob.perform_now
    expect(TrustRiskAssessment.where(signal: "exchange_burst")).not_to exist
  end
end
