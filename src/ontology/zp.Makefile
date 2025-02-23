AUTOPATTERNACCESSION = 99999
OBOPURL=http://purl.obolibrary.org/obo/
PURL=$(OBOPURL)ZP_
ZPCURIEPREFIX=ZP:
ROBOT=robot -vv

PDIR=../patterns/dosdp-patterns
TEMPLATEDIR=../templates
AUTOPATTERNDIR=../patterns/data/anatomy
MANUALPATTERNDIR=../patterns/data/manual
LABELPATTERNDIR=../patterns/data/labels
ZFINPATTERNDIR=../patterns/data/zfin
TODOPATTERNDIR=../patterns/data/todo
TMPDIR=../curation/tmp

ID_MAP_ZFIN=../curation/id_map_zfin.tsv
ID_MAP=../curation/id_map.tsv

#$(PDIR)/data/zfin/%.ofn: $(PDIR)/data/zfin/%.tsv $(PDIR)/dosdp-patterns/%.yaml $(SRC) all_imports .FORCE
#	@$(if $(findstring _label.ofn,$@),dosdp-tools generate --infile=$< --template=$(word 2, $^) --ontology=$(word 3, $^) --obo-prefixes=true --outfile=$@,dosdp-tools generate --infile=$< --template=$(word 2, $^) --ontology=$(word 3, $^) --obo-prefixes=true  --restrict-axioms-to=logical --outfile=$@)

#### 
# Defiinitions.owl overwrite (occurs in hack!)
####


mirror/zfa.owl: mirror/zfa.trigger
	@if [ $(MIR) = true ] && [ $(IMP) = true ]; then $(ROBOT) merge -I $(URIBASE)/zfa.owl remove --term BFO:0000050 convert -o $@.tmp.owl && mv $@.tmp.owl $@; fi


$(PDIR)/definitions.owl: prepare_patterns $(individual_patterns_default)   $(individual_patterns_manual) $(individual_patterns_anatomy) $(individual_patterns_zfin) $(individual_patterns_process)
	$(ROBOT) merge $(addprefix -i , $(individual_patterns_default))   $(addprefix -i , $(individual_patterns_manual)) $(addprefix -i , $(individual_patterns_anatomy)) $(addprefix -i , $(individual_patterns_zfin)) $(addprefix -i , $(individual_patterns_process)) annotate --ontology-iri $(ONTBASE)/patterns/definitions.owl  --version-iri $(ONTBASE)/releases/$(TODAY)/patterns/definitions.owl -o definitions.ofn &&\
	mv definitions.ofn $@ &&\
	echo 'OCCURS IN HACK SKIPPED!'
	#java -jar ../scripts/zp_occurs_in_hack.jar $@ ../curation/unsat.txt $@

