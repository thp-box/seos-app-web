class PointRuleVersion < ApplicationRecord
  DEFAULT_ENGAGEMENT = {
    "welcome" => 30, "listing" => 10, "responses" => 10, "referral" => 15,
    "cycle_size" => 5, "cycle" => { "bronze" => 20, "silver" => 25, "gold" => 30 },
    "written" => { "bronze" => 10, "silver" => 15, "gold" => 20 },
    "video" => { "bronze" => 20, "silver" => 25, "gold" => 30 },
    "share" => 10, "chain" => 10, "chain_monthly_cap" => 30,
    "silver_after" => 5, "gold_after" => 20, "monthly_cap" => 300
  }.freeze
  DEFAULT_VALUATION = { "brackets" => (1..100).map { |n| { "from_cents" => n == 1 ? 0 : (n - 1) * 2000 + 1, "to_cents" => n * 2000, "points_from" => n * 10, "points_to" => n * 10 } } }.freeze
  belongs_to :created_by, class_name: "User", optional: true
  validates :family, inclusion: { in: %w[engagement valuation] }
  validates :status, inclusion: { in: %w[draft simulated published] }
  validates :name, presence: true, length: { maximum: 100 }
  validates :effective_at, presence: true
  validate :valid_configuration
  def readonly? = persisted? && status_in_database == "published"

  def self.current(family, at: Time.current)
    where(family: family, status: "published").where("effective_at <= ?", at).order(effective_at: :desc, id: :desc).first
  end

  def estimate(cents)
    raise Exchanges::Invalid, "Indiquez une valeur entière en centimes dans les bornes du barème." unless family == "valuation" && cents.is_a?(Integer) && cents >= 0
    configuration.fetch("brackets").find { |bracket| (bracket["from_cents"]..bracket["to_cents"]).cover?(cents) } || raise(Exchanges::Invalid, "Cette estimation dépasse le barème publié.")
  end

  private

  def valid_configuration
    unless configuration.is_a?(Hash)
      errors.add(:configuration, "doit être un objet de paramètres")
      return
    end
    valid = case family
    when "engagement"
      configuration.keys.sort == DEFAULT_ENGAGEMENT.keys.sort && configuration.all? { |key, value|
        if %w[cycle written video].include?(key)
          value.is_a?(Hash) && value.keys.sort == %w[bronze gold silver] && value.values.all? { |n| n.is_a?(Integer) && (1..1000).cover?(n) }
        else
          value.is_a?(Integer) && (1..10_000).cover?(value)
        end
      } && configuration["silver_after"] < configuration["gold_after"] && configuration["referral"] == 15 && configuration["chain_monthly_cap"] <= configuration["monthly_cap"]
    when "valuation"
      brackets = configuration["brackets"]
      configuration.keys == [ "brackets" ] && brackets.is_a?(Array) && (1..200).cover?(brackets.size) && brackets.each_with_index.all? { |row, index|
        row.is_a?(Hash) && row.keys.sort == %w[from_cents points_from points_to to_cents] && row.values.all? { |n| n.is_a?(Integer) } &&
          row["from_cents"] == (index.zero? ? 0 : brackets[index - 1]["to_cents"] + 1) && row["to_cents"] >= row["from_cents"] && row["to_cents"] <= 100_000_000 &&
          (1..999_999).cover?(row["points_from"]) && (row["points_from"]..999_999).cover?(row["points_to"])
      }
    end
    errors.add(:configuration, "doit respecter les bornes, les clés autorisées et des tranches continues sans chevauchement") unless valid
  end
end
