require "rails_helper"

RSpec.describe "Engagement communautaire" do
  let(:user) { create(:profile).user }
  let(:admin) { create(:user, :super_admin) }
  before do
    point_rules
    load Rails.root.join("db/community_seeds.rb")
  end

  def quest(**attributes)
    Achievement.create!({ slug: SecureRandom.hex(4), name: "Un coup de main", description: "Joindre le compte rendu de votre action", event_name: "manual", reward_key: "written" }.merge(attributes))
  end

  it "fige la preuve et le barème, refuse les doublons, permet le réexamen et ne récompense qu’une fois" do
    item = quest
    expect { Achievements.submit!(user: user, achievement: item, evidence: "") }.to raise_error(ActiveRecord::RecordInvalid)
    record = Achievements.submit!(user: user, achievement: item, evidence: "Compte rendu privé")
    expect(record.points).to eq(10)
    expect { Achievements.submit!(user: user, achievement: item, evidence: "Autre") }.to raise_error(ActiveRecord::RecordNotUnique)
    expect { record.update!(points: 900) }.to raise_error(ActiveRecord::StatementInvalid)
    record.reload
    expect { Achievements.review!(record: record, actor: user, decision: "approved", reason: "Auto") }.to raise_error(Pundit::NotAuthorizedError)
    expect { Achievements.review!(record: record, actor: admin, decision: "approved", reason: "") }.to raise_error(Exchanges::Invalid)
    Achievements.review!(record: record, actor: admin, decision: "rejected", reason: "Précisions attendues")
    expect(Achievements.progress(user, item)).to eq(0)
    expect { Achievements.review!(record: record, actor: admin, decision: "approved", reason: "Revue") }.to raise_error(Exchanges::Invalid)
    Achievements.review!(record: record, actor: admin, decision: "reexamine", reason: "Éléments recoupés")
    2.times { Achievements.review!(record: record, actor: admin, decision: "approved", reason: "Vérifié") }
    expect(PointAccount.for!(user).balance).to eq(10)
    expect(Achievements.progress(user, item)).to eq(1)
    expect { Achievements.review!(record: record, actor: admin, decision: "reexamine", reason: "Revue") }.to raise_error(Exchanges::Invalid)
    expect { record.reload.update!(decision: "Réécriture") }.to raise_error(ActiveRecord::StatementInvalid)
    expect(item.update(reward_key: "video")).to be(false)
    expect { quest(recurrence: "cycle") }.to raise_error(ActiveRecord::RecordInvalid, /preuve unique/)
  end

  it "renouvelle les quêtes mensuelles et calcule les progressions depuis leurs sources" do
    item = quest(recurrence: "monthly", reward_key: "share")
    record = Achievements.submit!(user: user, achievement: item, evidence: "Action du mois")
    Achievements.review!(record: record, actor: admin, decision: "approved", reason: "Vérifié")
    expect(Achievements.progress(user, item)).to eq(1)
    travel_to 1.month.from_now do
      expect(Achievements.progress(user, item)).to eq(0)
      expect(Achievements.submit!(user: user, achievement: item, evidence: "Mois suivant").period_key).not_to eq(record.period_key)
    end
    Achievement.where(builtin: true).each { |entry| expect(Achievements.progress(user, entry)).to be >= 0 }
    Points::Rewards.welcome!(user)
    expect(Achievements.progress(user, Achievement.find_by!(slug: "welcome"))).to eq(1)
    create(:listing, user: user)
    expect(Achievements.progress(user, Achievement.find_by!(slug: "listing"))).to eq(1)
    expect { Achievements.submit!(user: user, achievement: Achievement.first, evidence: "x") }.to raise_error(Exchanges::Invalid)
  end

  it "réserve le Top aux annonces éligibles, l’expire et masque les annonces fermées" do
    listing = create(:listing, user: user, priority: "urgent")
    expect(listing.urgent?).to be(true)
    expect { Community.request_top!(user: user, listing: listing) }.to raise_error(Exchanges::Invalid)
    expect { Community.request_top!(user: admin, listing: listing) }.to raise_error(Pundit::NotAuthorizedError)
    claim = Points::Rewards.submit!(user: user, kind: "share", evidence: "Capture du partage sans traceur")
    Points::Rewards.review!(claim, actor: admin, decision: "approved", reason: "Partage vérifié")
    top = Community.request_top!(user: user, listing: listing)
    expect { Community.request_top!(user: user, listing: listing) }.to raise_error(ActiveRecord::RecordNotUnique)
    expect { Community.review_top!(record: top, actor: user, decision: "approved", reason: "Auto") }.to raise_error(Pundit::NotAuthorizedError)
    expect { Community.review_top!(record: top, actor: admin, decision: "oops", reason: "x") }.to raise_error(Exchanges::Invalid)
    expect { Community.review_top!(record: top, actor: admin, decision: "approved", reason: "x", days: 31) }.to raise_error(Exchanges::Invalid)
    Community.review_top!(record: top, actor: admin, decision: "approved", reason: "Mission utile", days: 1, position: 3)
    expect(listing.top_placement).to eq(top)
    expect(Catalogue.call({}).first).to eq(listing)
    expect { Community.review_top!(record: top, actor: admin, decision: "approved", reason: "bis") }.to raise_error(Exchanges::Invalid)
    travel_to 2.days.from_now do
      expect(listing.top_placement).to be_nil
      replacement = Community.request_top!(user: user, listing: listing)
      Community.review_top!(record: replacement, actor: admin, decision: "rejected", reason: "Rotation")
    end
    listing.update!(status: "closed")
    expect(listing.top_placement).to be_nil
    travel_to 8.days.from_now do
      expect(listing.urgent?).to be(false)
      expect(Catalogue.call(priority: "urgent")).to be_empty
    end
  end

  it "sépare le consentement, la publication, la récompense et le retrait" do
    attrs = { kind: "written", quote: "Une rencontre très utile", display_name_snapshot: "Camille" }
    expect { Community.testimonial!(user: user, attributes: attrs, consent: "0") }.to raise_error(Exchanges::Invalid)
    record = Community.testimonial!(user: user, attributes: attrs, consent: "1")
    expect(record.publicly_visible?).to be(false)
    expect { Community.review_testimonial!(record: record, actor: user, decision: "published", reason: "Auto") }.to raise_error(Pundit::NotAuthorizedError)
    Community.review_testimonial!(record: record, actor: admin, decision: "rejected", reason: "Relecture")
    Community.review_testimonial!(record: record, actor: admin, decision: "reexamine", reason: "Relecture terminée")
    Community.review_testimonial!(record: record, actor: admin, decision: "published", reason: "Accord vérifié")
    expect(record.publicly_visible?).to be(true)
    expect(PointOperation.count).to eq(0)
    claim = record.point_reward_claim
    Points::Rewards.review!(claim, actor: admin, decision: "approved", reason: "Témoignage vérifié")
    second = Community.testimonial!(user: user, attributes: attrs, consent: "1")
    Community.review_testimonial!(record: second, actor: admin, decision: "published", reason: "Accord vérifié")
    expect(second.point_reward_claim).to eq(claim)
    expect(PointAccount.for!(user).balance).to eq(10)
    expect { Community.withdraw!(record: record, user: admin) }.to raise_error(Pundit::NotAuthorizedError)
    Community.withdraw!(record: record, user: user)
    expect(record.publicly_visible?).to be(false)
    expect(PointAccount.for!(user).balance).to eq(10)
    expect { Community.review_testimonial!(record: record, actor: admin, decision: "published", reason: "Non") }.to raise_error(Exchanges::Invalid)
    expect { Community.review_testimonial!(record: second, actor: admin, decision: "unknown", reason: "Non") }.to raise_error(Exchanges::Invalid)
    Community.review_testimonial!(record: second, actor: admin, decision: "removed", reason: "Retrait éditorial")
    expect(second.publicly_visible?).to be(false)
  end
end
