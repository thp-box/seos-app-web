require "rails_helper"

RSpec.describe FinancialSupport do
  let(:user) { create(:user) }
  let(:admin) { create(:user, :super_admin) }
  let(:record) { FinancialContribution.create!(user: user, amount_cents: 1000, request_key: SecureRandom.uuid, stripe_session_id: "cs_test", payment_intent_id: "pi_test", status: "paid") }
  let(:api) { double("Stripe API") }
  before do
    allow(FinancialSupport).to receive(:client).and_return(double(v1: api))
  end

  it "empêche les remboursements sans autorité, sans motif, en attente ou trop anciens" do
    expect { FinancialSupport.refund!(record: record, actor: user, reason: "Non") }.to raise_error(Pundit::NotAuthorizedError)
    expect { FinancialSupport.refund!(record: record, actor: admin, reason: "") }.to raise_error(Exchanges::Invalid)
    record.update!(status: "pending")
    expect { FinancialSupport.refund!(record: record, actor: admin, reason: "Non") }.to raise_error(Exchanges::Invalid)
    record.update!(status: "paid", refund_requested_at: 2.days.ago)
    expect { FinancialSupport.refund!(record: record, actor: admin, reason: "Non") }.to raise_error(Exchanges::Invalid, /ancienne/)
  end

  it "conserve la tentative de remboursement lorsqu’une réponse Stripe se perd" do
    refunds = double
    allow(api).to receive(:refunds).and_return(refunds)
    allow(refunds).to receive(:create).and_raise(Stripe::APIConnectionError.new("Offline"))
    expect { FinancialSupport.refund!(record: record, actor: admin, reason: "Demande") }.to raise_error(Exchanges::Invalid, /Rapprochez/)
    expect(record.reload.refund_requested_at).to be_present
    expect(record.status).to eq("paid")
    allow(refunds).to receive(:create).and_return(Stripe::StripeObject.construct_from(id: "re_test", status: "failed"))
    expect { FinancialSupport.refund!(record: record, actor: admin, reason: "Demande") }.to raise_error(Exchanges::Invalid, /échoué/)
    allow(refunds).to receive(:create).and_return(Stripe::StripeObject.construct_from(id: "re_test", status: "pending"))
    FinancialSupport.refund!(record: record, actor: admin, reason: "Demande")
    expect(record.reload.status).to eq("refund_pending")
    expect(record.refunded_cents).to eq(0)
  end

  it "rapproche les remboursements en conservant un montant monotone" do
    expect { FinancialSupport.reconcile!(record: record, actor: user, reason: "Non") }.to raise_error(Pundit::NotAuthorizedError)
    expect { FinancialSupport.reconcile!(record: record, actor: admin, reason: "") }.to raise_error(Exchanges::Invalid)
    session = Stripe::StripeObject.construct_from(id: "cs_test", mode: "payment", client_reference_id: record.id.to_s, amount_total: 1000, currency: "eur", payment_intent: "pi_test", payment_status: "paid", status: "complete")
    sessions = double(retrieve: session)
    allow(api).to receive(:checkout).and_return(double(sessions: sessions))
    allow(api).to receive(:payment_intents).and_return(double(retrieve: Stripe::StripeObject.construct_from(latest_charge: "ch_test")))
    charge = Stripe::StripeObject.construct_from(amount: 1000, currency: "eur", amount_refunded: 500)
    allow(api).to receive(:charges).and_return(double(retrieve: charge))
    FinancialSupport.reconcile!(record: record, actor: admin, reason: "Contrôle")
    expect(record.reload.status).to eq("partially_refunded")
    charge.amount_refunded = 1000
    FinancialSupport.reconcile!(record: record, actor: admin, reason: "Contrôle")
    expect(record.reload.status).to eq("refunded")
    charge.amount_refunded = 0
    FinancialSupport.reconcile!(record: record, actor: admin, reason: "Retard")
    expect(record.reload.refunded_cents).to eq(1000)
    allow(sessions).to receive(:retrieve).and_raise(Stripe::APIConnectionError.new("Offline"))
    expect { FinancialSupport.reconcile!(record: record, actor: admin, reason: "Contrôle") }.to raise_error(Exchanges::Invalid, /indisponible/)
    record.update!(stripe_session_id: nil)
    expect { FinancialSupport.reconcile!(record: record, actor: admin, reason: "Contrôle") }.to raise_error(Exchanges::Invalid, /Aucune session/)
  end

  it "rejoue un remboursement reçu avant la confirmation du paiement" do
    record.update!(status: "pending", payment_intent_id: nil)
    PaymentEvent.create!(stripe_event_id: "evt_early", event_type: "charge.refunded", refund_data: { payment_intent: "pi_test", amount: 1000, amount_refunded: 1000, currency: "eur" })
    session = Stripe::StripeObject.construct_from(id: "cs_test", mode: "payment", client_reference_id: record.id.to_s, amount_total: 1000, currency: "eur", payment_intent: "pi_test", payment_status: "paid", status: "complete")
    FinancialSupport.apply_session!(record, session)
    expect(record.reload.status).to eq("refunded")
    expect(record.refunded_cents).to eq(1000)
  end
end
