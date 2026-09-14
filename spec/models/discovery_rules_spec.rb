require "rails_helper"
RSpec.describe "Règles de découverte et d’avis", type: :model do
  it "bloque les cycles de catégorie et les contraintes SQL d’identité et de points" do
    parent = create(:category)
    child = create(:category, parent: parent)
    parent.parent = child
    expect(parent).not_to be_valid
    parent.reload.update!(active: false)
    expect(child).not_to be_publishable
    listing = create(:listing)
    expect { listing.update_column(:estimated_points, 12) }.to raise_error(ActiveRecord::StatementInvalid)
    expect { create(:service_request, listing: listing, requester: listing.user) }.to raise_error(ActiveRecord::RecordInvalid)
  end

  it "borne les restrictions et applique leur période sans republiquer silencieusement" do
    listing = create(:listing)
    restriction = CategoryRestriction.create!(created_by: create(:user, :super_admin), category: listing.category, term: "jardin", reason: "Revue", starts_at: 1.day.from_now, ends_at: 2.days.from_now)
    expect(listing).not_to be_restricted
    travel_to 25.hours.from_now do
      expect(listing).to be_restricted
      ApplyCategoryRestrictionsJob.perform_now
      expect(listing.reload).to be_pending_review
      expect(listing.moderation_hold).to be(true)
      expect { ApplyCategoryRestrictionsJob.perform_now }.not_to change(AuditLog, :count)
    end
    restriction.starts_at = 4.days.from_now
    expect(restriction).not_to be_valid
    empty = CategoryRestriction.new(created_by: restriction.created_by, starts_at: Time.current, reason: "Sans portée")
    expect(empty).not_to be_valid
  end

  it "filtre stablement le catalogue et garde le distanciel lors d’une recherche géographique" do
    local = create(:listing, service_location_mode: "in_person", city: "Lyon", intent: "request", title: "Bricoler ensemble")
    local.update!(latitude: 45.76, longitude: 4.84)
    remote = create(:listing, title: "Apprendre ensemble")
    expect(Catalogue.call(q: "ensemble")).to contain_exactly(local, remote)
    expect(Catalogue.call(intent: "request")).to eq([ local ])
    expect(Catalogue.call(city: "Paris")).to eq([ remote ])
    expect(Catalogue.call(latitude: "45.76", longitude: "4.84", radius: "10")).to contain_exactly(local, remote)
    expect(Catalogue.call(latitude: "invalid", longitude: "4", radius: "10")).to be_empty
    expect(Catalogue.call(sort: "oldest").first).to eq(local)
    expect(local.public_coordinates).to eq([ 45.76, 4.84 ])
    local.update!(service_location_mode: "remote")
    expect(local.latitude).to be_nil
    expect(local.public_coordinates).to be_nil
  end

  it "contrôle la publication du profil, des catégories, des PS et des organisations" do
    listing = create(:listing, status: :draft, service_location_mode: "in_person", city: nil)
    listing.user.profile.update!(status: :draft)
    listing.category.update!(active: false)
    listing.exchange_mode = "points"
    expect(listing.valid?(:publication)).to be(false)
    expect(listing.errors.attribute_names).to include(:base, :category, :city, :estimated_points)
    listing.organization = create(:organization, kind: "company")
    expect(listing.valid?(:publication)).to be(false)
    expect(listing.errors.attribute_names).to include(:organization)
    expect(ListingPolicy.new(nil, listing).update?).to be(false)
    organization = create(:organization)
    listing.organization = organization
    editor = create(:user)
    create(:organization_membership, user: editor, organization: organization)
    expect(ListingPolicy.new(editor, listing).update?).to be(true)
    expect(ListingPolicy.new(create(:user), listing).update?).to be(false)
  end

  it "ne géocode qu’une commune publique de service sur place" do
    listing = create(:listing, service_location_mode: "in_person", city: "Dijon", address_line: "Adresse à ne pas transmettre")
    result = double(coordinates: [ 47.32204, 5.04148 ])
    expect(Geocoder).to receive(:search).with("Dijon", type: "municipality", limit: 1, autocomplete: 0).and_return([ result ])
    GeocodeListingJob.perform_now(listing)
    expect(listing.reload.latitude).to eq(47.32)
    listing.update!(service_location_mode: "remote")
    expect(Geocoder).not_to receive(:search)
    GeocodeListingJob.perform_now(listing)
  end

  it "respecte programmation et immutabilité éditoriales" do
    future = create(:content_version, published_at: 1.day.from_now)
    expect(ContentVersion.current("article", future.slug)).to be_nil
    travel_to 2.days.from_now do
      expect(ContentVersion.current("article", future.slug)).to eq(future)
    end
    expect(build(:content_version, kind: "page", slug: "arbitraire")).not_to be_valid
    expect(build(:content_version, kind: "legal", slug: "arbitraire")).not_to be_valid
    expect(build(:content_version, decorations: [ "<script>" ])).not_to be_valid
  end

  it "réserve les avis aux participants après réalisation et limite dépôt, critères et fenêtre" do
    request = create(:service_request)
    author = request.requester
    criterion = create(:review_criterion)
    attributes = { completion_answer: "yes", would_reengage: true, factual_body: "Très bon échange" }
    submit = ->(actor = author, ratings = {}) { ReviewSubmission.call(request: request, actor: actor, attributes: attributes, ratings: ratings) }
    expect { submit.call(create(:user)) }.to raise_error(Pundit::NotAuthorizedError)
    expect { submit.call }.to raise_error(Exchanges::Invalid)
    request.update!(status: :completed, completed_at: 31.days.ago)
    expect { submit.call }.to raise_error(Exchanges::Invalid)
    request.update!(completed_at: Time.current)
    expect { submit.call }.to raise_error(Exchanges::Invalid)
    ratings = ReviewCriterion.applicable(request, author).pluck(:id).to_h { |id| [ id.to_s, "na" ] }
    review = submit.call(author, ratings)
    expect(review.review_ratings.find_by!(review_criterion: criterion)).to be_not_applicable
    expect(review).not_to be_revealed
    expect { submit.call(author, ratings) }.to raise_error(ActiveRecord::RecordInvalid)
    travel_to 15.days.from_now { expect(review).to be_revealed }
    expect(ReviewRating.new(rating: 6, not_applicable: false)).not_to be_valid
  end
end
