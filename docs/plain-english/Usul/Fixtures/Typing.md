# Usul.Fixtures.Typing in Plain English

Source: [`formal/lean/Usul/Fixtures/Typing.lean`](../../../../formal/lean/Usul/Fixtures/Typing.lean)

This module implements the finite typed-routing fixture model. It checks declared fields, inherited fields, encoder requirements, missing facts, shared fields, and relation-driven facts. Explicitly stated facts have priority over derived facts. Relation direction and premises remain part of the model.

Coverage reports how many required fields are known. It does not manufacture a missing fact or a ruling. The model preserves the separation between safekeeping negligence and inquiry negligence and checks that a shared name alone does not identify unrelated fields.
