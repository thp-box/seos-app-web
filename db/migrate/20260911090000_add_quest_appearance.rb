class AddQuestAppearance < ActiveRecord::Migration[8.1]
  def change
    add_column :achievements, :icon, :string, default: "spark", null: false
    add_column :achievements, :accent, :string, default: "ocean", null: false
    add_column :achievements, :animated, :boolean, default: true, null: false
  end
end
