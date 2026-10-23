module Admin
  class PartnersController < BaseController
    before_action { raise Pundit::NotAuthorizedError unless current_user.super_admin? }
    before_action :load_page

    def create
      partner = @partnership_page.partner_entries.create!(partner_params)
      audit!(partner, "partner.created", "Ajout du partenaire #{partner.title}")
      redirect_to edit_admin_partnership_page_path(anchor: "partners"), notice: "Le partenaire a été ajouté.", status: :see_other
    end

    def update
      partner = @partnership_page.partner_entries.find(params[:id])
      partner.update!(partner_params)
      audit!(partner, "partner.updated", "Mise à jour du partenaire #{partner.title}")
      redirect_to edit_admin_partnership_page_path(anchor: "partner-#{partner.id}"), notice: "Le partenaire a été mis à jour.", status: :see_other
    end

    def destroy
      partner = @partnership_page.partner_entries.find(params[:id])
      title = partner.title
      partner.destroy!
      AuditLog.create!(actor: current_user, target: @partnership_page, action: "partner.deleted", reason: "Suppression du partenaire #{title}")
      redirect_to edit_admin_partnership_page_path(anchor: "partners"), notice: "Le partenaire a été supprimé.", status: :see_other
    end

    private

    def load_page = @partnership_page = PartnershipPage.current

    def partner_params
      params.require(:partner_entry).permit(:title, :description, :website_url, :position, :logo)
    end

    def audit!(partner, action, reason)
      AuditLog.create!(actor: current_user, target: partner, action: action, reason: reason)
    end
  end
end
