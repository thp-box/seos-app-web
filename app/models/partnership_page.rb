class PartnershipPage < ApplicationRecord
  belongs_to :updated_by, class_name: "User", optional: true
  has_many :partner_entries, -> { order(:position, :id) }, dependent: :destroy

  validates :title, presence: true, length: { maximum: 150 }
  validates :introduction, length: { maximum: 600 }
  validates :body, length: { maximum: 20_000 }
  validates :contact_label, length: { maximum: 80 }
  validates :contact_url, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[https mailto]) }, allow_blank: true

  def self.current
    first_or_create!(title: "Nos partenaires", introduction: "Les structures qui contribuent au projet SEOS.", body: "Cette page sera prochainement enrichie.")
  end
end
