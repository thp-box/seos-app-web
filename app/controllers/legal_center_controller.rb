class LegalCenterController < ApplicationController
  def show
    @documents = ContentVersion::LEGAL_SLUGS.filter_map { |slug| ContentVersion.current("legal", slug) }
  end
end
