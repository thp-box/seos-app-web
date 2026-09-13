import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.click = event => {
      const link = event.target.closest("a[href]")
      if (!link || event.defaultPrevented || event.metaKey || event.ctrlKey || event.shiftKey || event.altKey || event.button > 0) return
      const url = new URL(link.href)
      if (url.origin !== location.origin) return
      if (url.pathname === "/preferences-confidentialite" || (url.pathname === "/legal" && url.searchParams.get("onglet") === "preferences")) {
        event.preventDefault()
        this.open(link)
      }
    }
    document.addEventListener("click", this.click, true)
    if (new URL(location.href).searchParams.get("onglet") === "preferences") this.open()
  }
  disconnect() {
    document.removeEventListener("click", this.click, true)
    this.abort?.abort()
    this.dialog?.remove()
  }
  async open(trigger) {
    if (this.loading || this.dialog?.open) return
    this.loading = true
    this.trigger = trigger
    this.abort = new AbortController()
    try {
      const response = await fetch("/preferences-confidentialite?popup=1", { signal: this.abort.signal, headers: { Accept: "text/html" } })
      if (!response.ok) throw new Error("Préférences indisponibles")
      const doc = new DOMParser().parseFromString(await response.text(), "text/html")
      this.dialog = doc.querySelector("dialog")
      document.body.append(this.dialog)
      this.dialog.addEventListener("close", () => { this.dialog.remove(); this.trigger?.focus() })
      this.dialog.querySelector("[data-cookie-close]").addEventListener("click", () => this.dialog.close())
      this.dialog.querySelector("[data-cookie-customize]").addEventListener("click", () => this.dialog.querySelector('input[name="analytics"][type="checkbox"]').focus())
      this.dialog.addEventListener("submit", event => this.save(event))
      this.dialog.showModal()
    } catch (error) {
      if (error.name !== "AbortError") location.assign("/preferences-confidentialite")
    } finally { this.loading = false }
  }
  async save(event) {
    event.preventDefault()
    if (this.saving) return
    this.saving = true
    const dialog = this.dialog
    const buttons = dialog.querySelectorAll("button")
    buttons.forEach(button => { button.disabled = true })
    try {
      const response = await fetch(event.target.action, { method: "POST", body: new FormData(event.target), headers: { Accept: "application/json" }, signal: this.abort.signal })
      if (!response.ok) throw new Error("Enregistrement impossible")
      const consent = await response.json()
      document.querySelectorAll("[data-cookie-status]").forEach(status => {
        status.hidden = false
        const date = new Date(consent.recorded_at).toLocaleDateString("fr-FR")
        status.textContent = `Choix enregistré le ${date} · audience ${consent.analytics ? "acceptée" : "refusée"} · médias ${consent.external_media ? "acceptés" : "refusés"}`
      })
      dialog.close()
      document.dispatchEvent(new CustomEvent("cookie-preferences:saved", { detail: consent }))
    } catch (error) {
      if (error.name !== "AbortError") dialog.querySelector('[role="status"]').textContent = "Votre choix n’a pas été enregistré. Réessayez."
    } finally {
      this.saving = false
      buttons.forEach(button => { button.disabled = false })
    }
  }
}
