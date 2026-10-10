#!/usr/bin/env bash
# Disables one kernel guard or emitter at a time in a scratch copy of
# examples/ and requires a fixture vector to fail for every mutant (runner
# exit 1). A mutant that survives means no vector depends on that clause; a
# mutant that breaks loading (exit 2) proves nothing and also fails.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
runner="$root/tests/run_fixture_expectations.pl"
scratch="$(mktemp -d)"
trap 'rm -rf "$scratch"' EXIT

# name | file | sed expression [| fixture aggregator, default v39]
# Guards are removed by a goal that keeps every variable used; emitters are
# disabled by appending ", fail". Both keep the mutant warning-free.
mutants=(
  "capacity_guard|v38_contextual_affect_deontics.pl|s/^under_taklif_control(cultivated)\./under_taklif_control(panic_overflow).\nunder_taklif_control(cultivated)./"
  "modality_guard|v38_contextual_affect_deontics.pl|s/^    memberchk(Cond, Conditions)\./    Cond = Cond, Conditions = Conditions./"
  "comparative_guard|v38_contextual_affect_deontics.pl|s/^    memberchk(stronger_than(Other), Conditions)\./    Other = Other, Conditions = Conditions./"
  "subject_guard|v38_contextual_affect_deontics.pl|s/^    agent_subject(Agent, Subject)\./    Agent = Agent, Subject = Subject./"
  "tier_guard|v38_contextual_affect_deontics.pl|s/^    \\\\+ quarantined_evidence(Evidence)\./    Evidence = Evidence./"
  "discharge_guard|v38_contextual_affect_deontics.pl|s/^    \\\\+ path_realizes(Path, Agent, Affect, Object)\./    \\\\+ \\\\+ path_realizes(Path, Agent, Affect, Object)./"
  "anti_pair_guard|v38_contextual_affect_deontics.pl|s/^    \\\\+ path_realizes(Path, Agent, Commanded, Object)\./    \\\\+ \\\\+ path_realizes(Path, Agent, Commanded, Object)./"
  "scope_guard|v39_sheaf_concern.pl|s/deontic(Affect, Object, _Operator1/deontic(_Affect1, Object, _Operator1/;s/deontic(Affect, Object, _Operator2/deontic(_Affect2, Object, _Operator2/"
  "operator_conflict|v39_sheaf_concern.pl|s/^operator_incompatible(o, f)\./operator_incompatible(o, f) :- fail./;s/^operator_incompatible(f, o)\./operator_incompatible(f, o) :- fail./"
  "alias_normalization|v39_sheaf_concern.pl|s/^    findall(Id, canonical_alias(Term, Id), Ids0),/    findall(Id, canonical_alias(Term, Id), _), Ids0 = [],/"
  "object_emitter|v39_sheaf_concern.pl|s/^    Source \\\\== Object\./    Source \\\\== Object, fail./"
  "source_fact_emitter|v39_sheaf_concern.pl|s/^    \\\\+ deontic_obligation(Affect, _, _, Operator, Modality, Warrant)\./    \\\\+ deontic_obligation(Affect, _, _, Operator, Modality, Warrant), fail./"
  "context_emitter|v39_sheaf_concern.pl|s/^    \\\\+ ctx(World, Agent, _)\\./    \\\\+ ctx(World, Agent, _), fail./"
  "subject_emitter|v39_sheaf_concern.pl|s/^    \\\\+ subject_matches(Agent, Subject),$/    \\\\+ subject_matches(Agent, Subject), fail,/"
  "membership_closure|v39_sheaf_concern.pl|s/^    \\\\+ subject_closed(Agent)\./    Agent = Agent./"
  "world_undetermined_emitter|v39_sheaf_concern.pl|s/^    membership_unknown(Agent, Subject)\./    membership_unknown(Agent, Subject), fail./"
  "claim_undetermined_emitter|v39_sheaf_concern.pl|s/^    membership_unknown(Agent, Subject),$/    membership_unknown(Agent, Subject), fail,/"
  "unbound_world_guard|v39_sheaf_concern.pl|s/^    must_be(atom, World),$/    true,/"
  "undetermined_verdict|v39_sheaf_concern.pl|s/^        Unknowns \\\\== \[\]$/        Unknowns \\\\== [], fail/"
  "modality_emitter|v39_sheaf_concern.pl|s/^    \\\\+ modality_satisfied(Modality, Conditions)\./    \\\\+ modality_satisfied(Modality, Conditions), fail./"
  "capacity_emitter|v39_sheaf_concern.pl|s/^    \\\\+ under_taklif_control(ControlStatus)\./    \\\\+ under_taklif_control(ControlStatus), fail./"
  "tier_emitter|v39_sheaf_concern.pl|s/^    quarantined_evidence(Evidence)\./    quarantined_evidence(Evidence), fail./"
  "observation_context_gate|v39_sheaf_concern.pl|s/^    ctx(World, Agent, _),$/    true,/"
  "claim_state_precedence|v39_sheaf_concern.pl|s/^    \\\\+ claim_obstruction(World, Agent, Claim, _, _)\\./    true./"
  "claim_to_world|v39_sheaf_concern.pl|s/^    claim_obstruction(World, Agent, Section, Category, Detail)\./    claim_obstruction(World, Agent, Section, Category, Detail), fail./"
  "fatwa_no_legal_value|v40_fatwa_rules.pl|s/^rule(liability, no_legal_value, C, \\([^)]*\\)) :-$/rule(liability, no_legal_value, C, \\1) :- fail,/|v40_fatwa_oracle_fixtures.pl"
  "fatwa_lawful_authority|v40_fatwa_rules.pl|s/^rule(liability, lawful_authority, C, \\([^)]*\\)) :-$/rule(liability, lawful_authority, C, \\1) :- fail,/|v40_fatwa_oracle_fixtures.pl"
  "fatwa_sirayat_al_jinaya|v40_fatwa_rules.pl|s/^rule(liability, sirayat_al_jinaya, C, \\([^)]*\\)) :-$/rule(liability, sirayat_al_jinaya, C, \\1) :- fail,/|v40_fatwa_oracle_fixtures.pl"
  "fatwa_unattributed_death|v40_fatwa_rules.pl|s/^rule(liability, unattributed_death, C, \\([^)]*\\)) :-$/rule(liability, unattributed_death, C, \\1) :- fail,/|v40_fatwa_oracle_fixtures.pl"
  "fatwa_physician|v40_fatwa_rules.pl|s/^rule(liability, physician, C, \\([^)]*\\)) :-$/rule(liability, physician, C, \\1) :- fail,/|v40_fatwa_oracle_fixtures.pl"
  "fatwa_guarantee_by_contract|v40_fatwa_rules.pl|s/^rule(liability, guarantee_by_contract, C, \\([^)]*\\)) :-$/rule(liability, guarantee_by_contract, C, \\1) :- fail,/|v40_fatwa_oracle_fixtures.pl"
  "fatwa_hand_of_trust|v40_fatwa_rules.pl|s/^rule(liability, hand_of_trust, C, \\([^)]*\\)) :-$/rule(liability, hand_of_trust, C, \\1) :- fail,/|v40_fatwa_oracle_fixtures.pl"
  "fatwa_quwwa_qahira|v40_fatwa_rules.pl|s/^rule(liability, quwwa_qahira, C, \\([^)]*\\)) :-$/rule(liability, quwwa_qahira, C, \\1) :- fail,/|v40_fatwa_oracle_fixtures.pl"
  "fatwa_victim_fault|v40_fatwa_rules.pl|s/^rule(liability, victim_fault, C, \\([^)]*\\)) :-$/rule(liability, victim_fault, C, \\1) :- fail,/|v40_fatwa_oracle_fixtures.pl"
  "fatwa_mubashir_liable|v40_fatwa_rules.pl|s/^rule(liability, mubashir_liable, C, \\([^)]*\\)) :-$/rule(liability, mubashir_liable, C, \\1) :- fail,/|v40_fatwa_oracle_fixtures.pl"
  "fatwa_mubashir_first|v40_fatwa_rules.pl|s/^rule(liability, mubashir_first, C, \\([^)]*\\)) :-$/rule(liability, mubashir_first, C, \\1) :- fail,/|v40_fatwa_oracle_fixtures.pl"
  "fatwa_mutasabbib_by_fault|v40_fatwa_rules.pl|s/^rule(liability, mutasabbib_by_fault, C, \\([^)]*\\)) :-$/rule(liability, mutasabbib_by_fault, C, \\1) :- fail,/|v40_fatwa_oracle_fixtures.pl"
  "fatwa_no_causation|v40_fatwa_rules.pl|s/^rule(liability, no_causation, C, \\([^)]*\\)) :-$/rule(liability, no_causation, C, \\1) :- fail,/|v40_fatwa_oracle_fixtures.pl"
  "fatwa_sufra_kudra_after_tuhr|v40_fatwa_rules.pl|s/^rule(doubt, sufra_kudra_after_tuhr, C, \\([^)]*\\)) :-$/rule(doubt, sufra_kudra_after_tuhr, C, \\1) :- fail,/|v40_fatwa_oracle_fixtures.pl"
  "fatwa_bayyina_in_qada|v40_fatwa_rules.pl|s/^rule(doubt, bayyina_in_qada, C, \\([^)]*\\)) :-$/rule(doubt, bayyina_in_qada, C, \\1) :- fail,/|v40_fatwa_oracle_fixtures.pl"
  "fatwa_rikaz|v40_fatwa_rules.pl|s/^rule(found_property, rikaz, C, \\([^)]*\\)) :-$/rule(found_property, rikaz, C, \\1) :- fail,/|v40_fatwa_oracle_fixtures.pl"
  "fatwa_trivial_find|v40_fatwa_rules.pl|s/^rule(found_property, trivial_find, C, \\([^)]*\\)) :-$/rule(found_property, trivial_find, C, \\1) :- fail,/|v40_fatwa_oracle_fixtures.pl"
  "fatwa_haram_makka|v40_fatwa_rules.pl|s/^rule(found_property, haram_makka, C, \\([^)]*\\)) :-$/rule(found_property, haram_makka, C, \\1) :- fail,/|v40_fatwa_oracle_fixtures.pl"
  "fatwa_dallat_al_ibil|v40_fatwa_rules.pl|s/^rule(found_property, dallat_al_ibil, C, \\([^)]*\\)) :-$/rule(found_property, dallat_al_ibil, C, \\1) :- fail,/|v40_fatwa_oracle_fixtures.pl"
  "fatwa_perishable_find|v40_fatwa_rules.pl|s/^rule(found_property, perishable_find, C, \\([^)]*\\)) :-$/rule(found_property, perishable_find, C, \\1) :- fail,/|v40_fatwa_oracle_fixtures.pl"
  "fatwa_dallat_al_ghanam|v40_fatwa_rules.pl|s/^rule(found_property, dallat_al_ghanam, C, \\([^)]*\\)) :-$/rule(found_property, dallat_al_ghanam, C, \\1) :- fail,/|v40_fatwa_oracle_fixtures.pl"
  "fatwa_announced_year|v40_fatwa_rules.pl|s/^rule(found_property, announced_year, C, \\([^)]*\\)) :-$/rule(found_property, announced_year, C, \\1) :- fail,/|v40_fatwa_oracle_fixtures.pl"
  "fatwa_illicit_exchange|v40_fatwa_rules.pl|s/^rule(unknown_owner, illicit_exchange, C, \\([^)]*\\)) :-$/rule(unknown_owner, illicit_exchange, C, \\1) :- fail,/|v40_fatwa_oracle_fixtures.pl"
  "fatwa_owner_appears_after_charity|v40_fatwa_rules.pl|s/^rule(unknown_owner, owner_appears_after_charity, C, \\([^)]*\\)) :-$/rule(unknown_owner, owner_appears_after_charity, C, \\1) :- fail,/|v40_fatwa_oracle_fixtures.pl"
  "fatwa_family_recipient|v40_fatwa_rules.pl|s/^rule(unknown_owner, family_recipient, C, \\([^)]*\\)) :-$/rule(unknown_owner, family_recipient, C, \\1) :- fail,/|v40_fatwa_oracle_fixtures.pl"
  "fatwa_recipient|v40_fatwa_rules.pl|s/^rule(unknown_owner, recipient, C, \\([^)]*\\)) :-$/rule(unknown_owner, recipient, C, \\1) :- fail,/|v40_fatwa_oracle_fixtures.pl"
  "fatwa_bank_amara_tie|v40_fatwa_rules.pl|s/^    ;   RA =:= RZ, Amara == true -> Prevails = true$/    ;   RA =:= RZ, Amara == true, fail -> Prevails = true/|v40_fatwa_oracle_fixtures.pl"
  "fatwa_same_ruling|v40_fatwa_rules.pl|s/^same_ruling(hold, handToAuthority)\\./same_ruling(hold, handToAuthority) :- fail./|v40_fatwa_oracle_fixtures.pl"
)

survivors=0
for spec in "${mutants[@]}"; do
  IFS='|' read -r name file expr fixture <<<"$spec"
  rm -rf "$scratch/examples"
  cp -r "$root/examples" "$scratch/examples"
  target="$scratch/examples/$file"
  sed -i "$expr" "$target"
  if cmp -s "$root/examples/$file" "$target"; then
    echo "not ok - $name: mutation did not apply"
    survivors=$((survivors + 1))
  else
    status=0
    swipl "$runner" -- "$scratch/examples/${fixture:-v39_sheaf_obstruction_fixtures.pl}" >/dev/null 2>&1 || status=$?
    case "$status" in
      1) echo "ok - $name: killed" ;;
      0) echo "not ok - $name: mutant survived"; survivors=$((survivors + 1)) ;;
      *) echo "not ok - $name: mutant not judged (exit $status)"; survivors=$((survivors + 1)) ;;
    esac
  fi
done

echo "1..${#mutants[@]}"
exit $((survivors > 0))
