require "rails_helper"

RSpec.describe AdminActivity do
  it "agrège les jours de Paris, même avec deux heures UTC pour le même changement d’heure" do
    travel_to Time.zone.parse("2026-10-26 12:00") do
      owner = create(:profile, user: create(:user, created_at: 1.year.ago)).user
      %w[2026-10-24T22:30:00Z 2026-10-25T00:30:00Z 2026-10-25T01:30:00Z].each do |instant|
        create(:user, created_at: Time.iso8601(instant))
      end
      create(:user, created_at: Time.zone.parse("2026-10-18 12:00"))
      create(:user, created_at: 1.day.from_now)
      create(:listing, user: owner, published_at: Time.iso8601("2026-10-25T22:30:00Z"))
      create(:listing, user: owner, status: "removed", published_at: Time.iso8601("2026-10-24T23:00:00Z"))
      create(:listing, user: owner, status: "draft", published_at: nil)
      activity = described_class.new(period: 7, super_admin: false)
      expect(activity.series.size).to eq(7)
      expect(activity.series.find { |row| row[:date] == "2026-10-25" }).to eq(date: "2026-10-25", registrations: 3, publications: 2)
      expect(activity.registrations).to eq(3)
      expect(activity.previous_registrations).to eq(1)
      expect(activity.publications).to eq(2)
      expect(activity.listing_statuses).not_to have_key("draft")
      expect(activity.supervision).to be_nil
      expect(activity.series.first[:registrations]).to eq(0)
    end
  end

  it "borne la période et représente les jours sans activité avec des zéros" do
    activity = described_class.new(period: 999999, super_admin: true)
    expect(activity.days).to eq(30)
    expect(activity.series.size).to eq(30)
    expect(activity.series.sum { |row| row[:registrations] + row[:publications] }).to eq(0)
    expect(activity.supervision[:open_reports]).to eq(0)
  end
end
