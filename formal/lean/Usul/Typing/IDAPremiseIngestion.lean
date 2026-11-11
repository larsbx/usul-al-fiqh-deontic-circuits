import Usul.Typing.IDAAdmission

/-! The host authenticates exact certificate attestations and source passages.
The existing ACT-05 checker still decides applicability and application policy. -/
namespace Usul.IDA.PremiseIngestion

open Admission

inductive Failure where
  | duplicateToken | certificateSet | sourceEvidence
  deriving DecidableEq, Repr

def CertificateSource (c : Certificate v) : Judgment.SourceRef :=
  c.premise.request.record.provenance.source

def Check (source destination : Side v) (certificates : List (Certificate v))
    (sources : List Judgment.SourceRef) : Prop :=
  (certificates.map Certificate.token).Nodup ∧
    certificates = source.certificates ++ destination.certificates ∧
    ∀ c ∈ certificates, CertificateSource c ∈ sources

instance (source destination : Side v) (certificates : List (Certificate v))
    (sources : List Judgment.SourceRef) : Decidable (Check source destination certificates sources) := by
  unfold Check
  infer_instance

def validate (source destination : Side v) (certificates : List (Certificate v))
    (sources : List Judgment.SourceRef) : Except Failure (PLift (Check source destination certificates sources)) :=
  if hd : (certificates.map Certificate.token).Nodup then
    if hc : certificates = source.certificates ++ destination.certificates then
      if hs : ∀ c ∈ certificates, CertificateSource c ∈ sources then
        .ok ⟨hd, hc, hs⟩
      else .error .sourceEvidence
    else .error .certificateSet
  else .error .duplicateToken

def scopedAuthority (current : Authority v) (certificates : List (Certificate v))
    (sources : List Judgment.SourceRef) : Authority v :=
  { current with authenticated := certificates
                 environment := { current.environment with authenticatedSources := sources } }

theorem destination_source_bound {source destination : Side v} {certificates : List (Certificate v)}
    {sources : List Judgment.SourceRef} (checked : Check source destination certificates sources)
    {c : Certificate v} (member : c ∈ destination.certificates) :
    c ∈ certificates ∧ CertificateSource c ∈ sources := by
  have hc : c ∈ certificates := checked.2.1.symm ▸ List.mem_append_right _ member
  exact ⟨hc, checked.2.2 c hc⟩

theorem source_bound {source destination : Side v} {certificates : List (Certificate v)}
    {sources : List Judgment.SourceRef} (checked : Check source destination certificates sources)
    {c : Certificate v} (member : c ∈ source.certificates) :
    c ∈ certificates ∧ CertificateSource c ∈ sources := by
  have hc : c ∈ certificates := checked.2.1.symm ▸ List.mem_append_left _ member
  exact ⟨hc, checked.2.2 c hc⟩

theorem grants_preserved (current : Authority v) (certificates : List (Certificate v))
    (sources : List Judgment.SourceRef) :
    (scopedAuthority current certificates sources).grants = current.grants := rfl

end Usul.IDA.PremiseIngestion
