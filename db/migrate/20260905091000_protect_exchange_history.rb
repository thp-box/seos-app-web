class ProtectExchangeHistory < ActiveRecord::Migration[8.1]
  def up
    execute "CREATE TRIGGER request_events_no_update BEFORE UPDATE ON request_events BEGIN SELECT RAISE(ABORT, 'request history is append-only'); END"
    execute "CREATE TRIGGER request_events_no_delete BEFORE DELETE ON request_events BEGIN SELECT RAISE(ABORT, 'request history is append-only'); END"
    execute "CREATE TRIGGER published_content_no_update BEFORE UPDATE ON content_versions WHEN OLD.published_at IS NOT NULL BEGIN SELECT RAISE(ABORT, 'published content is immutable'); END"
    execute "CREATE TRIGGER published_content_no_delete BEFORE DELETE ON content_versions WHEN OLD.published_at IS NOT NULL BEGIN SELECT RAISE(ABORT, 'published content is immutable'); END"
  end
  def down
    %w[request_events_no_update request_events_no_delete published_content_no_update published_content_no_delete].each { |name| execute "DROP TRIGGER #{name}" }
  end
end
