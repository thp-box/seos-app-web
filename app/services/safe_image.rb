require "image_processing/vips"

class SafeImage
  TYPES = %w[image/jpeg image/png image/webp].freeze
  def self.attach!(attachment, upload)
    raise Exchanges::Invalid, "Choisissez une image JPEG, PNG ou WebP de 5 Mo maximum" unless upload.respond_to?(:tempfile) && upload.size <= 5.megabytes && TYPES.include?(upload.content_type)
    detected = Marcel::MimeType.for(upload.tempfile)
    raise Exchanges::Invalid, "Le contenu du fichier ne correspond pas à une image autorisée" unless TYPES.include?(detected) && detected == upload.content_type
    image = Vips::Image.new_from_file(upload.tempfile.path, access: :sequential)
    raise Exchanges::Invalid, "L’image dépasse 20 millions de pixels" if image.width * image.height > 20_000_000
    processed = ImageProcessing::Vips.source(upload.tempfile).resize_to_limit(1600, 1600).convert("jpg").saver(strip: true).call
    attachment.attach(io: StringIO.new(processed.read), filename: "image.jpg", content_type: "image/jpeg")
  rescue Vips::Error
    raise Exchanges::Invalid, "Cette image est illisible"
  ensure
    processed&.close!
  end
end
