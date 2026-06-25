#let codekey(..args) = none
#import "@preview/codly:1.3.0": *
#import "@preview/codly-languages:0.1.1": *
#import "@preview/cetz:0.4.2"
#import "@preview/frame-it:2.0.0": *
#show: codly-init.with()
#codly(languages: codly-languages)

#set page(paper: "a4")

// #let author = "Paul Elvis Otto"
#let my_title = "ZWEITSTIMME-ORG API USER GUIDE"
#let today = datetime.today().display()
#set document(
  title: my_title,
  // author: author,
  date: datetime.today(),
)

#let (interpretation, feature, caution) = frames(
  feature: ("Feature",),
  // For each frame kind, you have to provide its supplement title to be displayed
  caution: ("caution", orange),
  // You can provide a color or leave it out and it will be generated
  interpretation: ("interpretation", green),
)
#set heading(numbering: "1.")

#show: frame-style(styles.boxy)

#set page(numbering: "I")
#set math.mat(delim: "[")
#title()
#align(left)[
  // #author \
  #today
]
#outline()
#pagebreak()
#set page(numbering: "1")
#counter(page).update(1)

#set page(footer: context [
  *Paul Elvis Otto*
  #h(1fr)
  #counter(page).display(
    "1/1",
    both: true,
  )
])
#let current-chapter-title() = context {
  let headings = query(heading.where(level: 1).before(here()))
  if headings == () { panic("Aucun titre trouvé") }
  headings.last().body
}

#set page(header: context [
  #text(emph(current-chapter-title()))
  #h(1fr)
  // Top right header
  #line(length: 100%, stroke: 0.5pt)
])

= Introduction

This is the userguide for the zweitstimme-org polling-api


= Data Sources

= Data Validation

= Using the API

== General Information

== Endpoints

// This includes all the endpoints from the current openapi.json file builds automatically
#include "./endpoints.typ"
