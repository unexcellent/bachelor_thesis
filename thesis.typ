// =============================================================================
// Bachelor's Thesis - TUM School of Engineering and Design
// Style adapted from the WARR / TUM-LRT thesis template.
//
// Compile with:  typst compile thesis.typ
// Live preview:  typst watch thesis.typ
// =============================================================================

#import "lib/template.typ": entry-list, thesis
#import "lib/declaration.typ": declaration
#import "@preview/acrostiche:0.7.0": init-acronyms

// Abbreviations: acronym -> long form. Referenced in the text via
// #acr("...") (expands the long form on first use), and rendered as the
// List of Abbreviations in the front matter. Keep alphabetically sorted.
#let abbreviations = (
  "ARISS": "Amateur Radio on the International Space Station",
  "CSP": "Cubesat Space Protocol",
  "FM": "Frequency Modulation",
  "GMSK": "Gaussian Minimum Shift Keying",
  "MCU": "Microcontroller Unit",
  "MOVE": "Munich Orbital Verification Experiment",
  "SSTV": "Slow-Scan Television",
  "UHF": "Ultra High Frequency",
  "VHF": "Very High Frequency",
  "VIS": "Visual Interval Signaling",
)
#init-acronyms(abbreviations)

#show: thesis.with(
  title: "A Modular Software Architecture for SSTV Image Transmission on an ESP32 Microcontroller",
  thesis-type: "Bachelor's Thesis",
  degree: "Bachelor of Science",
  program: "Aerospace",
  department: "School of Engineering and Design",
  chair: "Chair of Spacecraft Systems",
  author: "Tobias Klockau",
  matriculation: "03781731",
  supervisor: "Alessandro Golkar",
  advisor: "Jaspar Sindermann",
  submission-date: "October 1st 2026",
  logo: image("figures/tum-logo.svg", width: 4.5cm),
  abstract: include "abstract.typ",
  kurzfassung: include "kurzfassung.typ",
  confidentiality: none,
  abbreviations: abbreviations.pairs(),
)

// --- Main body ---------------------------------------------------------------
#include "chapters/introduction.typ"
#include "chapters/theory.typ"
#include "chapters/constraints.typ"
#include "chapters/implementation.typ"
#include "chapters/verification.typ"
#include "chapters/discussion.typ"

// --- Back matter -------------------------------------------------------------
// Following the WARR template, the suffix sections are lettered (A, B, C ...)
// and the statement of independent work is placed last.
#set heading(numbering: "A.1")
#counter(heading).update(0)

#heading[References]
#bibliography("references.bib", style: "ieee", title: none)

#include "chapters/appendix.typ"

#declaration(
  author: "Tobias Klockau",
  title: "A Modular Software Architecture for SSTV Image Transmission on an ESP32 Microcontroller",
  place: "Munich",
  date: "30 September 2026",
)
