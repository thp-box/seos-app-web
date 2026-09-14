require "rails_helper"
require "tmpdir"
RSpec.describe SeosBackup do
  it "restaure une base et ses fichiers dans un dossier neuf et détecte une altération" do
    Dir.mktmpdir do |root|
      database = File.join(root, "source.sqlite3")
      db = SQLite3::Database.new(database)
      db.execute("CREATE TABLE checks (value TEXT)")
      db.execute("INSERT INTO checks VALUES ('restored')")
      db.close
      storage = File.join(root, "assets")
      FileUtils.mkdir_p(storage)
      File.write(File.join(storage, "file"), "Pièce de test")
      backup = File.join(root, "backup")
      restored = File.join(root, "restore")
      described_class.create!(database: database, storage: storage, destination: backup)
      described_class.restore!(source: backup, destination: restored)
      check = SQLite3::Database.new(File.join(restored, "primary.sqlite3"))
      expect(check.get_first_value("SELECT value FROM checks")).to eq("restored")
      check.close
      expect(File.read(File.join(restored, "storage/file"))).to eq("Pièce de test")
      expect { described_class.restore!(source: backup, destination: restored) }.to raise_error(ArgumentError)
      File.write(File.join(backup, "storage/file"), "altéré")
      expect { described_class.verify!(backup) }.to raise_error(RuntimeError, /altérée/)
    end
  end
end
