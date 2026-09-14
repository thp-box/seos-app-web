class AdminActivity
  attr_reader :days, :dates, :series, :registrations, :publications, :previous_registrations, :previous_publications, :accounts, :listing_statuses, :supervision

  def initialize(period:, super_admin:, now: Time.current)
    now = now.in_time_zone
    @days = [ 7, 30, 90 ].include?(period.to_i) ? period.to_i : 30
    @dates = ((now.to_date - @days + 1)..now.to_date).to_a
    # Aggregate at the hour in UTC, then assign each bucket to its Paris calendar day.
    # This preserves midnight and daylight-saving boundaries without loading member records.
    start = (@dates.first - @days).in_time_zone
    signups = daily_counts(User, :created_at, start, now)
    published = daily_counts(Listing, :published_at, start, now)
    @series = @dates.map { |date| { date: date.iso8601, registrations: signups.fetch(date, 0), publications: published.fetch(date, 0) } }
    @registrations = @series.sum { |row| row[:registrations] }
    @publications = @series.sum { |row| row[:publications] }
    @previous_registrations = signups.select { |date, _| date < @dates.first }.values.sum
    @previous_publications = published.select { |date, _| date < @dates.first }.values.sum
    @accounts = User.count
    scope = super_admin ? Listing.all : Listing.where.not(status: "draft")
    @listing_statuses = scope.group(:status).count
    @supervision = if super_admin
      { organizations_pending: Organization.where(status: "pending").count, published_missions: VolunteerMission.where(status: "published").count, open_reports: Report.where.not(status: "resolved").count }
    end
  end

  private

  def daily_counts(model, column, start, finish)
    expression = Arel.sql("strftime('%Y-%m-%d %H:00:00', #{model.quoted_table_name}.#{model.connection.quote_column_name(column)})")
    model.where(column => start..finish).group(expression).count.each_with_object(Hash.new(0)) do |(hour, count), totals|
      totals[Time.find_zone!("UTC").parse(hour).in_time_zone.to_date] += count
    end
  end
end
