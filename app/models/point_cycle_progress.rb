class PointCycleProgress < ApplicationRecord
  belongs_to :user
  belongs_to :point_rule_version
  belongs_to :point_operation, optional: true
end
