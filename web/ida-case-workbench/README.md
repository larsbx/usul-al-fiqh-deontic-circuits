# IDA case-review workbench

This read-only interface presents a generated dossier for the bounded synthetic
ACT-08 repayment scenario. It keeps source assertions, contextual premise
admission, report signs, conditional derivations, finite-history assessments, and
human review separate.

The browser does not run Lean, authenticate source signatures, admit arbitrary
cases, or issue decisions. The generation command performs the replay and binds
the resulting dossier to its implementation revision and admission receipt. The
page explicitly labels this as **replayed at generation**, using **published test
keys and synthetic evidence**. Trust and revocation are not checked live by the
browser.

## Open the generated workbench

From a clean repository checkout with the documented IDA prerequisites:

```sh
make ida-case-workbench
python3 -m http.server 8765 --bind 127.0.0.1 --directory .cache/ida-case-workbench
```

Open [http://127.0.0.1:8765/](http://127.0.0.1:8765/) in a browser. If a custom
output directory was supplied to the generator, serve that directory instead.
Opening `index.html` with `file://` is not
supported because the page reads `./dossier.json` using a same-origin request.
The generated directory must contain `index.html`, `app.js`, `style.css`,
`dossier.json`, and `verification.json` together. The browser checks the dossier's
raw SHA-256, implementation revision, receipt digest, and 384-cell count against
that generation marker before displaying it. A missing or mismatched marker
blocks the view. This unsigned consistency marker is not external authenticity
or live verification. No external fonts, scripts, CDN, or remote API are used.

## Review flow

1. Inspect the synthetic-fixture notice, exact implementation revision, and
   receipt digest. The baseline dossier remains fixed throughout the session.
2. Select a statement to inspect its precise scope, source occurrences, proof
   declarations, dependencies, and limitations. A source signature authenticates
   bytes and issuer; it does not establish the real-world truth of an assertion.
3. Inspect the complete inquiry, named participant roles, temporal view,
   evidence perspective, and definition/interpretation/admission pins.
4. Use **Scenario explorer** to compare only the exporter-supplied finite cells.
   The selected report mask, history population, and authority mode stay labeled
   hypothetical. No selected cell inherits the baseline admission signature.
   The page looks up the exact cell; it never calculates a substitute outcome.
5. Review the unresolved questions. The adjudicator/mufti selector changes the
   review perspective and notes heading only; it changes no context, rule,
   profile, receipt, or admission status.
6. Copy draft notes if useful. The copied JSON includes the implementation
   revision, receipt digest, synthetic mode, review perspective, displayed view,
   baseline selection, and exact selected hypothetical coordinates. Notes are
   unsigned and unsubmitted. The page neither stores nor sends them.

The interface has no upload route, authority-management action, decision-signing
action, registry-write path, or generic free-form fact admission.

## Display contract

The generator supplies `ida-case-dossier-v1`, with
`caseMode: "synthetic-scenario"`, `audience: "review"`, and explicit
`fixture.synthetic` / `fixture.testKeys` flags. The principal sections are
`verification`, `inquiry`, `claims`, `conclusion`, `sources`, `proofs`,
`questions`, and `scenarios`. An optional `protocol` section lists supported
agent operations as explanatory text.

Scenario dimensions are `mask`, `population`, and `authorityMode`; option values
are numbers. The baseline is `{ "mask": 9, "population": 2,
"authorityMode": 0 }`. Each cell carries those exact selectors and the
exported guard, report status, finite assessment, and staged result.

All dossier text is rendered through DOM text nodes. Proof links are restricted
to HTTPS paths in this GitHub repository. Display-contract validation does not
constitute independent verification; the generation receipt and replay remain
the evidence for the underlying computation.
