# Formalization pipeline: corpus → records → Lean / TLA+ checks.
PY      ?= python3
TLA_JAR ?= .cache/tla2tools.jar
TLA_URL  = https://github.com/tlaplus/tlaplus/releases/download/v1.8.0/tla2tools.jar

.PHONY: all test fetch ocr build validate generated lean tla
all: test validate generated lean tla

test:      ; cd pipeline && $(PY) -m pytest -q
fetch:     ; cd pipeline && $(PY) -m usul_corpus fetch
ocr:       ; cd pipeline && $(PY) -m usul_corpus ocr --jobs $(shell nproc)   # needs tesseract + poppler-utils
build:     ; cd pipeline && $(PY) -m usul_corpus build
validate:  ; cd pipeline && $(PY) -m usul_corpus validate
generated: ; $(PY) formal/fixtures/gen_grounded.py && cd pipeline && $(PY) -m usul_corpus signature && git diff --exit-code ../formal/fixtures ../formal/lean/UsulTest
lean:      ; cd formal/lean && lake build
$(TLA_JAR):; mkdir -p $(@D) && curl -sSL -o $@ $(TLA_URL)
tla: $(TLA_JAR) ; TLA2TOOLS=$(abspath $(TLA_JAR)) formal/tla/check.sh
