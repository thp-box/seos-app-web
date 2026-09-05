# No automatic public activation or founder exemption, including on repeated seeds.
if Rails.env.development?
  admin = User.find_by!(email: "superadmin@seos.test")
  TrustAlgorithmVersion.find_or_create_by!(version: "v1.0") do |version|
    version.created_by = admin
    version.configuration = TrustAlgorithmVersion::DEFAULT_CONFIGURATION
    version.explanation = "Formule bayésienne SEOS V1 : échanges confirmés, avis structurés révélés et parrainages limités."
  end
end
