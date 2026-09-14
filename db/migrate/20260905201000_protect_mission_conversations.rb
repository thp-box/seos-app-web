class ProtectMissionConversations < ActiveRecord::Migration[8.1]
  def up
    %w[UPDATE DELETE].each { |action| execute "CREATE TRIGGER mission_messages_no_#{action.downcase} BEFORE #{action} ON mission_messages BEGIN SELECT RAISE(ABORT, 'immutable mission message'); END" }
    execute "CREATE TRIGGER mission_application_contract BEFORE UPDATE ON mission_applications WHEN NEW.volunteer_mission_id != OLD.volunteer_mission_id OR NEW.user_id != OLD.user_id OR NEW.message != OLD.message OR NEW.starts_on != OLD.starts_on OR NEW.ends_on != OLD.ends_on BEGIN SELECT RAISE(ABORT, 'immutable mission application'); END"
  end
  def down
    %w[update delete].each { |action| execute "DROP TRIGGER mission_messages_no_#{action}" }
    execute "DROP TRIGGER mission_application_contract"
  end
end
