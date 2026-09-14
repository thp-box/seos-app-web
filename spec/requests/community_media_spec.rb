require "rails_helper"

RSpec.describe "Médias communautaires", type: :request do
  let(:user) { create(:profile).user }
  let(:admin) { create(:user, :super_admin) }
  before { point_rules }

  it "vérifie la vidéo réelle, la garde privée avant accord et bloque son accès après retrait" do
    login user
    upload = fixture_file_upload("testimonial.mp4", "video/mp4")
    post account_testimonials_path, params: { operation: "testimonial", kind: "video", quote: "Une expérience utile", display_name_snapshot: "Camille", transcript: "Une expérience utile au jardin partagé.", consent: "1", video: upload }
    expect(response).to have_http_status(:see_other)
    record = Testimonial.last
    expect(record.video).to be_attached
    get media_path(record.video.attachment)
    expect(response.media_type).to eq("video/mp4")
    delete destroy_user_session_path
    get media_path(record.video.attachment)
    expect(response).to have_http_status(:not_found)
    Community.review_testimonial!(record: record, actor: admin, decision: "published", reason: "Accord et transcription vérifiés")
    get testimonials_path
    expect(response.body).to include("<video", "Transcription")
    get media_path(record.video.attachment)
    expect(response).to have_http_status(:ok)
    Community.withdraw!(record: record, user: user)
    get media_path(record.video.attachment)
    expect(response).to have_http_status(:not_found)
  end

  it "refuse les faux fichiers et une vidéo sans transcription" do
    expect { SafeVideo.attach!(Testimonial.new.video, nil) }.to raise_error(Exchanges::Invalid)
    fake = fixture_file_upload("testimonial.mp4", "video/mp4")
    fake.tempfile.write("not a video")
    fake.tempfile.truncate(11)
    fake.tempfile.rewind
    expect { SafeVideo.attach!(Testimonial.new.video, fake) }.to raise_error(Exchanges::Invalid)
    expect(Testimonial.new(kind: "video", quote: "Aide", display_name_snapshot: "Camille", consent_version: "v1", consented_at: Time.current, user: user)).not_to be_valid
  end
end
