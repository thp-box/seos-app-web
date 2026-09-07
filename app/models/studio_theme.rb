# Selectors are application-owned; values have already passed StudioVersion's allowlists.
class StudioTheme
  def self.css(tokens)
    rules = []
    rules << ".btn,.maquette-surface .btn{border-radius:var(--button-radius)}" if tokens.key?("button-radius")
    rules << ".card,.maquette-surface :is(.exchange-card,.ad-card,.travel-card,.support-card,.testimonial){border-radius:var(--card-radius)}" if tokens.key?("card-radius")
    rules << ".section,.maquette-surface .section{padding-block:var(--section-space)}" if tokens.key?("section-space")
    wave = ".hero::after,.maquette-surface .hero-wave,.section-decoration,.maquette-surface .hero-organic-cut,.maquette-surface .page-hero-organic-cut,.maquette-surface .yoga-separator"
    rules << "#{wave}{height:var(--wave-height)}" if tokens.key?("wave-height")
    shapes = { "wave" => "58% 42% 0 0 / 70% 90% 0 0", "curve" => "50% 50% 0 0 / 100% 100% 0 0", "diagonal" => "0", "flat" => "0" }
    if tokens.key?("wave-shape")
      rules << ".maquette-surface :is(.hero-organic-cut,.page-hero-organic-cut,.yoga-separator){background:var(--cream)}.maquette-surface :is(.hero-organic-cut,.page-hero-organic-cut,.yoga-separator)>svg{display:none}"
      rules << "#{wave}{border-radius:#{shapes.fetch(tokens['wave-shape'])};clip-path:#{tokens['wave-shape'] == 'diagonal' ? 'polygon(0 100%,100% 0,100% 100%)' : 'none'}}"
    end
    if tokens.key?("wave-speed") || tokens.key?("wave-amplitude") || tokens["motion"].in?(%w[subtle standard])
      amplitude = tokens["motion"] == "subtle" ? "8px" : "16px"
      rules << "#{wave}{animation:seos-wave var(--wave-speed,8s) ease-in-out infinite alternate}"
      rules << "@keyframes seos-wave{from{translate:0 0}to{translate:0 var(--wave-amplitude,#{amplitude})}}"
    end
    rules << ".topbar{background:linear-gradient(90deg,var(--deep),var(--footer))}" if tokens.key?("deep") || tokens.key?("footer")
    rules << ".maquette-surface.maquette-surface{font-family:var(--font-body)}" if tokens.key?("font-body")
    rules << ".maquette-surface :is(h1,h2,h3){font-family:var(--font-heading)}" if tokens.key?("font-heading")
    rules << "@media(prefers-reduced-motion:reduce){*,*::before,*::after{animation:none!important;transition:none!important;scroll-behavior:auto!important}}"
    rules.join
  end
end
