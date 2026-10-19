# Formalization pipeline: corpus → records → Lean / TLA+ checks.
PY      ?= python3
TLA_JAR ?= .cache/tla2tools.jar
TLA_URL  = https://github.com/tlaplus/tlaplus/releases/download/v1.8.0/tla2tools.jar

.PHONY: lean-mathlib
.PHONY: all test fetch fatawa labels bank-review oracle prolog-oracle fatawa-takhrij fatawa-prolog judgement ocr build validate generated lean tla reception mentions
all: source-verify test validate generated lean tla

test:      ; cd pipeline && $(PY) -m pytest -q
# Both gates verify committed outputs by equality; neither updates artifacts.
INTEGRATION_TESTS = tests/test_fatawa_prolog.py tests/test_typed_routing.py tests/test_multiple_annotations.py tests/test_routing.py
.PHONY: integration integration-external
integration: ; cd pipeline && $(PY) -m pytest -q --integration-gate -m 'not external_source' $(INTEGRATION_TESTS) tests/test_integration_gate.py --junitxml=../.cache/integration-committed.xml
integration-external: ; cd pipeline && $(PY) -m pytest -q --integration-gate -m external_source $(INTEGRATION_TESTS) --junitxml=../.cache/integration-external.xml
fetch:     ; cd pipeline && $(PY) -m usul_corpus fetch
fatawa:    ; cd pipeline && $(PY) -m usul_corpus fatawa
labels:    ; cd pipeline && $(PY) -m usul_corpus labels
bank-review: ; cd pipeline && $(PY) -m usul_corpus bank-review
oracle:    ; cd pipeline && $(PY) -m usul_corpus oracle
fatawa-takhrij: ; cd pipeline && $(PY) -m usul_corpus fatawa-takhrij
fatawa-prolog: ; cd pipeline && $(PY) -m usul_corpus fatawa-prolog   # needs swipl
judgement: ; cd pipeline && $(PY) -m usul_corpus judgement
ocr:       ; cd pipeline && $(PY) -m usul_corpus ocr --jobs $(shell nproc)   # needs tesseract + poppler-utils
build:     ; cd pipeline && $(PY) -m usul_corpus build
validate:  ; cd pipeline && $(PY) -m usul_corpus validate
reception: ; cd pipeline && $(PY) -m usul_corpus reception && $(PY) -m usul_corpus docs   # needs the citers cached
mentions:  ; cd pipeline && $(PY) -m usul_corpus mentions                                # needs the citers cached
generated: ; $(PY) formal/fixtures/gen_grounded.py && $(PY) formal/fixtures/gen_taklif.py && cd pipeline && $(PY) -m usul_corpus signature && $(PY) -m usul_corpus reconcile && $(PY) -m usul_corpus judgement --check && $(PY) -m usul_corpus sheaf && $(PY) -m usul_corpus worklist --check && $(PY) -m usul_corpus routing --check && $(PY) -m usul_corpus fatawa-takhrij --check && $(PY) -m usul_corpus.signature_routing .. --classical-only --check && git diff --exit-code ../formal/lean/Usul/Readings.lean ../formal/fixtures ../formal/tla ../corpus/reconciliation ../corpus/sheaf ../formal/lean/UsulTest ../formal/lean/HadithTest
lean:      ; cd formal/lean && lake build && lake env lean scripts/ExportTypes.lean && git diff --exit-code ../../examples/v41_types.pl
# Mathlib, pinned (formal/lean-mathlib); not part of `all`, the kernel stays Mathlib-free.
lean-mathlib: ; cd formal/lean-mathlib && lake exe cache get && lake build
prolog-oracle: ; formal/oracle/run_all.sh   # needs swipl: independent Prolog mirror of the Lean kernels
$(TLA_JAR):; mkdir -p $(@D) && curl -sSL -o $@ $(TLA_URL)
tla: $(TLA_JAR) ; TLA2TOOLS=$(abspath $(TLA_JAR)) formal/tla/check.sh

# Verification never creates/re-pins a lock; unavailable required bytes fail.
.PHONY: source-verify source-verify-fetch
source-verify: ; cd pipeline && $(PY) -m usul_corpus.source_verify
source-verify-fetch: ; cd pipeline && $(PY) -m usul_corpus.source_verify --fetch-source
