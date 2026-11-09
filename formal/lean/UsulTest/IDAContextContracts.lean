import UsulTest.IDAContext

/-! Fixed statement contracts. These fail to compile if a required proof is
replaced with a weaker statement under the same name. -/

namespace UsulTest.IDAContextContracts

open Usul.IDA Usul.IDA.Context

example (r : ActRegistry.Registry) (c : Catalog) (s t : Snapshot) :
    resolve r c s = .ok t ↔
    (c.Unambiguous ∧ c.Consistent) ∧ matching c s.coordinates = [s] ∧
      s.WellFormed r ∧ t = s :=
  resolve_iff r c s t

example {r : ActRegistry.Registry} {c : Catalog} {s t u : Snapshot}
    (h : resolve r c s = .ok t) (hm : u ∈ c) (hc : u.coordinates = s.coordinates) :
    u = t :=
  resolve_unique h hm hc

example {r : ActRegistry.Registry} {c : Catalog} {s t : Snapshot}
    (h : resolve r c s = .ok t) :
    t.target = s.target ∧ t.inquiry.accountable = s.inquiry.accountable ∧
      t.inquiry.performer = s.inquiry.performer ∧ t.time = s.time :=
  resolve_rigid h

example {v : Vocabulary} {q : ActRegistry.Qualification} {d : PredicateDefinition}
    (ht : Typed v q) (hm : d ∈ v.definitions) (hk : d.key = ⟨q.predicate, q.version⟩) :
    q.arguments.map EntityRef.kind = d.arguments :=
  typed_arguments ht hm hk

example {r : ActRegistry.Registry} {c : Catalog} {s : Snapshot}
    {p : Derivation.Premise} {receipt : BindingReceipt} :
    bind r c s p = .ok receipt ↔
    resolve r c s = .ok s ∧ s.MatchesPremise p ∧ receipt = ⟨s, p⟩ :=
  bind_iff

example {r : ActRegistry.Registry} {c : Catalog} {s t : Snapshot}
    (hs : resolve r c s = .ok s) (ht : resolve r c t = .ok t)
    (hi : s.coordinates.2 = t.coordinates.2) : s.effectiveIdentity = t.effectiveIdentity :=
  time_identity_unique hs ht hi

example {r : ActRegistry.Registry} {c : Catalog} {s t : Snapshot}
    (h : resolve r c t = .ok t) (hc : s.coordinates = t.coordinates)
    (ht : s.target = t.target) (hq : s.envelope.qualifications ≠ t.envelope.qualifications) :
    ¬ ∃ f : TargetExpr → Except Failure Snapshot, ∀ x, resolve r c x = f x.target :=
  no_target_factorization h hc ht hq

example (s : Snapshot) : decode (encode s) = some s :=
  decode_encode s

example {w : SnapshotWire} {s : Snapshot} (h : decode w = some s) : encode s = w :=
  encode_decode h

end UsulTest.IDAContextContracts
