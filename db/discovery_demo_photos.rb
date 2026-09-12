# Only complete the known local demo listings; never replace an existing photo.
if Rails.env.development?
  {
    "demo-bricolage" => "photo-1586023492125-27b2c045efd7a8d3f02d.jpg",
    "demo-numerique" => "photo-1516321318423-f06f85e504b3f27a878f.jpg",
    "demo-jardin" => "photo-1416879595882-3373a0480b5be3d794ff.jpg"
  }.each do |slug, filename|
    listing = Listing.joins(:user).find_by(slug: slug, users: { email: %w[membre@seos.test association@seos.test] })
    next unless listing && !listing.photos.attached?
    File.open(Rails.root.join("app/assets/images/maquette", filename)) do |file|
      listing.photos.attach(io: file, filename: filename, content_type: "image/jpeg")
    end
  end
end
