class ProtectCommunityHistory < ActiveRecord::Migration[8.1]
  def up
    %w[chain_rewards payment_events].each do |table|
      %w[UPDATE DELETE].each { |action| execute "CREATE TRIGGER #{table}_no_#{action.downcase} BEFORE #{action} ON #{table} BEGIN SELECT RAISE(ABORT, 'immutable community history'); END" }
    end
    %w[UPDATE DELETE].each { |action| execute "CREATE TRIGGER chain_rules_no_#{action.downcase} BEFORE #{action} ON chain_rule_versions WHEN OLD.status = 'published' BEGIN SELECT RAISE(ABORT, 'immutable chain rule'); END" }
    execute "CREATE TRIGGER chain_service_confirmed_immutable BEFORE UPDATE ON chain_services WHEN OLD.status = 'confirmed' BEGIN SELECT RAISE(ABORT, 'immutable confirmed chain service'); END"
    execute "CREATE TRIGGER chain_contract_immutable BEFORE UPDATE ON help_chains WHEN NEW.chain_rule_version_id != OLD.chain_rule_version_id OR NEW.point_rule_version_id != OLD.point_rule_version_id OR NEW.creator_id != OLD.creator_id BEGIN SELECT RAISE(ABORT, 'immutable chain contract'); END"
  end
  def down
    %w[chain_rewards payment_events].each { |table| %w[update delete].each { |action| execute "DROP TRIGGER #{table}_no_#{action}" } }
    %w[update delete].each { |action| execute "DROP TRIGGER chain_rules_no_#{action}" }
    execute "DROP TRIGGER chain_service_confirmed_immutable"
    execute "DROP TRIGGER chain_contract_immutable"
  end
end
