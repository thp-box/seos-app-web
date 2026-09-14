class AddDailyPointsToVolunteerMissions < ActiveRecord::Migration[8.1]
  def change
    add_column :volunteer_missions, :daily_contribution_points, :integer, default: 0, null: false
    add_check_constraint :volunteer_missions, "daily_contribution_points >= 0", name: "mission_nonnegative_points"
  end
end
