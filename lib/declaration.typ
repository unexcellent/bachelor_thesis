// Statement of Independent Work (Declaration of Authorship).
// Required by the TUM School of Engineering and Design.

#let declaration(
  author: none,
  title: none,
  place: "Munich",
  date: none,
) = {
  pagebreak(weak: true)

  text(size: 17pt)[Statement of Independent Work]
  v(1cm)

  par(justify: true)[
    I hereby declare that this thesis is my own work and that no other sources
    have been used except those clearly indicated and referenced. All passages
    taken literally or in spirit from published or unpublished sources are marked
    as such. The thesis has not been submitted, either in whole or in part, to
    any other examination authority and has not yet been published.
  ]

  v(0.5cm)

  if title != none {
    par(justify: true)[
      *Title of the thesis:* #title
    ]
  }

  v(2.5cm)

  grid(
    columns: (1fr, 1fr),
    align: left,
    [
      #line(length: 5cm, stroke: 0.5pt)
      #place, #if date != none { date }
    ],
    [
      #line(length: 5cm, stroke: 0.5pt)
      #author
    ],
  )
}
