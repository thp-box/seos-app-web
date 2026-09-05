class PaymentWebhooksController < ActionController::Base
  skip_forgery_protection
  def create
    return head :not_found unless FeatureFlag.support_enabled? && FinancialSupport.ready?
    FinancialSupport.webhook!(body: request.raw_post, signature: request.headers["Stripe-Signature"])
    head :ok
  rescue Stripe::SignatureVerificationError, JSON::ParserError, Exchanges::Invalid
    head :bad_request
  rescue ActiveRecord::RecordNotUnique
    head :ok
  end
end
