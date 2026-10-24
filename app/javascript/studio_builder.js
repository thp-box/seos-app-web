import grapesjs from "grapesjs"
import "grapesjs/dist/css/grapes.min.css"
import "./stylesheets/studio_builder.css"

const root = document.querySelector("[data-studio-builder]")

if (root) {
  const config = JSON.parse(root.querySelector("[data-studio-config]").textContent)
  const library = root.querySelector("[data-studio-library]")
  const status = root.querySelector("[data-studio-status]")
  const saveButton = root.querySelector("[data-studio-save]")
  const csrf = document.querySelector("meta[name='csrf-token']")?.content
  let dirty = false
  let saving = false

  const esc = value => String(value || "").replace(/[&<>\"]/g, character => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" })[character])
  const svgIcon = path => `<svg viewBox="0 0 24 24" aria-hidden="true"><path d="${path}"/></svg>`
  const icons = {
    heading: "M5 6v12M19 6v12M5 12h14", paragraph: "M6 5h12M6 9h12M6 13h9M6 17h11",
    image: "M4 5h16v14H4z M6 17l4-5 3 3 2-2 4 4", button: "M4 8h16v8H4z M9 12h6",
    container: "M3 5h18v14H3z", columns: "M3 5h8v14H3z M13 5h8v14h-8z", divider: "M3 12h18",
    spacer: "M5 4h14M5 20h14M12 5v14M9 8l3-3 3 3M9 16l3 3 3-3", wave: "M2 15c4-7 7 7 11 0s6-3 9-1",
    bubbles: "M7 14a3 3 0 1 0 0-6 3 3 0 0 0 0 6zM16 18a4 4 0 1 0 0-8 4 4 0 0 0 0 8z",
    curve: "M2 18c5-13 15-13 20 0", diagonal: "M3 17 21 7v10H3z"
  }
  const imageSource = config.templates.image?.html?.match(/src="([^"]+)"/)?.[1] || ""
  const blocks = [
    ["heading", "Titre", "<h2>Votre nouveau titre</h2>", "Éléments"],
    ["paragraph", "Texte", "<p>Double-cliquez pour écrire votre texte.</p>", "Éléments"],
    ["image", "Image", `<figure><img src="${esc(imageSource)}" alt="Décrivez cette image"><figcaption>Votre légende</figcaption></figure>`, "Éléments"],
    ["button", "Bouton", '<a class="btn btn-deep" href="/contact">Votre bouton</a>', "Éléments"],
    ["divider", "Séparateur", "<hr>", "Éléments"],
    ["spacer", "Espace", '<div style="min-height:80px"></div>', "Éléments"],
    ["container", "Conteneur", '<div class="container" style="min-height:120px;padding:32px"></div>', "Mise en page"],
    ["columns", "2 colonnes", '<div class="studio-grid-2"><div style="min-height:120px;padding:24px"></div><div style="min-height:120px;padding:24px"></div></div>', "Mise en page"],
    ["wave", "Vague", '<div class="studio-transition studio-transition--wave"><svg viewBox="0 0 1200 120" preserveAspectRatio="none"><path d="M0 45 C240 120 420 0 660 55 C880 110 1020 18 1200 58 L1200 120 L0 120 Z"></path></svg></div>', "Transitions"],
    ["bubbles", "Bulles", '<div class="studio-transition studio-transition--bubbles"><span></span><span></span><span></span><span></span></div>', "Transitions"],
    ["curve", "Courbe", '<div class="studio-transition studio-transition--curve"><span></span></div>', "Transitions"],
    ["diagonal", "Diagonale", '<div class="studio-transition studio-transition--diagonal"><span></span></div>', "Transitions"]
  ]

  const editor = grapesjs.init({
    container: "#studio-v2-editor",
    height: "100%",
    width: "auto",
    storageManager: false,
    noticeOnUnload: false,
    telemetry: false,
    cssIcons: "",
    components: config.initialHtml,
    style: `${config.initialCss}\n.studio-grid-2{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:24px}.studio-transition{position:relative;min-height:90px;overflow:hidden}.studio-transition--wave svg{display:block;width:100%;height:var(--wave-height,90px);transform:rotate(var(--wave-angle,0deg));transform-origin:center}.studio-transition--wave path{fill:var(--wave-color,#d2b34e)}.studio-transition--bubbles span{position:absolute;border-radius:50%;background:var(--bubble-color,#d2b34e);opacity:.72}.studio-transition--bubbles span:nth-child(1){width:44px;height:44px;left:8%;top:24px}.studio-transition--bubbles span:nth-child(2){width:76px;height:76px;left:32%;top:5px}.studio-transition--bubbles span:nth-child(3){width:30px;height:30px;right:28%;top:40px}.studio-transition--bubbles span:nth-child(4){width:60px;height:60px;right:8%;top:15px}.studio-transition--curve span,.studio-transition--diagonal span{position:absolute;inset:0;background:var(--transition-color,#d2b34e)}.studio-transition--curve span{border-radius:50% 50% 0 0/100% 100% 0 0;transform:translateY(32%)}.studio-transition--diagonal span{clip-path:polygon(0 68%,100% 10%,100% 100%,0 100%)}@media(max-width:700px){.studio-grid-2{grid-template-columns:1fr}}`,
    canvas: { styles: config.stylesheets },
    blockManager: { appendTo: library },
    layerManager: { appendTo: "[data-studio-layers]" },
    traitManager: { appendTo: "[data-studio-traits]" },
    selectorManager: { componentFirst: true },
    deviceManager: { devices: [
      { id: "Desktop", name: "Ordinateur", width: "" },
      { id: "Tablet", name: "Tablette", width: "768px", widthMedia: "992px" },
      { id: "Mobile portrait", name: "Téléphone", width: "390px", widthMedia: "600px" }
    ] },
    styleManager: {
      appendTo: "[data-studio-styles]",
      sectors: [
        { name: "Typographie", open: true, buildProps: ["font-family", "font-size", "font-weight", "line-height", "letter-spacing", "color", "text-align", "text-decoration", "text-shadow"] },
        { name: "Dimensions et position", open: false, buildProps: ["display", "position", "top", "right", "bottom", "left", "width", "min-height", "max-width", "overflow"] },
        { name: "Espacement", open: false, buildProps: ["margin", "padding", "gap"] },
        { name: "Fond", open: false, buildProps: ["background-color", "background", "opacity"] },
        { name: "Bordure et forme", open: false, buildProps: ["border", "border-radius", "box-shadow"] },
        { name: "Transformation et animation", open: false, buildProps: ["transform", "transition", "animation"] }
      ]
    },
    panels: { defaults: [] },
    plugins: [instance => instance.DomComponents.addType("studio-chrome", {
      isComponent: element => element.hasAttribute?.("data-studio-chrome"),
      model: { defaults: { selectable: false, hoverable: false, draggable: false, droppable: false, copyable: false, removable: false } }
    })],
    richTextEditor: { actions: ["bold", "italic", "underline", "strikethrough", "link"] }
  })

  const categoryFor = key => {
    if (key.startsWith("home-")) return "Accueil"
    if (key.startsWith("travel-")) return "Voyage solidaire"
    if (key.startsWith("community-")) return "Communauté"
    if (/^(don|exchange|points)-/.test(key)) return "Don, échange et points"
    return "Compositions"
  }
  const addBlock = (id, name, html, category, kind = "widget") => editor.BlockManager.add(`seos-${id}`, {
    label: `<span class="visual-template-icon">${svgIcon(icons[id] || icons.container)}</span><strong>${esc(name)}</strong><button type="button" class="visual-template-add" tabindex="-1">＋</button>`,
    content: html,
    category: { id: `${kind}-${category}`, label: category, open: category === "Éléments" || category === "Compositions" },
    attributes: { "data-library-kind": kind, "data-block-id": `seos-${id}`, "data-search": `${name} ${category}`.toLowerCase(), title: `Glisser ${name}` }
  })
  blocks.forEach(block => addBlock(...block))
  Object.entries(config.templates).filter(([key]) => !["heading", "paragraph", "image", "button", "divider", "spacer", "text", "blank-section"].includes(key)).forEach(([key, value]) => addBlock(`preset-${key}`, value.name, value.html, categoryFor(key), "section"))

  const switchPanel = name => {
    root.querySelectorAll("[data-studio-tab]").forEach(button => button.classList.toggle("is-active", button.dataset.studioTab === name))
    root.querySelectorAll("[data-studio-panel]").forEach(panel => { panel.hidden = panel.dataset.studioPanel !== name; panel.classList.toggle("is-active", !panel.hidden) })
  }
  root.querySelectorAll("[data-studio-tab]").forEach(button => button.addEventListener("click", () => switchPanel(button.dataset.studioTab)))
  root.querySelector("[data-studio-back]").addEventListener("click", () => switchPanel("library"))

  const setSettingsTab = name => {
    root.querySelectorAll("[data-settings-tab]").forEach(button => button.classList.toggle("is-active", button.dataset.settingsTab === name))
    root.querySelectorAll("[data-settings-panel]").forEach(panel => { panel.hidden = panel.dataset.settingsPanel !== name })
  }
  root.querySelectorAll("[data-settings-tab]").forEach(button => button.addEventListener("click", () => setSettingsTab(button.dataset.settingsTab)))

  editor.on("component:selected", component => {
    const label = component.getName() || component.get("tagName") || "Élément"
    root.querySelector("[data-studio-selection-name]").textContent = label.charAt(0).toUpperCase() + label.slice(1)
    root.querySelector("[data-wave-controls]").hidden = !component.getClasses().includes("studio-transition--wave")
    switchPanel("settings")
  })
  editor.on("component:add component:remove component:update styleable:change", () => {
    dirty = true
    status.textContent = "Modifications non enregistrées"
    status.dataset.state = "dirty"
  })

  root.querySelectorAll("[data-device]").forEach(button => button.addEventListener("click", () => {
    editor.setDevice(button.dataset.device)
    root.querySelectorAll("[data-device]").forEach(item => item.classList.toggle("is-active", item === button))
  }))
  root.querySelectorAll("[data-studio-command]").forEach(button => button.addEventListener("click", () => editor.Commands.run(`core:${button.dataset.studioCommand}`)))
  root.querySelector("[data-studio-delete]").addEventListener("click", () => editor.getSelected()?.remove())
  root.querySelector("[data-studio-fullscreen]").addEventListener("click", () => root.classList.toggle("visual-focus"))
  root.querySelectorAll("[data-wave-control]").forEach(input => input.addEventListener("input", () => {
    const wave = editor.getSelected()
    if (!wave?.getClasses().includes("studio-transition--wave")) return
    const roundness = Number(root.querySelector('[data-wave-control="roundness"]').value)
    const depth = Number(root.querySelector('[data-wave-control="depth"]').value)
    const angle = Number(root.querySelector('[data-wave-control="angle"]').value)
    const first = Math.round(120 + roundness * 2.4)
    const second = Math.round(500 - roundness * 1.7)
    wave.components().at(0)?.components().at(0)?.addAttributes({ d: `M0 45 C${first} ${depth} ${second} ${110 - depth} 660 55 C880 ${depth + 35} 1020 ${Math.max(4, 55 - depth / 2)} 1200 58 L1200 120 L0 120 Z` })
    wave.addStyle({ "--wave-height": `${Math.max(40, depth + 25)}px`, "--wave-angle": `${angle}deg` })
    root.querySelector('[data-wave-output="roundness"]').textContent = `${roundness}%`
    root.querySelector('[data-wave-output="depth"]').textContent = `${depth}%`
    root.querySelector('[data-wave-output="angle"]').textContent = `${angle}°`
  }))

  const updateLibrary = () => {
    const view = root.dataset.libraryView || "widgets"
    const query = root.querySelector("[data-studio-search]").value.trim().toLowerCase()
    let count = 0
    library.querySelectorAll(".gjs-block").forEach(block => {
      const kind = block.dataset.libraryKind === "section" ? "sections" : "widgets"
      block.hidden = kind !== view || (query && !block.dataset.search.includes(query))
      if (!block.hidden) count += 1
    })
    library.querySelectorAll(".gjs-block-category").forEach(category => { category.hidden = !category.querySelector(".gjs-block:not([hidden])") })
    root.querySelector("[data-library-empty]").hidden = count > 0
  }
  root.dataset.libraryView = "widgets"
  root.querySelectorAll("[data-library-view]").forEach(button => button.addEventListener("click", () => {
    root.dataset.libraryView = button.dataset.libraryView
    root.querySelectorAll("[data-library-view]").forEach(item => item.classList.toggle("is-active", item === button))
    root.querySelector("[data-studio-search]").value = ""
    updateLibrary()
  }))
  root.querySelector("[data-studio-search]").addEventListener("input", updateLibrary)
  library.addEventListener("click", event => {
    const button = event.target.closest(".visual-template-add")
    if (!button) return
    event.preventDefault()
    event.stopPropagation()
    const blockElement = button.closest(".gjs-block")
    const block = editor.BlockManager.get(blockElement?.dataset.blockId)
    if (!block) return
    const added = editor.addComponents(block.get("content"))
    const selected = Array.isArray(added) ? added[0] : added
    if (selected) editor.select(selected)
  })

  const pages = root.querySelector("[data-studio-pages]")
  Object.entries(config.pages).forEach(([slug, page]) => pages.add(new Option(page.title || slug, slug, false, slug === config.page)))
  pages.addEventListener("change", () => {
    if (dirty && !window.confirm("Quitter cette page sans enregistrer les modifications ?")) { pages.value = config.page; return }
    const url = new URL(window.location.href); url.searchParams.set("page", pages.value); window.location.assign(url)
  })

  const save = async () => {
    if (saving) return null
    saving = true
    saveButton.disabled = true
    saveButton.textContent = "Enregistrement…"
    status.textContent = "Enregistrement…"
    const settings = structuredClone(config.settings)
    settings.site ||= {}; settings.site.pages ||= {}
    settings.site.pages[config.page] ||= config.pages[config.page]
    const document = new DOMParser().parseFromString(editor.getHtml(), "text/html")
    document.querySelectorAll("[data-studio-chrome]").forEach(element => element.remove())
    settings.site.pages[config.page].canvas = { version: 1, html: document.body.innerHTML, css: editor.getCss() }
    const body = new FormData()
    body.append("document", JSON.stringify({ site: settings.site, tokens: settings.tokens || {} }))
    body.append("digest", config.digest)
    body.append("page", config.page)
    try {
      const response = await fetch(config.save, { method: "POST", headers: { "X-CSRF-Token": csrf, Accept: "application/json" }, body })
      const result = await response.json()
      if (!response.ok) throw new Error(result.error || "Impossible d’enregistrer")
      config.digest = result.digest; config.save = result.save; config.review = result.review; config.settings = settings
      dirty = false; status.textContent = "Modifications enregistrées"; status.dataset.state = "saved"
      window.history.replaceState({}, "", result.url + `?page=${encodeURIComponent(config.page)}`)
      return result
    } catch (error) {
      status.textContent = error.message; status.dataset.state = "error"; return null
    } finally {
      saving = false
      saveButton.disabled = false
      saveButton.textContent = "Enregistrer"
    }
  }
  saveButton.addEventListener("click", save)
  root.querySelector("[data-studio-review]").addEventListener("click", async () => { const result = await save(); if (result) window.location.assign(result.review) })
  window.addEventListener("beforeunload", event => { if (dirty) event.preventDefault() })
  editor.on("load", () => { editor.UndoManager.clear(); dirty = false; updateLibrary(); status.textContent = "Cliquez sur n’importe quel élément pour le modifier." })
}
