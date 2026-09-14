class AddOrganizationRequestKind < ActiveRecord::Migration[8.1]
  def change
    add_column :organizations, :request_kind, :string
    add_check_constraint :organizations, "request_kind IS NULL OR request_kind IN ('partnership', 'community_mission')", name: "organizations_request_kind"
    remove_check_constraint :organizations, name: "organizations_kind", expression: "kind IN ('association', 'company', 'institution', 'collective')"
    add_check_constraint :organizations, "kind IN ('association', 'company', 'micro_company', 'institution', 'collective')", name: "organizations_kind"
  end
end
