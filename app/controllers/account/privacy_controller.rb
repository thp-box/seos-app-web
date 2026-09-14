module Account
  class PrivacyController < BaseController
    before_action :require_recent_authentication, only: [ :create, :download ]
    def show
      @requests = DataRequest.where(user: current_user).order(id: :desc).limit(30)
    end
    def create
      record = Privacy.request!(user: current_user, kind: params[:kind], details: params[:details])
      Privacy.export!(request: record, actor: current_user) if %w[access portability].include?(record.kind)
      redirect_to account_privacy_path, notice: "Votre demande a été enregistrée.", status: :see_other
    end
    def download
      record = DataRequest.where(user: current_user).find(params[:id])
      raise ActiveRecord::RecordNotFound unless record.export_available?
      response.headers["X-Content-Type-Options"] = "nosniff"
      send_data Privacy.encryptor.decrypt_and_verify(record.export_file.download), type: "application/json", disposition: "attachment", filename: "mes-donnees-seos.json"
    end
  end
end
