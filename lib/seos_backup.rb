require "sqlite3"
require "fileutils"
require "digest"
require "json"
module SeosBackup
  # Run with application writers and workers stopped: database and files form one snapshot.
  def self.create!(database:, storage:, destination:)
    raise ArgumentError, "Destination déjà existante" if File.exist?(destination)
    FileUtils.mkdir_p(destination, mode: 0o700)
    source = SQLite3::Database.new(database, readonly: true)
    target = SQLite3::Database.new(File.join(destination, "primary.sqlite3"))
    backup = SQLite3::Backup.new(target, "main", source, "main")
    begin
      result = backup.step(-1)
      raise "Sauvegarde SQLite incomplète" unless result == SQLite3::Constants::ErrorCode::DONE
    ensure
      backup.finish
      target.close
      source.close
    end
    FileUtils.cp_r(storage, File.join(destination, "storage")) if File.directory?(storage)
    manifest = Dir.glob(File.join(destination, "**", "*"), File::FNM_DOTMATCH).select { |file| File.file?(file) }.to_h do |file|
      [ file.delete_prefix("#{destination}/"), Digest::SHA256.file(file).hexdigest ]
    end
    File.write(File.join(destination, "manifest.json"), JSON.pretty_generate(manifest), mode: "w", perm: 0o600)
    verify!(destination)
  end
  def self.verify!(directory)
    manifest = JSON.parse(File.read(File.join(directory, "manifest.json")))
    manifest.each do |relative, hash|
      raise "Chemin de sauvegarde invalide" if relative.start_with?("/") || relative.split("/").include?("..")
      file = File.join(directory, relative)
      raise "Sauvegarde altérée : #{relative}" unless File.file?(file) && Digest::SHA256.file(file).hexdigest == hash
    end
    database = SQLite3::Database.new(File.join(directory, "primary.sqlite3"), readonly: true)
    begin
      raise "Intégrité SQLite invalide" unless database.get_first_value("PRAGMA integrity_check") == "ok"
      raise "Clés étrangères invalides" unless database.execute("PRAGMA foreign_key_check").empty?
    ensure
      database.close
    end
    true
  end
  def self.restore!(source:, destination:)
    raise ArgumentError, "La restauration exige un répertoire neuf" if File.exist?(destination)
    verify!(source)
    FileUtils.mkdir_p(destination, mode: 0o700)
    FileUtils.cp_r(Dir.glob(File.join(source, "*")), destination)
    verify!(destination)
  end
end
