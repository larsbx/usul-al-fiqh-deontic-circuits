# Usul.Typing.IDASubstitution in Plain English

Source: [`formal/lean/Usul/Typing/IDASubstitution.lean`](../../../../formal/lean/Usul/Typing/IDASubstitution.lean)

This module checks sorted variables and rigid references, reindexes registered
descriptions and inquiry participants, and grounds them through the existing
IDA types. It also defines signed atoms, conjunction, and conditional premise
arrows.

| Theorem | What it establishes |
|---|---|
| `Term.decode_wrong_sort`, `Term.rigid_preserved` | The decoder rejects a rigid term of another sort and substitution fixes a rigid reference. |
| `Sub.assoc`, `Args.get_subst`, `Args.shared_image` | Composition is associative. Each argument position follows the same substitution and shared terms retain shared images. |
| `Description.subst_id`, `Description.subst_comp`, `Description.schema_preserved`, `Description.subst_wellFormed` | Descriptions satisfy the action laws, keep their registered schema, and ground to a well-formed action. |
| `Inquiry.ground_comp`, `Inquiry.frame_preserved` | One-step and staged inquiry grounding agree, and reindexing keeps the fixed frame. |
| `Formula.subst_id`, `Formula.subst_comp` | Formula reindexing follows identity and composition. |
| `Derives.subst`, `Derives.cut`, `Derives.iff_atoms` | The conditional calculus admits substitution and simultaneous cut and is exactly checked by available atoms. |
| `PremiseArrow.check_iff`, `PremiseArrow.id_comp`, `PremiseArrow.comp_id`, `PremiseArrow.assoc` | The checker requires every substituted premise, and its arrows obey the category laws. |
