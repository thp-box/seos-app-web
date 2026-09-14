require "open3"
require "timeout"

class SafeVideo
  def self.attach!(attachment, upload)
    raise Exchanges::Invalid, "Choisissez une vidéo MP4 de 25 Mo maximum, avec sa transcription." unless upload.respond_to?(:tempfile) && upload.size <= 25.megabytes && upload.content_type == "video/mp4"
    data = JSON.parse(run!("ffprobe", "-v", "error", "-protocol_whitelist", "file,pipe", "-format_whitelist", "mov", "-show_format", "-show_streams", "-of", "json", upload.tempfile.path))
    video = data.fetch("streams").find { |stream| stream["codec_type"] == "video" }
    duration = Float(data.dig("format", "duration"), exception: false)
    raise Exchanges::Invalid, "La vidéo doit durer au plus 3 minutes et mesurer au plus 1920 × 1920 pixels." unless video && duration && duration.positive? && duration <= 180 && video["width"].between?(1, 1920) && video["height"].between?(1, 1920)
    Tempfile.create([ "seos-video", ".mp4" ]) do |output|
      run!("ffmpeg", "-v", "error", "-nostdin", "-y", "-protocol_whitelist", "file,pipe", "-format_whitelist", "mov", "-i", upload.tempfile.path, "-map", "0:v:0", "-map", "0:a:0?", "-map_metadata", "-1", "-c:v", "libx264", "-preset", "fast", "-pix_fmt", "yuv420p", "-c:a", "aac", "-movflags", "+faststart", "-t", "180", "-fs", "26214400", output.path)
      attachment.attach(io: StringIO.new(File.binread(output.path)), filename: "temoignage.mp4", content_type: "video/mp4")
    end
  rescue JSON::ParserError, KeyError, Errno::ENOENT
    raise Exchanges::Invalid, "Vidéo illisible ou traitement vidéo indisponible. Réessayez plus tard."
  end

  def self.run!(*arguments)
    Open3.popen3(*arguments) do |stdin, stdout, stderr, thread|
      stdin.close
      reader = Thread.new { stderr.read }
      begin
        result = Timeout.timeout(120) { output = stdout.read; raise Exchanges::Invalid, "Vidéo illisible." unless thread.value.success?; output }
        reader.value
        result
      rescue Timeout::Error
        Process.kill("KILL", thread.pid)
        thread.join
        raise Exchanges::Invalid, "Le traitement vidéo a dépassé le délai autorisé."
      ensure
        reader.join
      end
    end
  end
end
