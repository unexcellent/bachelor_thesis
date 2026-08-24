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
  "CSP": "Cubesat Space Protocol",
  "FM": "Frequency Modulation",
  "MCU": "Microcontroller Unit",
  "SSTV": "Slow-Scan Television",
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
#include "chapters/conclusion.typ"

// --- Back matter -------------------------------------------------------------
// Following the WARR template, the suffix sections are lettered (A, B, C ...)
// and the statement of independent work is placed last.
#set heading(numbering: "A.1")
#counter(heading).update(0)

#heading[References]
#bibliography("references.bib", style: "ieee", title: none)

#heading[Appendix]

== Pin Map

#figure(
  table(
    columns: 4,
    align: left,
    [*GPIO*], [*Connected to*], [*Label*], [*Purpose*],
    [9], [SC850SL], [SCL], [I2C bus clock],
    [11], [SC850SL], [SDA], [camera register configuration],
    [12], [MI1602], [SDA], [Register control],
    [15], [MI1602], [SCL], [MIPI-CSI bus clock],
    [20], [PCM5102A], [MCLK], [Master clock],
    [21], [PCM5102A], [BCLK], [Bit clock],
    [22], [PCM5102A], [DOUT], [Serial audio sample data],
    [23], [PCM5102A], [WS], [Word select],
    [28], [MI1602], [SCLK], [SPI2 clock for frame readout],
    [29], [MI1602], [MISO], [SPI2 data input],
    [30], [MI1602], [MOSI], [SPI2 data output],
    [31], [MI1602], [SSN], [SPI2 slave select],
    [37], [THVD1424], [RX], [Receives CSP messages from the payload board],
    [38], [THVD1424], [TX], [Transmits CSP messages to the payload board],
    [39], [THVD1424], [DE], [Enables sending via RS485. Permanently held high],
    [54], [SC850SL], [XSHUTDN], [Shutdown / reset],
  ),
  caption: [ESP32-P4 pin mapping (only the relevant parts)],
) <tab-gpio>



#declaration(
  author: "Tobias Klockau",
  title: "A Modular Software Architecture for SSTV Image Transmission on an ESP32 Microcontroller",
  place: "Munich",
  date: "30 September 2026",
)
