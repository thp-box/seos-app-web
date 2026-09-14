class ProtectTrustConfiguration < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL
      CREATE TRIGGER trust_configuration_immutable BEFORE UPDATE ON trust_algorithm_versions
      WHEN NEW.configuration != OLD.configuration OR NEW.version != OLD.version OR NEW.explanation != OLD.explanation OR NEW.created_by_id != OLD.created_by_id
      BEGIN SELECT RAISE(ABORT, 'immutable trust configuration'); END
    SQL
  end

  def down
    execute "DROP TRIGGER trust_configuration_immutable"
  end
end
