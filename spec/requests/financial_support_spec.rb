require "rails_helper"

RSpec.describe "Soutien financier dormant", type: :request do
  let(:user) { create(:profile).user }
  let(:admin) { create(:user, :super_admin) }
  let(:key) { SecureRandom.uuid }
  before do
    point_rules
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:fetch).and_call_original
    { "STRIPE_SECRET_KEY" => "sk_test_example", "STRIPE_WEBHOOK_SECRET" => "whsec_example", "FINANCIAL_SUPPORT_READY" => "1", "APP_URL" => "https://seos.example" }.each do |name, value|
      allow(ENV).to receive(:[]).with(name).and_return(value)
      allow(ENV).to receive(:fetch).with(name).and_return(value)
    end
  end

  def session_data(record, **attributes)
    { id: "cs_test_#{record.id}", object: "checkout.session", mode: "payment", client_reference_id: record.id.to_s,
      metadata: { contribution_id: record.id.to_s }, amount_total: record.amount_cents, currency: "eur", payment_status: "paid", status: "complete", payment_intent: "pi_#{record.id}", url: "https://checkout.stripe.com/c/pay/test" }.merge(attributes)
  end

  def deliver(record, id: "evt_success", type: "checkout.session.completed", object: nil)
    body = { id: id, object: "event", type: type, data: { object: object || session_data(record) } }.to_json
    timestamp = Time.current.to_i
    digest = OpenSSL::HMAC.hexdigest("SHA256", "whsec_example", "#{timestamp}.#{body}")
    post "/stripe/webhook", params: body, headers: { "CONTENT_TYPE" => "application/json", "Stripe-Signature" => "t=#{timestamp},v1=#{digest}" }
  end

  def enable
    FeatureFlag.create!(key: "financial_support_enabled", enabled: true)
  end

  it "cache le parcours et réserve l’activation auditée au super-admin après validations" do
    login user
    get account_support_path
    expect(response).to have_http_status(:not_found)
    get account_root_path
    expect(response.body).not_to include("Soutenir SEOS")
    post "/stripe/webhook"
    expect(response).to have_http_status(:not_found)
    delete destroy_user_session_path
    login admin
    get admin_financial_support_index_path
    expect(response.body).to include("désactivé")
    post admin_financial_support_index_path, params: { operation: "toggle", enabled: "1", reason: "Activation" }
    expect(response).to have_http_status(:unprocessable_content)
    post admin_financial_support_index_path, params: { operation: "toggle", enabled: "1", validations: "1", reason: "Recette complète" }
    expect(response).to have_http_status(:see_other)
    expect(FeatureFlag.support_enabled?).to be(true)
    post admin_financial_support_index_path, params: { operation: "toggle", enabled: "0", reason: "Pause" }
    expect(FeatureFlag.support_enabled?).to be(false)
    expect(AuditLog.where(action: "financial.flag").count).to eq(2)
    post admin_financial_support_index_path, params: { operation: "unknown" }
    expect(response).to have_http_status(:unprocessable_content)
    delete destroy_user_session_path
    staff = create(:user, :admin)
    login staff
    get admin_financial_support_index_path
    expect(response).to have_http_status(:forbidden)
    grant(staff, "financial.manage")
    post admin_financial_support_index_path, params: { operation: "toggle", enabled: "1", validations: "1", reason: "Non" }
    expect(response).to have_http_status(:forbidden)
  end

  it "borne le montant et conserve la même demande Checkout après une interruption" do
    enable
    login user
    get account_support_path
    expect(response.body).to include("Aucun avantage fiscal")
    post account_support_path, params: { amount_euros: "1.001", request_key: key }
    expect(response).to have_http_status(:unprocessable_content)
    post account_support_path, params: { amount_euros: "0.01", request_key: key }
    expect(response).to have_http_status(:unprocessable_content)
    checkout = stub_request(:post, "https://api.stripe.com/v1/checkout/sessions").to_return do |request|
      expect(request.headers["Idempotency-Key"]).to eq("contribution:#{FinancialContribution.last.id}")
      { status: 200, body: session_data(FinancialContribution.last, payment_status: "unpaid", status: "open").to_json, headers: { "Content-Type" => "application/json" } }
    end
    2.times do |index|
      if index == 1
        record = FinancialContribution.last
        stub_request(:get, "https://api.stripe.com/v1/checkout/sessions/cs_test_#{record.id}").to_return(status: 200, body: session_data(record).to_json, headers: { "Content-Type" => "application/json" })
      end
      post account_support_path, params: { amount_cents: 1000, request_key: key, points: 9000 }
      expect(response).to redirect_to("https://checkout.stripe.com/c/pay/test")
    end
    expect(checkout).to have_been_requested.once
    expect(FinancialContribution.count).to eq(1)
    expect(FinancialContribution.last.status).to eq("pending")
    post account_support_path, params: { amount_cents: 2000, request_key: key }
    expect(response).to have_http_status(:unprocessable_content)
    get account_support_path
    expect(response.body).to include("Reprendre cette demande")
    expect(PointOperation.count).to eq(0)
    travel_to 2.days.from_now do
      expect { FinancialSupport.checkout!(user: user, amount: 1000, request_key: key) }.to raise_error(Exchanges::Invalid, /ancienne/)
    end
  end

  it "vérifie les signatures et les montants, déduplique les événements et conserve les remboursements" do
    enable
    record = FinancialContribution.create!(user: user, request_key: key, amount_cents: 1000)
    post "/stripe/webhook", params: "{}", headers: { "Stripe-Signature" => "invalid" }
    expect(response).to have_http_status(:bad_request)
    deliver(record, object: session_data(record, amount_total: 999))
    expect(response).to have_http_status(:bad_request)
    expect(PaymentEvent.count).to eq(0)
    2.times { deliver(record); expect(response).to have_http_status(:ok) }
    expect(PaymentEvent.count).to eq(1)
    expect(record.reload.status).to eq("paid")
    deliver(record, id: "evt_refund", type: "charge.refunded", object: { id: "ch_test", payment_intent: record.payment_intent_id, amount: 1000, currency: "eur", amount_refunded: 400 })
    expect(record.reload.status).to eq("partially_refunded")
    deliver(record, id: "evt_late")
    expect(record.reload.status).to eq("partially_refunded")
    deliver(record, id: "evt_full", type: "charge.refunded", object: { id: "ch_test", payment_intent: record.payment_intent_id, amount: 1000, currency: "eur", amount_refunded: 1000 })
    expect(record.reload.status).to eq("refunded")
    expect(record.refunded_cents).to eq(1000)
    expect { PaymentEvent.first.update!(event_type: "fake") }.to raise_error(ActiveRecord::ReadOnlyRecord)
    expect { record.update!(amount_cents: 2000) }.to raise_error(ActiveRecord::StatementInvalid)
    expect(PointOperation.count).to eq(0)
    expect(TrustEvent.count).to eq(0)
  end

  it "traite l’échec et l’expiration, rapproche et rembourse sans donner de points" do
    enable
    record = FinancialContribution.create!(user: user, request_key: key, amount_cents: 1500)
    deliver(record, id: "evt_failed", type: "checkout.session.async_payment_failed", object: session_data(record, payment_status: "unpaid", status: "complete"))
    expect(record.reload.status).to eq("failed")
    deliver(record, id: "evt_expired", type: "checkout.session.expired", object: session_data(record, payment_status: "unpaid", status: "expired"))
    expect(record.reload.status).to eq("expired")
    stub_request(:get, "https://api.stripe.com/v1/checkout/sessions/#{record.stripe_session_id}").to_return(status: 200, body: session_data(record).to_json, headers: { "Content-Type" => "application/json" })
    stub_request(:get, "https://api.stripe.com/v1/payment_intents/pi_#{record.id}").to_return(status: 200, body: { id: "pi_#{record.id}", latest_charge: nil }.to_json, headers: { "Content-Type" => "application/json" })
    login admin
    post admin_financial_support_index_path, params: { operation: "reconcile", record_id: record.id, reason: "Contrôle" }
    expect(response).to have_http_status(:see_other)
    expect(record.reload.status).to eq("paid")
    refund = stub_request(:post, "https://api.stripe.com/v1/refunds").to_return(status: 200, body: { id: "re_test", status: "succeeded" }.to_json, headers: { "Content-Type" => "application/json" })
    2.times do
      post admin_financial_support_index_path, params: { operation: "refund", record_id: record.id, reason: "Demande du membre" }
      expect(response).to have_http_status(:see_other)
    end
    expect(refund).to have_been_requested.once
    expect(record.reload.status).to eq("refunded")
    get admin_financial_support_index_path
    expect(response.body).to include("1500", "Remboursé")
    expect(PointOperation.count).to eq(0)
  end
end
