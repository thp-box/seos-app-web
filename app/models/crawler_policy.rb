class CrawlerPolicy < ApplicationRecord
  belongs_to :author, class_name: "User"
  def readonly? = persisted?
  def self.current = order(id: :desc).first
end