#############################################
### Computing all reserved iris in ZP ######
#############################################
RESERVED_IRI=$(TMPDIR)/reserved_iris.txt
ZP_SRC_SEED=$(TMPDIR)/editseed.txt
pattern_term_lists_auto := $(patsubst %.tsv, $(AUTOPATTERNDIR)/%.txt, $(notdir $(wildcard $(AUTOPATTERNDIR)/*.tsv)))
pattern_term_lists_manual := $(patsubst %.tsv, $(MANUALPATTERNDIR)/%.txt, $(notdir $(wildcard $(MANUALPATTERNDIR)/*.tsv)))
pattern_term_lists_zfin := $(patsubst %.tsv, $(ZFINPATTERNDIR)/%.txt, $(notdir $(wildcard $(ZFINPATTERNDIR)/*.tsv)))


$(MANUALPATTERNDIR)/%.txt: $(MANUALPATTERNDIR)/%.tsv
	grep -Eo '(ZP)[:][^[:space:]"]+' $< | sort | uniq > $@

$(AUTOPATTERNDIR)/%.txt: $(AUTOPATTERNDIR)/%.tsv
	grep -Eo '(ZP)[^[:space:]"]+' $< | sort | uniq > $@
	
$(ZFINPATTERNDIR)/%.txt: $(ZFINPATTERNDIR)/%.tsv
	grep -Eo '(ZP)[^[:space:]"]+' $< | sort | uniq > $@

$(ZP_SRC_SEED): $(SRC)
	robot query -f csv -i $< --use-graphs true --query ../sparql/zp_terms.sparql $@


$(TMPDIR)/id_map_terms.txt.tmp:
	grep -Eo '(ZP)[^[:space:]"]+' ../curation/id_map_zfin.tsv | sort | uniq > $@

$(TMPDIR)/id_map_terms.txt.zp.tmp:
	grep -Eo '(ZP)[:][^[:space:]"]+' ../curation/id_map.tsv | sort | uniq > $@	
	
$(TMPDIR)/id_map_terms.txt: $(TMPDIR)/id_map_terms.txt.tmp $(TMPDIR)/id_map_terms.txt.zp.tmp
	cat $^ | sort | uniq > $@


$(TMPDIR)/idmap_removed_ambiguous_terms.txt.tmp: ../curation/id_map_zfin.tsv
	grep -Eo '($(PURL))[^[:space:]"]+' $< | sort | uniq > $@

$(TMPDIR)/idmap_removed_ambiguous_terms.txt.zp.tmp: ../curation/id_map_zfin.tsv
	grep -Eo '(ZP)[:][^[:space:]"]+' $< | sort | uniq > $@	
	
$(TMPDIR)/idmap_removed_ambiguous_terms.txt: $(TMPDIR)/idmap_removed_ambiguous_terms.txt.tmp $(TMPDIR)/idmap_removed_ambiguous_terms.txt.zp.tmp
	cat $^ | sort | uniq > $@


$(TMPDIR)/idmap_removed_incomplete_terms.txt.tmp: ../curation/id_map_zfin.tsv
	grep -Eo '($(PURL))[^[:space:]"]+' $< | sort | uniq > $@

$(TMPDIR)/idmap_removed_incomplete_terms.txt.zp.tmp: ../curation/id_map_zfin.tsv
	grep -Eo '(ZP)[:][^[:space:]"]+' $< | sort | uniq > $@	
	
$(TMPDIR)/idmap_removed_incomplete_terms.txt: $(TMPDIR)/idmap_removed_incomplete_terms.txt.tmp $(TMPDIR)/idmap_removed_incomplete_terms.txt.zp.tmp
	cat $^ | sort | uniq > $@


$(TMPDIR)/obsoleted.txt.tmp: ../templates/obsolete.tsv
	grep -Eo '($(PURL))[^[:space:]"]+' $< | sort | uniq > $@

$(TMPDIR)/obsoleted.txt.zp.tmp: ../templates/obsolete.tsv
	grep -Eo '(ZP)[:][^[:space:]"]+' $< | sort | uniq > $@	
	
$(TMPDIR)/obsoleted.txt: $(TMPDIR)/obsoleted.txt.tmp $(TMPDIR)/obsoleted.txt.zp.tmp
	cat $^ | sort | uniq > $@


$(RESERVED_IRI)_tmp.txt: $(pattern_term_lists_auto) $(pattern_term_lists_manual) $(pattern_term_lists_zfin) $(ZP_SRC_SEED) $(TMPDIR)/id_map_terms.txt $(TMPDIR)/idmap_removed_ambiguous_terms.txt $(TMPDIR)/idmap_removed_incomplete_terms.txt $(TMPDIR)/obsoleted.txt
	cat $^ | sort | uniq > $@

$(RESERVED_IRI)_iri.txt: $(RESERVED_IRI)_tmp.txt
	cp $< $@
	sed -i 's!ZP[:]!$(PURL)!g' $@
	
$(RESERVED_IRI)_curie.txt: $(RESERVED_IRI)_tmp.txt
	cp $< $@
	sed -i 's!http[:][/][/]purl[.]obolibrary[.]org[/]obo[/]ZP[_]!ZP:!g' $@

$(RESERVED_IRI): $(RESERVED_IRI)_iri.txt $(RESERVED_IRI)_curie.txt
	cat $^ | sort | uniq > $@

reserved_iris: $(RESERVED_IRI)

#####################################################
### Filling in missing IRIs in manual patterns ######
#####################################################

MANUALPATTERNIDS=$(patsubst %.tsv, $(MANUALPATTERNDIR)/%_ids, $(notdir $(wildcard ../patterns/data/manual/*.tsv)))

$(MANUALPATTERNDIR)/%_ids: $(RESERVED_IRI) $(ID_MAP)
	python3 ../scripts/assign_unique_ids.py $(MANUALPATTERNDIR)/$*.tsv $(ID_MAP) $(RESERVED_IRI) $(AUTOPATTERNACCESSION) $(ZPCURIEPREFIX) $(PDIR)

missing_iris: $(MANUALPATTERNIDS)

###################################
### Running anatomy pipeline ######
###################################

ZFA_IRI = $(OBOPURL)zfa.owl
ZFA = $(TMPDIR)/zfa.owl
PATTERN_CONFIG=../patterns/pattern-config.yaml
PIPELINE_DATA_PATH=../patterns/data/anatomy/
SPARQLDIR=../sparql

download_patterns: .FORCE
	cat $(PDIR)/external.txt | sed 's!.*/!!' | sed 's! !!g' |  xargs -I{} rm -f $(PDIR)/{}
	cat $(PDIR)/external.txt | sed 's! !!g' | xargs -I{} wget -q {} -P $(PDIR)/

$(ZFA):
	$(ROBOT) reason --reasoner ELK -I $(ZFA_IRI) --output $@

anatomy_pipeline: download_patterns $(ZFA) $(ID_MAP) $(RESERVED_IRI) 
	echo "Using $(ZFA_IRI) for running anatomy pipeline, make sure this is correct!"
	python3 ../scripts/zp_anatomy_pipeline.py  $(ZFA) $(ID_MAP) $(RESERVED_IRI) $(PDIR) $(SPARQLDIR) $(PIPELINE_DATA_PATH) $(PATTERN_CONFIG) || exit 1

#########################################
### Generating all ROBOT templates ######
#########################################

TEMPLATESDIR=../templates

TEMPLATES=$(patsubst %.tsv, $(TEMPLATESDIR)/%.owl, $(notdir $(wildcard $(TEMPLATESDIR)/*.tsv)))

$(TEMPLATESDIR)/%.owl: $(TEMPLATESDIR)/%.tsv $(SRC)
	$(ROBOT) merge -i $(SRC) template --template $< --output $@ && \
	$(ROBOT) annotate --input $@ --ontology-iri $(ONTBASE)/components/$*.owl -o $@

templates: $(TEMPLATES)
	echo $(TEMPLATES)
	
	
#############################################
### WHOLE PIPELINE (main job)      ##########
#############################################

.PHONY: .FORCE

$(ID_MAP): update_id_map

update_id_map: $(ID_MAP_ZFIN)
	python3 ../scripts/create_id_map.py ../patterns $(ID_MAP)

clean:
	rm -rf $(TMPDIR)/*

pattern_labels:
	rm -rf $(LABELPATTERNDIR)/*
	python3 ../scripts/zp_create_label_patterns.py ../patterns

zp_labels.csv:
	robot query -f csv -i ../patterns/definitions.owl --query ../sparql/zp_label_terms.sparql tmp_$@
	cat tmp_$@ | sort | uniq > $@ && rm tmp_$@
	
zfin_pipeline: clean prepare_patterns $(RESERVED_IRI) zp_labels.csv
	sh ../scripts/zfin_pipeline.sh

preprocess:
	$(ROBOT) merge -i zp-edit.owl \
	reason --reasoner ELK  --exclude-tautologies structural \
	remove -T blacklist_eqs.txt --axioms equivalent --preserve-structure false -o zp-edit-release.ofn
	mv zp-edit-release.ofn zp-edit-release.owl

# BASE product needs to be overwritten because SRC is, during run of prepare release, a merged artefact (see zp_release.sh)
$(ONT)-base.owl: $(SRC) $(OTHER_SRC)
	$(ROBOT) remove --input zp-edit.owl --select imports --trim false \
		merge $(patsubst %, -i %, $(OTHER_SRC)) \
		annotate --ontology-iri $(ONTBASE)/$@ --version-iri $(ONTBASE)/releases/$(TODAY)/$@ --output $@.tmp.owl && mv $@.tmp.owl $@

#zp_pipeline: anatomy_pipeline missing_iris pattern_labels templates prepare_release
zp_pipeline: zfin_pipeline anatomy_pipeline missing_iris pattern_labels templates patterns preprocess

z:
	sh ../scripts/zfin_pipeline_test.sh

#############################################
### TEST PIPELINE                 ##########
#############################################

$(TMPDIR)/new_labels.txt:
	robot query -f csv -i ../../zp.owl --query ../sparql/zp_label_terms.sparql $@

$(TMPDIR)/old_labels.txt:
	robot query -f csv -I $(OBOPURL)zp.owl --query ../sparql/zp_label_terms.sparql $@

mass_obsolete: $(TMPDIR)/old_labels.txt $(TMPDIR)/new_labels.txt
	python3 ../scripts/mass_obsolete.py $(TMPDIR)/old_labels.txt $(TMPDIR)/new_labels.txt ../templates/obsolete.tsv

qc:
	$(ROBOT) report -i ../../zp.owl --fail-on None --print 5 -o zp_owl_report.owl
	$(ROBOT) merge --input ../../zp.owl reason --reasoner ELK  --equivalent-classes-allowed asserted-only --exclude-tautologies structural --output test.owl && rm test.owl && echo "Success"
