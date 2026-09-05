module SuperAdmin
  class MapSettingsController < BaseController
    def edit
      @flag = FeatureFlag.find_or_create_by!(key: "public_map_enabled")
    end
    def update
      @flag = FeatureFlag.find_or_create_by!(key: "public_map_enabled")
      @flag.with_lock do
        raise Exchanges::Invalid, "Ce réglage a changé ; rechargez la page" unless params[:lock_version].to_i == @flag.lock_version
        raise Exchanges::Invalid, "Un motif est obligatoire" if params[:reason].blank?
        previous = @flag.enabled.to_s
        @flag.update!(enabled: params[:reset] == "1" || params[:enabled] == "1")
        AuditLog.create!(actor: current_user, target: @flag, action: "map.updated", reason: params[:reason], metadata: { from: previous, to: @flag.enabled.to_s })
      end
      redirect_to edit_super_admin_map_setting_path, notice: "Réglage de la carte publié.", status: :see_other
    end
  end
end
