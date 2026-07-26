// Thesis template for the TUM School of Engineering and Design.
// Provides the title page, page layout, heading styles and the assembly of
// front matter, main body and back matter.

#let tum-blue = rgb("#3070b3")

// ---------------------------------------------------------------------------
// Title page
// ---------------------------------------------------------------------------
#let title-page(
  title: none,
  subtitle: none,
  thesis-type: none,
  degree: none,
  program: none,
  department: none,
  chair: none,
  author: none,
  matriculation: none,
  supervisor: none,
  advisor: none,
  submission-date: none,
  logo: none,
) = {
  set page(margin: (top: 3cm, bottom: 2.5cm, left: 3cm, right: 3cm))

  // Logo top-right, per TUM corporate design (falls back to a text mark).
  // `logo` is passed as ready-made image content so its path resolves
  // relative to the main document rather than this template file.
  set align(right)
  if logo != none {
    logo
  } else {
    text(size: 20pt, weight: "bold", fill: tum-blue)[TUM]
  }

  set align(center)
  v(0.5cm)
  text(size: 12pt)[Technical University of Munich]
  linebreak()
  text(size: 12pt)[#department]
  if chair != none {
    linebreak()
    text(size: 11pt)[#chair]
  }

  v(3cm)

  text(size: 13pt, weight: "medium")[#thesis-type]
  v(0.4cm)
  line(length: 60%, stroke: 0.5pt + tum-blue)
  v(0.6cm)
  text(size: 22pt, weight: "bold")[#title]
  if subtitle != none {
    v(0.3cm)
    text(size: 15pt)[#subtitle]
  }
  v(0.6cm)
  line(length: 60%, stroke: 0.5pt + tum-blue)

  v(1fr)

  // Author and administrative details
  set align(left)
  let field(label, value) = if value != none {
    grid(
      columns: (4cm, 1fr),
      row-gutter: 0.6em,
      text(weight: "medium")[#label], [#value],
    )
  }

  pad(left: 1.5cm, right: 1.5cm)[
    #field("Author", author)
    #field("Matriculation number", matriculation)
    #field("Degree", degree)
    #field("Study program", program)
    #field("Supervisor", supervisor)
    #field("Advisor", advisor)
    #field("Submitted on", submission-date)
  ]

  v(2cm)
}

// ---------------------------------------------------------------------------
// Main template
// ---------------------------------------------------------------------------
#let thesis(
  title: "Thesis title",
  subtitle: none,
  thesis-type: "Bachelor's Thesis",
  degree: "Bachelor of Science (B.Sc.)",
  program: none,
  department: "School of Engineering and Design",
  chair: none,
  author: "Author Name",
  matriculation: none,
  supervisor: none,
  advisor: none,
  submission-date: none,
  logo: none,
  abstract: none,
  acknowledgement: none,
  body,
) = {
  set document(title: title, author: author)

  // Base text and paragraph settings
  set text(font: "New Computer Modern", size: 11pt, lang: "en")
  set par(justify: true, leading: 0.7em, spacing: 1.3em)

  // Page geometry (binding-friendly margins)
  set page(
    paper: "a4",
    margin: (top: 2.5cm, bottom: 2.5cm, inside: 3cm, outside: 2.5cm),
  )

  // Heading styling and numbering
  set heading(numbering: "1.1")
  show heading: set block(above: 1.4em, below: 0.9em)
  show heading.where(level: 1): set text(size: 17pt)
  show heading.where(level: 2): set text(size: 14pt)
  show heading.where(level: 3): set text(size: 12pt)

  // Figures, tables and equations
  set figure(gap: 0.8em)
  set math.equation(numbering: "(1)")

  // --- Title page ---------------------------------------------------------
  title-page(
    title: title,
    subtitle: subtitle,
    thesis-type: thesis-type,
    degree: degree,
    program: program,
    department: department,
    chair: chair,
    author: author,
    matriculation: matriculation,
    supervisor: supervisor,
    advisor: advisor,
    submission-date: submission-date,
    logo: logo,
  )

  // --- Front matter (roman numerals) --------------------------------------
  set page(numbering: "i")
  counter(page).update(1)

  set heading(numbering: none)

  if acknowledgement != none {
    pagebreak(weak: true)
    heading(level: 1)[Acknowledgements]
    acknowledgement
  }

  if abstract != none {
    pagebreak(weak: true)
    heading(level: 1)[Abstract]
    abstract
  }

  // Tables of contents / figures / tables
  {
    pagebreak(weak: true)
    text(size: 17pt)[Contents]
    outline(title: none, indent: auto)
  }
  {
    pagebreak(weak: true)
    text(size: 17pt)[List of Figures]
    outline(title: none, target: figure.where(kind: image))
  }
  {
    pagebreak(weak: true)
    text(size: 17pt)[List of Tables]
    outline(title: none, target: figure.where(kind: table))
  }

  // --- Main body (arabic numerals) ----------------------------------------
  pagebreak(weak: true)
  set page(numbering: "1")
  counter(page).update(1)

  set heading(numbering: "1.1")
  show heading.where(level: 1): it => {
    pagebreak(weak: true)
    it
  }

  // The main body is responsible for its own back matter (references,
  // statement of independent work, appendix) so their order can be controlled.
  body
}
