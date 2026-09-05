class ProtectPointsLedger < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL
      CREATE TRIGGER point_entry_insert_guard BEFORE INSERT ON point_entries BEGIN
        SELECT CASE WHEN (SELECT status FROM point_operations WHERE id = NEW.point_operation_id) != 'pending'
          THEN RAISE(ABORT, 'operation already committed') END;
        SELECT CASE WHEN NEW.balance_after != (SELECT balance FROM point_accounts WHERE id = NEW.point_account_id) + NEW.amount
          THEN RAISE(ABORT, 'incorrect resulting balance') END;
      END
    SQL
    execute <<~SQL
      CREATE TRIGGER point_entry_balance AFTER INSERT ON point_entries BEGIN
        UPDATE point_accounts SET balance = NEW.balance_after WHERE id = NEW.point_account_id;
      END
    SQL
    execute <<~SQL
      CREATE TRIGGER point_balance_derived BEFORE UPDATE ON point_accounts
      WHEN NEW.user_id IS NOT OLD.user_id OR NEW.kind != OLD.kind OR NEW.balance != COALESCE((SELECT SUM(amount) FROM point_entries WHERE point_account_id = OLD.id), 0)
      BEGIN SELECT RAISE(ABORT, 'balance must follow ledger'); END
    SQL
    execute <<~SQL
      CREATE TRIGGER point_account_initial_zero BEFORE INSERT ON point_accounts
      WHEN NEW.balance != 0 BEGIN SELECT RAISE(ABORT, 'account must start at zero'); END
    SQL
    execute <<~SQL
      CREATE TRIGGER point_operation_commit BEFORE UPDATE ON point_operations BEGIN
        SELECT CASE WHEN OLD.status != 'pending' OR NEW.status != 'committed' OR NEW.committed_at IS NULL
          OR NEW.kind != OLD.kind OR NEW.idempotency_key != OLD.idempotency_key OR NEW.reason != OLD.reason
          OR NEW.source_type != OLD.source_type OR NEW.source_id != OLD.source_id
          OR NEW.initiator_id IS NOT OLD.initiator_id OR NEW.point_rule_version_id IS NOT OLD.point_rule_version_id
          OR NEW.reversed_operation_id IS NOT OLD.reversed_operation_id OR NEW.created_at != OLD.created_at
          THEN RAISE(ABORT, 'immutable point operation') END;
        SELECT CASE WHEN (SELECT COUNT(*) FROM point_entries WHERE point_operation_id = OLD.id) != 2
          OR (SELECT COALESCE(SUM(amount), 0) FROM point_entries WHERE point_operation_id = OLD.id) != 0
          THEN RAISE(ABORT, 'unbalanced point operation') END;
      END
    SQL
    execute "CREATE TRIGGER point_operation_starts_pending BEFORE INSERT ON point_operations WHEN NEW.status != 'pending' BEGIN SELECT RAISE(ABORT, 'operation must start pending'); END"
    %w[UPDATE DELETE].each do |action|
      execute "CREATE TRIGGER point_entries_no_#{action.downcase} BEFORE #{action} ON point_entries BEGIN SELECT RAISE(ABORT, 'immutable point entries'); END"
    end
    execute "CREATE TRIGGER point_operations_no_delete BEFORE DELETE ON point_operations BEGIN SELECT RAISE(ABORT, 'immutable point operation'); END"
    execute "CREATE TRIGGER point_rules_no_update BEFORE UPDATE ON point_rule_versions WHEN OLD.status = 'published' BEGIN SELECT RAISE(ABORT, 'immutable published point rule'); END"
    execute "CREATE TRIGGER point_rules_no_delete BEFORE DELETE ON point_rule_versions WHEN OLD.status = 'published' BEGIN SELECT RAISE(ABORT, 'immutable published point rule'); END"
  end

  def down
    %w[point_entry_insert_guard point_entry_balance point_balance_derived point_account_initial_zero point_operation_commit point_operation_starts_pending point_entries_no_update point_entries_no_delete point_operations_no_delete point_rules_no_update point_rules_no_delete].each { |name| execute "DROP TRIGGER #{name}" }
  end
end
