# Usul.Typing.IDAOmissionWire in Plain English

Source: [`formal/lean/Usul/Typing/IDAOmissionWire.lean`](../../../../formal/lean/Usul/Typing/IDAOmissionWire.lean)

An observation batch names one omission opportunity and lists reports and
optional coverage for that scope. The wire format reuses the act registry
codecs for the action, accountable person and performer. It also carries
the definition and clock versions, definition digest, and opportunity
with both time bounds.

The scope round trip proves the encoding preserves every field. Injectivity
means two distinct scopes cannot encode to the same value. Review first
resolves the exact current snapshot and obtains its omission scope. Lean
proves that any successful assessment used that scope, the supported wire
version, and the resolved snapshot's effective time and recording cutoff.
Only the two declared performance modes decode.

The module consumes a typed batch. Authentication is performed before
invoking it at the host boundary.
