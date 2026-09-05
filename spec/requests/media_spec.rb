require "rails_helper"
RSpec.describe "Médias réencodés et autorisés", :"F-006", :"F-011", :"F-021", type: :request do
  let!(:listing) { create(:listing) }
  let(:png_path) { Rails.root.join("tmp", "spec-upload.png") }
  before { ChunkyPNG::Image.new(20, 20, ChunkyPNG::Color.rgb(0, 100, 80)).save(png_path) }
  after { FileUtils.rm_f(png_path) }
  def upload = Rack::Test::UploadedFile.new(png_path, "image/png")

  it "réencode les images et protège celles des brouillons" do
    login listing.user
    patch account_profile_path, params: { profile: { avatar: upload } }
    expect(response).to have_http_status(:see_other)
    avatar = listing.user.profile.avatar.attachment
    expect(avatar.blob.content_type).to eq("image/jpeg")
    get media_path(avatar)
    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq("image/jpeg")
    patch account_listing_path(listing, step: 3), params: { listing: { photos: [ upload ] } }
    expect(response).to have_http_status(:see_other)
    listing.reload
    expect(listing.photos.count).to eq(1)
    expect(listing).to be_draft
    photo = listing.photos.first
    get media_path(photo)
    expect(response).to have_http_status(:ok)
    delete destroy_user_session_path
    get media_path(photo)
    expect(response).to have_http_status(:not_found)
    get media_path(avatar)
    expect(response).to have_http_status(:ok)
  end

  it "refuse MIME falsifié et fichiers trop gros" do
    login listing.user
    forged = Rack::Test::UploadedFile.new(png_path, "image/jpeg")
    patch account_profile_path, params: { profile: { avatar: forged } }
    expect(response).to have_http_status(:unprocessable_content)
    expect(listing.user.profile.avatar).not_to be_attached
    fake = double(size: 6.megabytes, tempfile: File.open(png_path), content_type: "image/png")
    expect { SafeImage.attach!(listing.photos, fake) }.to raise_error(Exchanges::Invalid)
  end

  it "réserve les pièces jointes de conversation aux participants" do
    request = create(:service_request, listing: listing)
    login request.requester
    post account_service_request_messages_path(request), params: { message: { body: "La photo du matériel", delivery_key: "image-1", attachment: upload } }
    expect(response).to have_http_status(:see_other)
    attachment = Message.last.attachment.attachment
    delete destroy_user_session_path
    get media_path(attachment)
    expect(response).to have_http_status(:not_found)
    login listing.user
    get media_path(attachment)
    expect(response).to have_http_status(:ok)
    Message.last.update!(removed_at: Time.current)
    get media_path(attachment)
    expect(response).to have_http_status(:not_found)
  end
end
