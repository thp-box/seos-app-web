module Account
  class ProfilesController < BaseController
    def edit
      @profile = current_user.profile || current_user.build_profile(display_name: "")
    end
    def update
      @profile = current_user.profile || current_user.build_profile
      values = params.require(:profile).permit(:display_name, :bio, :public_city, :skills, :languages, :phone, :address_line, :phone_sharing_policy)
      @profile.assign_attributes(values)
      @profile.status = :published unless @profile.restricted? || @profile.anonymized?
      if @profile.save
        SafeImage.attach!(@profile.avatar, params[:profile][:avatar]) if params[:profile][:avatar].present?
        redirect_to edit_account_profile_path, notice: "Votre profil est enregistré.", status: :see_other
      else
        render :edit, status: :unprocessable_entity
      end
    end
  end
end
