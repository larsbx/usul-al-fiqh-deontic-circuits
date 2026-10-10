# Formalization pipeline: corpus → records → Lean / TLA+ checks.
PY      ?= python3
TLA_JAR ?= .cache/tla2tools.jar
TLA_URL  = https://github.com/tlaplus/tlaplus/releases/download/v1.8.0/tla2tools.jar

.PHONY: all test fetch fatawa ocr build validate generated lean tla reception oracle
all: test validate generated lean tla oracle

test:      ; cd pipeline && $(PY) -m pytest -q
fetch:     ; cd pipeline && $(PY) -m usul_corpus fetch
fatawa:    ; cd pipeline && $(PY) -m usul_corpus fatawa
ocr:       ; cd pipeline && $(PY) -m usul_corpus ocr --jobs $(shell nproc)   # needs tesseract + poppler-utils
build:     ; cd pipeline && $(PY) -m usul_corpus build
validate:  ; cd pipeline && $(PY) -m usul_corpus validate
reception: ; cd pipeline && $(PY) -m usul_corpus reception && $(PY) -m usul_corpus docs   # needs the citers cached
generated: ; $(PY) formal/fixtures/gen_grounded.py && cd pipeline && $(PY) -m usul_corpus signature && $(PY) -m usul_corpus m8-worklist --check && git diff --exit-code ../formal/fixtures ../formal/lean/UsulTest ../formal/lean/HadithTest
lean:      ; cd formal/lean && lake build
oracle:    ; formal/oracle/run_all.sh   # needs swipl: independent Prolog mirror of the Lean kernels
$(TLA_JAR):; mkdir -p $(@D) && curl -sSL -o $@ $(TLA_URL)
tla: $(TLA_JAR) ; TLA2TOOLS=$(abspath $(TLA_JAR)) formal/tla/check.sh
