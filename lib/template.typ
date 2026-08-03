// Thesis template for the TUM School of Engineering and Design.
// Visual style adapted from the WARR / TUM-LRT thesis template:
// blue regular-weight sans headings, a gray running header with a light rule,
// 1.5 line spacing and generous margins. The title page is unchanged.

#let tum-blue = rgb("#3070b3") // title-page accent (matches the TUM logo)

// Template colours (from the WARR/LRT LaTeX template).
// Headings use the TUM logo blue so titles match the logo on the title page.
#let custom-blue = tum-blue
#let custom-blue-warr = rgb("#006896") // original WARR heading blue (unused)
#let custom-gray = rgb("#909090")
#let custom-lightgray = rgb("#A9A9A9")

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

// Two-column definition list used for the lists of abbreviations / symbols and
// the glossary. `entries` is an array of (key, description) pairs.
#let entry-list(entries, key-width: auto, bold-key: true, row-gutter: 0.8em) = {
  if entries == none or entries.len() == 0 { return }
  grid(
    columns: (key-width, 1fr),
    column-gutter: 1.2em,
    row-gutter: row-gutter,
    ..entries
      .map(e => (
        align(right + top, if bold-key { strong(e.at(0)) } else { e.at(0) }),
        align(left + top, e.at(1)),
      ))
      .flatten()
  )
}

// Running page header: chapter number and name above a light-gray rule.
#let running-header(show-section: true) = context {
  set text(fill: custom-gray, size: 13pt, weight: "light")
  let label = if show-section {
    // The last top-level heading on or before the current page, so a chapter's
    // opening page shows its own title rather than the previous chapter's.
    let cp = here().page()
    let hs = query(heading.where(level: 1)).filter(h => (
      h.location().page() <= cp
    ))
    if hs.len() > 0 {
      let h = hs.last()
      let counts = counter(heading).at(h.location())
      if h.numbering != none and counts.len() > 0 {
        [#numbering(h.numbering, counts.first()) #h.body]
      } else {
        h.body
      }
    }
  }
  label
  v(-0.3em)
  line(length: 100%, stroke: 1pt + custom-lightgray)
}

// Page number in the bottom-right corner.
#let page-footer(roman: false) = context {
  set text(fill: custom-gray, size: 13pt, weight: "light")
  align(right, counter(page).display(if roman { "I" } else { "1" }))
}

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

  // University identification on the left (specific -> general, tight spacing),
  // logo on the right scaled to exactly the height of those three lines.
  // `logo` is ready-made image content so its path resolves relative to the
  // main document rather than this template file.
  context {
    let ident = {
      set text(size: 12pt)
      set par(leading: 0.45em)
      if chair != none {
        chair
        linebreak()
      }
      [TUM #department]
      linebreak()
      [Technical University of Munich]
    }
    let mark = if logo != none {
      logo
    } else {
      text(size: 20pt, weight: "bold", fill: tum-blue)[TUM]
    }
    let target = measure(ident).height
    let mark-height = measure(mark).height
    let sized-mark = if mark-height > 0pt {
      box(scale(mark, (target / mark-height) * 100%, reflow: true))
    } else {
      mark
    }
    grid(
      columns: (1fr, auto),
      align: (left + top, right + top),
      ident, sized-mark,
    )
  }

  set align(center)
  v(4.5cm)

  text(size: 13pt, weight: "medium")[#thesis-type]
  v(0.5cm)
  text(size: 22pt, weight: "bold")[#title]
  if subtitle != none {
    v(0.3cm)
    text(size: 15pt)[#subtitle]
  }

  v(1fr)

  // Author and administrative details
  set align(left)
  let field(label, value) = if value != none {
    grid(
      columns: (4cm, 1fr),
      column-gutter: 1cm,
      row-gutter: 0.6em,
      text(weight: "medium")[#label], [#value],
    )
  }

  field("Author", author)
  field("Matriculation number", matriculation)
  field("Degree", degree)
  field("Study program", program)
  field("Supervisor", supervisor)
  field("Advisor", advisor)
  field("Submitted on", submission-date)

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
  kurzfassung: none,
  acknowledgement: none,
  confidentiality: none,
  abbreviations: none,
  symbols: none,
  body,
) = {
  set document(title: title, author: author)

  // Base text and paragraph settings.
  // Helvetica Neue mirrors TUM's / the WARR template's corporate typeface.
  set text(font: "Helvetica Neue", size: 11pt, lang: "en")
  // ~1.5 line spacing with a classic first-line indent instead of paragraph gaps.
  set par(justify: true, leading: 1em, spacing: 1em, first-line-indent: 1.5em)

  // Page geometry (WARR template: 3 cm sides, 3.5 cm top/bottom).
  set page(
    paper: "a4",
    margin: (left: 3cm, right: 3cm, top: 3.5cm, bottom: 3.5cm),
    header-ascent: 40%,
  )

  // Headings: blue, regular-weight sans, large; deepest levels in gray.
  set heading(numbering: "1.1")
  show heading: set text(fill: custom-blue, weight: "light")
  show heading: set block(above: 1.2em, below: 0.7em)
  show heading.where(level: 1): set text(size: 25pt)
  show heading.where(level: 2): set text(size: 17pt)
  show heading.where(level: 3): set text(size: 12pt)
  show heading.where(level: 4): set text(size: 11pt)
  show heading.where(level: 5): set text(size: 11pt, fill: custom-gray)
  show heading.where(level: 6): set text(size: 11pt, fill: custom-gray)
  // Every top-level section starts on a new page.
  show heading.where(level: 1): it => {
    pagebreak(weak: true)
    it
  }

  // Figures, tables and equations
  set figure(gap: 0.8em)
  set math.equation(numbering: "(1)")

  // --- Title page (no header/footer, unnumbered) --------------------------
  set page(header: none, footer: none, numbering: none)
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

  // --- Front matter (upper-case roman numerals) ---------------------------
  pagebreak()
  set page(
    header: running-header(show-section: false),
    footer: page-footer(roman: true),
  )
  counter(page).update(1)
  set heading(numbering: none, outlined: false)

  if acknowledgement != none {
    heading(level: 1)[Acknowledgements]
    acknowledgement
  }

  if abstract != none {
    heading(level: 1)[Abstract]
    abstract
  }
  if kurzfassung != none {
    heading(level: 1)[Kurzfassung]
    kurzfassung
  }

  if confidentiality != none {
    heading(level: 1)[Confidentiality Clause]
    confidentiality
  }

  heading(level: 1)[Contents]
  outline(title: none, indent: auto)

  heading(level: 1)[List of Figures]
  outline(title: none, target: figure.where(kind: image))

  heading(level: 1)[List of Tables]
  outline(title: none, target: figure.where(kind: table))

  if abbreviations != none {
    heading(level: 1)[List of Abbreviations]
    entry-list(abbreviations)
  }
  if symbols != none {
    heading(level: 1)[List of Symbols]
    entry-list(symbols, bold-key: false)
  }

  // --- Main body (arabic numerals, running section name) ------------------
  pagebreak()
  set page(
    header: running-header(show-section: true),
    footer: page-footer(roman: false),
  )
  counter(page).update(1)
  set heading(numbering: "1.1", outlined: true)

  // The main body is responsible for its own back matter (references,
  // appendix, glossary, statement of independent work) so their order and
  // lettered numbering can be controlled from the main document.
  body
}
