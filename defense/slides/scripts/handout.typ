// Handout: one page per slide with the slide on top and its speaker notes below.
// Inputs (made by `pnpm export`): build/slides.pdf and build/notes.json.
// Compile from the slides directory: typst compile --root . scripts/handout.typ defense.pdf

#let notes = json("../build/notes.json")

#set document(title: "SSTV Thesis Defense", author: "Tobias Klockau")
#set page(paper: "a4", margin: (x: 18mm, top: 16mm, bottom: 18mm), numbering: "1")
#set text(font: ("Helvetica Neue", "Helvetica", "Arial"), size: 11pt, lang: "en")
#set list(indent: 0.6em, spacing: 0.75em)
#set par(leading: 0.6em)

#for (i, note) in notes.enumerate() {
  if i > 0 { pagebreak() }
  text(size: 9pt, fill: luma(110))[Slide #(i + 1)]
  v(2mm)
  box(stroke: 0.5pt + luma(180), image("../build/slides.pdf", page: i + 1, width: 100%))
  v(7mm)
  if note == "" {
    text(fill: luma(140))[No notes.]
  } else {
    eval(note, mode: "markup")
  }
}
