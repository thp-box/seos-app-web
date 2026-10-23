module Admin
  class PartnershipPagesController < BaseController
    before_action { raise Pundit::NotAuthorizedError unless current_user.super_admin? }
    before_action { @partnership_page = PartnershipPage.current }

    def edit
      @partners = @partnership_page.partner_entries.with_attached_logo
      @partner = PartnerEntry.new(position: (@partners.maximum(:position) || -1) + 1)
    end

    def update
      @partnership_page.update!(partnership_page_params.merge(updated_by: current_user))
      AuditLog.create!(actor: current_user, target: @partnership_page, action: "partnership_page.updated", reason: "Mise à jour de la page partenaires")
      redirect_to edit_admin_partnership_page_path, notice: "La page partenaires est à jour.", status: :see_other
    end

    private

    def partnership_page_params
      params.require(:partnership_page).permit(:title, :introduction, :body, :contact_label, :contact_url)
    end
  end
end
