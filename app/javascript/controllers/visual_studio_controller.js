import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["status", "guided", "layers", "pages", "pageName", "library", "theme", "inspector", "frame", "frameWrap", "previewForm", "document", "slug", "revision"]
  static values = { state: Object, saveUrl: String }

  connect() {
    this.config = this.stateValue
    this.doc = structuredClone(this.config.settings)
    this.doc.site ||= {}; this.doc.site.pages ||= {}; this.doc.tokens ||= {}
    this.page = this.config.page
    this.digest = this.config.digest
    this.saved = JSON.stringify(this.doc)
    this.controlId = 0; this.past = []; this.future = []; this.sequence = 0; this.width = 1440
    this.beforeLeave = event => { if (this.dirty) { event.preventDefault(); event.returnValue = "" } }
    window.addEventListener("beforeunload", this.beforeLeave)
    this.beforeTurboVisit = event => { if (this.dirty && !window.confirm("Quitter le Studio sans enregistrer vos dernières modifications ?")) event.preventDefault() }
    document.addEventListener("turbo:before-visit", this.beforeTurboVisit)
    this.observer = new ResizeObserver(() => this.fitFrame())
    this.observer.observe(this.frameWrapTarget)
    this.renderPages(); this.renderLibrary(); this.renderTheme(); this.refresh()
  }
  disconnect() {
    clearTimeout(this.timer); this.observer.disconnect()
    window.removeEventListener("beforeunload", this.beforeLeave)
    document.removeEventListener("turbo:before-visit", this.beforeTurboVisit)
  }
  get dirty() { return JSON.stringify(this.doc) !== this.saved }
  get currentPage() { return this.doc.site.pages[this.page] || this.config.pages[this.page] }
  get blocks() { return this.currentPage?.blocks || [] }
  get selected() { return this.blocks.find(block => block.id === this.selectedId) }
  message(text) { this.statusTarget.textContent = text }
  node(tag, text, className) {
    const node = document.createElement(tag)
    if (text !== undefined) node.textContent = text
    if (className) node.className = className
    return node
  }
  button(text, callback, parent, className = "btn btn-outline") {
    const button = this.node("button", text, className); button.type = "button"
    button.addEventListener("click", callback); parent.append(button); return button
  }
  field(parent, label, value, choices, callback, type = "text", help = "") {
    const wrapper = this.node("div", undefined, "form-field")
    const id = `visual-control-${++this.controlId}`
    const caption = this.node("label", label); caption.htmlFor = id; wrapper.append(caption)
    let input
    if (choices) {
      input = this.node("select")
      choices.forEach(([text, value]) => { const option = this.node("option", text); option.value = value; input.append(option) })
    } else if (type === "textarea") { input = this.node("textarea"); input.rows = 3; input.maxLength = 15000 }
    else { input = this.node("input"); input.type = type; if (type === "number") { input.min = 8; input.max = 1200; input.step = 1; input.required = true }; if (type === "text") input.maxLength = 15000 }
    input.id = id; input.className = "control"; input.value = value ?? ""
    if (help) { const hint = this.node("small", help); hint.id = `${id}-help`; input.setAttribute("aria-describedby", hint.id); wrapper.append(hint) }
    input.addEventListener(choices ? "change" : "input", () => callback(input.value))
    wrapper.append(input); parent.append(wrapper); return input
  }
  details(parent, title, open = false, name = "visual-inspector") {
    const details = this.node("details"); details.open = open; details.name = name
    details.append(this.node("summary", title)); parent.append(details); return details
  }
  change(callback) {
    const before = JSON.stringify(this.doc)
    callback()
    if (JSON.stringify(this.doc) === before) return
    this.past.push(before); if (this.past.length > 40) this.past.shift(); this.future = []
    this.renderLayers()
    this.message("Modifications visibles dans l’aperçu — pensez à enregistrer.")
    clearTimeout(this.timer); this.timer = setTimeout(() => this.refresh(), 350)
  }
  ensurePage() {
    this.doc.site.pages[this.page] ||= structuredClone(this.config.pages[this.page] || { title: this.page, blocks: [] })
    return this.doc.site.pages[this.page]
  }
  undo() {
    if (!this.past.length) return
    this.future.push(JSON.stringify(this.doc)); this.doc = JSON.parse(this.past.pop()); this.restore()
  }
  redo() {
    if (!this.future.length) return
    this.past.push(JSON.stringify(this.doc)); this.doc = JSON.parse(this.future.pop()); this.restore()
  }
  restore() {
    if (this.doc.site.deleted_pages?.includes(this.page) || (!this.doc.site.pages[this.page] && !this.config.pages[this.page])) this.page = "home"
    this.renderPages(); this.renderTheme(); this.inspect(); this.refresh()
    this.message(this.dirty ? "Modification annulée ou rétablie — copie non enregistrée." : "Vous êtes revenu à la copie enregistrée.")
  }
  renderPages() {
    this.pagesTarget.replaceChildren()
    Object.entries({ ...this.config.pages, ...this.doc.site.pages }).forEach(([slug, page]) => {
      if (this.doc.site.deleted_pages?.includes(slug)) return
      const option = this.node("option", page.title); option.value = slug; this.pagesTarget.append(option)
    })
    this.pagesTarget.value = this.page
    this.updateGuided()
    this.renderLayers()
  }
  updateGuided() {
    const url = new URL(this.guidedTarget.href)
    url.searchParams.set("page", this.page)
    this.guidedTarget.href = url.pathname + url.search
  }
  renderLayers() {
    this.layersTarget.replaceChildren()
    this.blocks.forEach((block, index) => this.button(`${index + 1}. ${this.config.templates[block.template].name}${block.hidden ? " — masquée" : ""}`, () => { this.selectedId = block.id; this.selectedField = null; this.inspect(); this.highlight(); this.frameTarget.contentDocument?.getElementById(`site-section-${block.id}`)?.scrollIntoView({ block: "center" }) }, this.layersTarget))
    if (!this.blocks.length) this.layersTarget.append(this.node("p", "Ajoutez une section pour commencer la composition de cette page."))
  }
  changePage() { this.page = this.pagesTarget.value; this.updateGuided(); this.selectedId = null; this.renderLayers(); this.inspect(); this.refresh() }
  createPage() {
    const title = this.pageNameTarget.value.trim()
    if (!title || title.length > 100) { this.message("Donnez un nom à votre page (100 caractères maximum)."); return }
    let base = title.normalize("NFD").replace(/[\u0300-\u036f]/g, "").toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "").slice(0, 60) || "page"
    if (!/^[a-z]/.test(base)) base = `page-${base}`
    let slug = base, i = 2
    while (this.doc.site.pages[slug] || this.config.pages[slug] || this.doc.site.deleted_pages?.includes(slug)) slug = `${base}-${i++}`
    this.change(() => { this.doc.site.pages[slug] = { title, blocks: [{ id: crypto.randomUUID(), template: "text", values: { title, body: "" } }] } })
    this.page = slug; this.selectedId = this.blocks[0].id; this.pageNameTarget.value = ""
    this.renderPages(); this.inspect(); this.refresh()
  }
  deletePage() {
    if (["home", "accueil", "annonces", "listings"].includes(this.page)) { this.message("L’accueil et les annonces ne peuvent pas être supprimés."); return }
    if (!window.confirm(`Retirer la page « ${this.currentPage.title} » de cette copie ?`)) return
    this.change(() => { delete this.doc.site.pages[this.page]; this.doc.site.deleted_pages = [...new Set([...(this.doc.site.deleted_pages || []), this.page])] }); this.page = "home"; this.selectedId = null
    this.renderPages(); this.inspect(); this.refresh()
  }
  renderLibrary() {
    this.libraryTarget.replaceChildren()
    Object.entries(this.config.templates).forEach(([key, template]) => {
      const item = this.node("div", undefined, "visual-template"); item.draggable = true
      item.dataset.template = key
      item.append(this.node("strong", template.name))
      item.addEventListener("dragstart", event => { this.drag = { template: key }; event.dataTransfer.setData("text/plain", key); event.dataTransfer.effectAllowed = "copy" })
      this.button("Ajouter", () => this.add(key, this.blocks.length), item)
      this.libraryTarget.append(item)
    })
  }
  add(template, index) {
    if (this.blocks.length >= 40) { this.message("Cette page contient déjà 40 sections."); return }
    if (!this.doc.site.pages[this.page] && this.page === "home" && !window.confirm("L’accueil utilise encore la présentation de départ. Ajouter une section prépare une nouvelle composition ; l’accueil actuel reste en ligne jusqu’à votre publication. Continuer ?")) return
    const block = { id: crypto.randomUUID(), template, values: {} }
    if (template === "text") block.values = { title: "Votre titre", body: "Votre texte à écrire ici." }
    this.change(() => this.ensurePage().blocks.splice(index, 0, block))
    this.selectedId = block.id; this.focusBlock = block.id; this.selectedField = null; this.inspect()
  }
  move(id, index) {
    this.change(() => {
      const blocks = this.ensurePage().blocks, old = blocks.findIndex(block => block.id === id)
      if (old < 0) return
      const [block] = blocks.splice(old, 1); blocks.splice(Math.max(0, index > old ? index - 1 : index), 0, block)
    })
    this.inspect()
  }
  renderTheme() {
    this.themeTarget.replaceChildren()
    const colors = this.details(this.themeTarget, "Couleurs", true, "visual-theme")
    Object.entries(this.config.colors).forEach(([key, value]) => {
      this.field(colors, this.config.colorNames[key], this.doc.tokens[key] || value, null, color => {
        this.change(() => { this.doc.tokens[key] = color })
        this.frameTarget.contentDocument?.documentElement.style.setProperty(`--${key}`, color)
      }, "color")
    })
    const effects = this.details(this.themeTarget, "Vagues et mouvements", false, "visual-theme")
    const appearance = this.details(this.themeTarget, "Écriture, tailles et formes", false, "visual-theme")
    Object.entries(this.config.options).forEach(([key, option]) => {
      const parent = key.startsWith("wave-") || key === "motion" ? effects : appearance
      this.field(parent, option.label, this.doc.tokens[key] || "", [["Réglage d’origine", ""], ...option.choices], value => this.change(() => { if (value) this.doc.tokens[key] = value; else delete this.doc.tokens[key] }))
    })
    this.button("Ambiance organique douce", () => {
      this.change(() => Object.assign(this.doc.tokens, { motion: "subtle", "wave-height": "100px", "wave-speed": "12s", "wave-amplitude": "8px", "wave-shape": "wave", "card-radius": "38px" }))
      this.renderTheme()
    }, effects)
    effects.append(this.node("p", "Les préférences de réduction des animations des visiteurs sont respectées."))
  }
  inspect() {
    this.inspectorTarget.replaceChildren()
    if (!this.selected) { this.inspectorTarget.append(this.node("p", "Cliquez sur un texte, une photo ou une section dans l’aperçu.")); return }
    const block = this.selected, template = this.config.templates[block.template]
    this.inspectorTarget.append(this.node("h2", template.name))
    this.field(this.inspectorTarget, "Élément à modifier", this.selectedField || "", [["Toute la section", ""], ...Object.values(template.groups).flat().map(field => [field.label, field.key])], value => { this.selectedField = value || null; this.inspect() })
    const actions = this.node("div", undefined, "actions"); this.inspectorTarget.append(actions)
    this.button("Monter", () => this.move(block.id, this.blocks.indexOf(block) - 1), actions)
    this.button("Descendre", () => this.move(block.id, this.blocks.indexOf(block) + 2), actions)
    this.button(block.hidden ? "Afficher la section" : "Masquer la section", () => { this.change(() => { block.hidden = !block.hidden }); this.inspect() }, actions)
    this.button("Dupliquer", () => {
      if (this.blocks.length >= 40) return
      this.change(() => this.ensurePage().blocks.splice(this.blocks.indexOf(block) + 1, 0, { ...structuredClone(block), id: crypto.randomUUID() }))
    }, actions)
    this.button("Retirer la section", () => { this.change(() => { this.ensurePage().blocks = this.blocks.filter(item => item.id !== block.id) }); this.selectedId = null; this.inspect() }, actions)
    Object.entries(template.groups).forEach(([title, fields], index) => {
      const group = this.details(this.inspectorTarget, title, this.selectedField ? fields.some(field => field.key === this.selectedField) : index === 0)
      fields.forEach(field => {
        const key = field.key
        this.field(group, field.label, block.values[key] ?? (block.template === "text" && ["url", "label"].includes(key) ? "" : field.default), field.type === "image" ? this.config.images : null,
          value => this.change(() => {
            block.values[key] = value
            if (block.template === "text" && !block.values.label && !block.values.url) { delete block.values.label; delete block.values.url }
          }), field.type === "height" ? "number" : field.type === "text" ? "textarea" : "text", field.help)
      })
    })
    if (block.template === "spacer") return
    if (this.selectedField && template.fields[this.selectedField] && template.fields[this.selectedField].type !== "url") {
      const field = this.selectedField
      const group = this.details(this.inspectorTarget, "Taille et animation de cet élément")
      group.append(this.node("p", "Ces réglages s’appliquent uniquement à l’élément cliqué dans l’aperçu."))
      this.styleFields(group, block.elements?.[field] || {}, values => { block.elements ||= {}; block.elements[field] = values }, false, template.fields[field].type === "image")
    }
    const style = this.details(this.inspectorTarget, "Taille, espacement et effets de la section")
    this.styleFields(style, block.style || {}, values => { block.style = values }, true)
    this.field(style, "Séparation décorative", block.separator || "none", [["Aucune", "none"], ...this.config.presets.map(key => [({ wave_single: "Vague douce", wave_double: "Deux vagues superposées", soft_curve: "Courbe douce", asymmetric_blob: "Forme organique", scallop: "Petites ondulations", diagonal_soft: "Diagonale douce", mist_fade: "Dégradé léger" })[key] || key.replaceAll("-", " "), key])], value => this.change(() => { block.separator = value }))
    this.field(style, "Position de la séparation", block.placement || "bottom", [["Après la section", "bottom"], ["Avant la section", "top"]], value => this.change(() => { block.placement = value }))
  }
  styleFields(parent, style, setter, section, image = false) {
    const labels = { size: section ? "Taille des titres" : "Taille de l’élément", space: "Espace autour du contenu", shape: "Forme des images", animation: "Animation" }
    Object.entries(this.config.styles).forEach(([key, options]) => {
      if (!section && (key === "space" || (key === "shape" && !image))) return
      this.field(parent, labels[key], style[key] || (key === "animation" ? "none" : "normal"), Object.entries(options).map(([value, label]) => [label, value]), value => this.change(() => { style[key] = value; setter(style) }))
    })
  }
  header() { this.inspectChrome("header") }
  footer() { this.inspectChrome("footer") }
  inspectChrome(area) {
    this.selectedId = null; this.inspectorTarget.replaceChildren()
    this.inspectorTarget.append(this.node("h2", area === "header" ? "Haut du site" : "Bas du site"))
    const chrome = { ...structuredClone(this.config.chrome[area]), ...this.doc.site[area] }
    const labels = { logo: "Logo", alt: "Description du logo", title: "Texte principal", description: "Informations complémentaires", mobile_join_label: "Inscription sur mobile", join_label: "Bouton d’inscription", login_label: "Lien de connexion", account_label: "Menu du compte" }
    Object.entries(chrome).filter(([key]) => key !== "links").forEach(([key, value]) => {
      this.field(this.inspectorTarget, labels[key], value, key === "logo" ? this.config.images : null, value => this.change(() => { chrome[key] = value; this.doc.site[area] = chrome }), "text")
    })
    const links = this.details(this.inspectorTarget, "Liens du menu")
    chrome.links.forEach((link, index) => {
      const group = this.node("fieldset"); group.append(this.node("legend", `Lien ${index + 1}`)); links.append(group)
      this.field(group, "Texte du lien", link.label, null, value => this.change(() => { link.label = value; this.doc.site[area] = chrome }))
      this.field(group, "Page à ouvrir", link.url, null, value => this.change(() => { link.url = value; this.doc.site[area] = chrome }))
      this.button("Retirer ce lien", () => { this.change(() => { chrome.links.splice(index, 1); this.doc.site[area] = chrome }); this.inspectChrome(area) }, group)
    })
    this.button("Ajouter un lien", () => {
      if (chrome.links.length >= 12) return
      this.change(() => { chrome.links.push({ label: "Nouveau lien", url: "/contact" }); this.doc.site[area] = chrome }); this.inspectChrome(area)
    }, links)
  }
  refresh() {
    clearTimeout(this.timer)
    this.scrollPosition = this.frameTarget.contentWindow?.scrollY || 0
    this.documentTarget.value = JSON.stringify(this.doc); this.slugTarget.value = this.page
    this.revisionTarget.value = String(++this.sequence)
    this.previewFormTarget.submit()
  }
  frameLoaded() {
    const doc = this.frameTarget.contentDocument
    if (!doc?.querySelector("meta[name='studio-preview-revision']")) {
      if (doc?.body?.textContent.trim()) this.message("L’aperçu ne peut pas être affiché. Vérifiez les champs saisis et votre connexion ; vos modifications restent dans cet écran.")
      return
    }
    if (doc.querySelector("meta[name='studio-preview-revision']").content !== String(this.sequence)) return
    doc.body.classList.add("studio-visual-preview")
    // Capture before Turbo's document listeners, so selecting a link never navigates the frame.
    doc.defaultView.addEventListener("submit", event => { event.preventDefault(); event.stopImmediatePropagation() }, true)
    doc.defaultView.addEventListener("click", event => {
      event.preventDefault(); event.stopImmediatePropagation()
      const wrapper = event.target.closest("[data-studio-block]")
      if (wrapper) {
        this.selectedId = wrapper.dataset.studioBlock
        this.selectedField = event.target.closest("[data-field],[data-image],[data-link]")?.dataset
        this.selectedField = this.selectedField?.field || this.selectedField?.image || this.selectedField?.link
        this.inspect(); this.highlight()
      } else if (event.target.closest("body > header")) this.header()
      else if (event.target.closest("body > footer")) this.footer()
    }, true)
    const wrappers = Array.from(doc.querySelectorAll("[data-studio-block]"))
    wrappers.forEach(wrapper => {
      wrapper.draggable = true; wrapper.tabIndex = 0; wrapper.setAttribute("aria-label", `Modifier ${this.config.templates[this.blocks.find(block => block.id === wrapper.dataset.studioBlock)?.template]?.name || 'cette section'}`)
      wrapper.addEventListener("keydown", event => { if (["Enter", " "].includes(event.key)) { event.preventDefault(); this.selectedId = wrapper.dataset.studioBlock; this.selectedField = null; this.inspect(); this.highlight() } })
      wrapper.addEventListener("dragstart", event => { this.drag = { id: wrapper.dataset.studioBlock }; event.dataTransfer.setData("text/plain", this.drag.id); event.dataTransfer.effectAllowed = "move" })
      const index = this.blocks.findIndex(block => block.id === wrapper.dataset.studioBlock)
      wrapper.before(this.dropZone(doc, index))
    })
    const parent = wrappers[0]?.parentNode || doc.querySelector("#main-content")
    parent?.append(this.dropZone(doc, this.blocks.length))
    this.highlight(); this.fitFrame()
    if (this.focusBlock) { doc.getElementById(`site-section-${this.focusBlock}`)?.scrollIntoView({ block: "center" }); this.focusBlock = null }
    else this.frameTarget.contentWindow.scrollTo(0, this.scrollPosition || 0)
  }
  dropZone(doc, index) {
    const zone = doc.createElement("div"); zone.className = "studio-drop-zone"; zone.textContent = "Déposer une section ici"; zone.dataset.index = index
    zone.addEventListener("dragover", event => { if (this.drag) { event.preventDefault(); zone.classList.add("is-over") } })
    zone.addEventListener("dragleave", () => zone.classList.remove("is-over"))
    zone.addEventListener("drop", event => { event.preventDefault(); if (!this.drag) return; if (this.drag.template) this.add(this.drag.template, index); else this.move(this.drag.id, index); this.drag = null; zone.classList.remove("is-over") })
    return zone
  }
  highlight() {
    this.frameTarget.contentDocument?.querySelectorAll("[data-studio-block]").forEach(node => node.classList.toggle("is-selected", node.dataset.studioBlock === this.selectedId))
  }
  device(event) { this.width = Number(event.currentTarget.dataset.width); this.fitFrame() }
  expand() { this.element.classList.toggle("visual-focus"); this.fitFrame() }
  fitFrame() {
    const available = this.frameWrapTarget.clientWidth
    const scale = Math.min(1, available / this.width)
    this.frameTarget.style.width = `${this.width}px`; this.frameTarget.style.height = `${Math.max(850, 700 / scale)}px`
    this.frameTarget.style.transform = `scale(${scale})`; this.frameWrapTarget.style.height = `${Math.max(850 * scale, 700)}px`
  }
  async save(event, review = false) {
    if (this.saving) return
    this.saving = true
    const sent = JSON.stringify(this.doc)
    this.message("Enregistrement en cours…")
    try {
      const response = await fetch(this.saveUrlValue, { method: "POST", headers: { "Content-Type": "application/json", "Accept": "application/json", "X-CSRF-Token": document.querySelector("meta[name='csrf-token']")?.content || "" }, body: JSON.stringify({ document: sent, digest: this.digest }) })
      if (!response.headers.get("content-type")?.includes("application/json")) throw new Error("Votre session doit être confirmée. Vos changements restent ici ; reconnectez-vous dans un autre onglet puis réessayez.")
      const result = await response.json()
      if (!response.ok) throw new Error(result.error || "L’enregistrement a échoué.")
      this.saved = sent; this.digest = result.digest; this.saveUrlValue = result.save
      this.previewFormTarget.action = result.preview
      this.guidedTarget.href = `${result.guided}?area=${encodeURIComponent(this.config.area || "pages")}&page=${encodeURIComponent(this.page)}`
      history.replaceState({}, "", `${result.url}?page=${encodeURIComponent(this.page)}`)
      this.message(this.dirty ? "Copie enregistrée. Des changements plus récents restent à enregistrer." : "Copie enregistrée. Elle n’est pas encore en ligne.")
      if (review && !this.dirty) window.location.assign(`${result.review}?page=${encodeURIComponent(this.page)}&editor=visual`)
    } catch (error) { this.message(error.message) }
    finally { this.saving = false }
  }
  review(event) { this.save(event, true) }
}
