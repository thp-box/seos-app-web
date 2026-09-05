require "rails_helper"
RSpec.describe NotificationEmailJob, type: :job do
  it "envoie une notification sans texte privé et ne réexpédie pas un job rejoué" do
    request = create(:service_request)
    notification = Notification.notify!(user: request.provider, key: "mail-test", title: "Votre échange a été mis à jour", request: request)
    expect { described_class.perform_now(notification) }.to change(ActionMailer::Base.deliveries, :count).by(1)
    mail = ActionMailer::Base.deliveries.last
    expect(mail.to).to eq([ request.provider.email ])
    expect(mail.body.encoded).not_to include(request.requester.email)
    expect(notification.reload.emailed_at).to be_present
    expect { described_class.perform_now(notification) }.not_to change(ActionMailer::Base.deliveries, :count)
  end
  it "respecte les préférences et les comptes suspendus" do
    user = create(:user, email_notifications: false)
    notification = Notification.notify!(user: user, key: "mail-disabled", title: "Une notification")
    expect { described_class.perform_now(notification) }.not_to change(ActionMailer::Base.deliveries, :count)
    user.update!(email_notifications: true, status: :suspended)
    expect { described_class.perform_now(notification) }.not_to change(ActionMailer::Base.deliveries, :count)
  end
end
