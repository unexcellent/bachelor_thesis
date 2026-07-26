// =============================================================================
// Bachelor's Thesis - TUM School of Engineering and Design
// Style adapted from the WARR / TUM-LRT thesis template.
//
// Compile with:  typst compile thesis.typ
// Live preview:  typst watch thesis.typ
// =============================================================================

#import "lib/template.typ": thesis, entry-list
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
  kurzfassung: include "kurzfassung.typ",
  acknowledgement: include "acknowledgement.typ",
  // For a confidential thesis, set this to the clause content (see the WARR
  // template). Left off for a public thesis.
  confidentiality: none,
  abbreviations: (
    ("COTS", "Commercial off-the-shelf"),
    ("CubeSat", "Cube satellite"),
    ("GEO", "Geostationary orbit"),
    ("ISS", "International Space Station"),
    ("LEO", "Low earth orbit"),
    ("MEO", "Medium earth orbit"),
  ),
  symbols: (
    ($A$, "Cross-sectional area"),
    ($C$, "Drag coefficient"),
    ($F$, "Drag force"),
    ($v$, "Velocity"),
    ($rho$, "Atmospheric density"),
  ),
)

// --- Main body ---------------------------------------------------------------
#include "chapters/01-introduction.typ"
#include "chapters/02-literature-review.typ"
#include "chapters/03-data-collection.typ"
#include "chapters/04-analysis.typ"
#include "chapters/05-conclusions.typ"

// --- Back matter -------------------------------------------------------------
// Following the WARR template, the suffix sections are lettered (A, B, C ...)
// and the statement of independent work is placed last.
#set heading(numbering: "A.1")
#counter(heading).update(0)

#heading[References]
#bibliography("references.bib", style: "ieee", title: none)

#heading[Appendix]
// Optional. Add extensive supplementary material (large tables, derivations,
// additional figures) here.

#heading[Glossary]
#entry-list(
  (
    ("CubeSat", "A class of nano-satellite built from standardised 10 cm cubic units (1U), typically developed by universities and small companies using low-cost components."),
    ("Outgassing", "The release of condensable molecules from a material exposed to vacuum, which can degrade components and contaminate optical surfaces."),
    ("Thermosphere", "The atmospheric layer between roughly 90 km and 1,000 km altitude in which residual atmospheric drag acts on satellites in low earth orbit."),
  ),
  key-width: 3cm,
  row-gutter: 1em,
)

// Statement of Independent Work (unnumbered, kept out of the contents).
#declaration(
  author: "Tobias Klockau",
  title: "Considerations for Using COTS Parts in CubeSats",
  place: "Munich",
  date: "16 February 2024",
)
