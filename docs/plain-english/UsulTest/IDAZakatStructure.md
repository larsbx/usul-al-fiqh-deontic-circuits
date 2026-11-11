# UsulTest.IDAZakatStructure in Plain English

Source: [`formal/lean/UsulTest/IDAZakatStructure.lean`](../../../formal/lean/UsulTest/IDAZakatStructure.lean)

A local fixture registers the proposed three-role zakat transfer signature.
The named roles keep payer and recipient distinct even though both use the
person sort. Two staged substitutions agree with their composition, and
swapping the people leaves the specified property unchanged. Resolution
rejects a changed version or digest, a missing property, and a person in
the property role. These checks concern the structure of an act description.
