---
layout: ontology_detail
id: zp
title: Zebrafish Phenotype Ontology
jobs:
  - id: https://travis-ci.org/obophenotype/zebrafish-phenotype-ontology
    type: travis-ci
build:
  checkout: git clone https://github.com/obophenotype/zebrafish-phenotype-ontology.git
  system: git
  path: "."
contact:
  email: ybradford@zfin.org
  label: Yvonne Bradford
description: None
domain: phenotype
homepage: https://github.com/obophenotype/zebrafish-phenotype-ontology
products:
  - id: zp.owl
  - id: zp.obo
dependencies:
 - id: go
 - id: ro
 - id: pato
 - id: bspo
 - id: zfa
 - id: bfo
 - id: uberon
tracker: https://github.com/obophenotype/zebrafish-phenotype-ontology/issues
license:
  url: http://creativecommons.org/licenses/by/3.0/
  label: CC-BY
---

Enter a detailed description of your ontology here
