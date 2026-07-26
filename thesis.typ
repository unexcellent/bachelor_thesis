// =============================================================================
// Bachelor's Thesis - TUM School of Engineering and Design
//
// Compile with:  typst compile thesis.typ
// Live preview:  typst watch thesis.typ
// =============================================================================

#import "lib/template.typ": thesis
#import "lib/declaration.typ": declaration

#show: thesis.with(
  title: "Considerations for Using COTS Parts in CubeSats",
  subtitle: "An Overview of Satellite Systems and their Applications",
  thesis-type: "Bachelor's Thesis",
  degree: "Bachelor of Science (B.Sc.)",
  program: "Aerospace",
  department: "School of Engineering and Design",
  chair: none, // e.g. "Chair of Astronautics"
  author: "Tobias Klockau",
  matriculation: "03781731",
  supervisor: none, // e.g. "Prof. Dr. ..."
  advisor: "Golkar",
  submission-date: "16 February 2024",
  logo: image("figures/tum-logo.svg", width: 3.5cm),
  abstract: include "abstract.typ",
  acknowledgement: include "acknowledgement.typ",
)

// --- Main body ---------------------------------------------------------------
#include "chapters/01-introduction.typ"
#include "chapters/02-literature-review.typ"
#include "chapters/03-data-collection.typ"
#include "chapters/04-analysis.typ"
#include "chapters/05-conclusions.typ"

// --- Back matter -------------------------------------------------------------
// TUM order: References -> Statement of Independent Work -> Appendix.

#bibliography("references.bib", style: "ieee", title: "References")

#declaration(
  author: "Tobias Klockau",
  title: "Considerations for Using COTS Parts in CubeSats",
  place: "Munich",
  date: "16 February 2024",
)

// --- Appendix ----------------------------------------------------------------
#pagebreak(weak: true)
#heading(numbering: none)[Appendix]
// Optional. Add extensive supplementary material (large tables, derivations,
// additional figures) here.
