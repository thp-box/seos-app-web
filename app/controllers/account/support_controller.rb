module Account
  class SupportController < BaseController
    content_security_policy { |policy| policy.form_action :self, "https://checkout.stripe.com" }
    before_action { raise ActiveRecord::RecordNotFound unless FeatureFlag.support_enabled? }
    def show
      @contributions = FinancialContribution.where(user: current_user).order(id: :desc).limit(30)
    end
    def create
      amount = if params.key?(:amount_euros)
        text = params[:amount_euros].to_s.tr(",", ".")
        raise Exchanges::Invalid, "Saisissez un montant en euros avec deux décimales au maximum." unless text.match?(/\A\d{1,4}(?:\.\d{1,2})?\z/)
        (BigDecimal(text) * 100).to_i
      else
        Integer(params[:amount_cents], exception: false)
      end
      url = FinancialSupport.checkout!(user: current_user, amount: amount, request_key: params[:request_key].to_s)
      redirect_to url, allow_other_host: true, status: :see_other
    end
  end
end
