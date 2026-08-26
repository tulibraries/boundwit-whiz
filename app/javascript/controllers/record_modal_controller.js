import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["backdrop", "content"]

  async open(event) {
    event.preventDefault()

    const url = event.currentTarget.href

    const response = await fetch(url, {
      headers: {
        Accept: "text/html"
      }
    })

    this.contentTarget.innerHTML = await response.text()
    this.backdropTarget.classList.remove("d-none")
    document.body.classList.add("modal-open")
  }

  close() {
    this.backdropTarget.classList.add("d-none")
    this.contentTarget.innerHTML = ""
    document.body.classList.remove("modal-open")
  }

  closeOnBackdrop(event) {
    if (event.target === this.backdropTarget) {
      this.close()
    }
  }
}
