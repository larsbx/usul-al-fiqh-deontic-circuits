# scripts.CheckIDAActRegistryWire in Plain English

Source: [`formal/lean/scripts/CheckIDAActRegistryWire.lean`](../../../formal/lean/scripts/CheckIDAActRegistryWire.lean)

After the host verifies canonical bytes and definition digests, this executable
parses every registry/envelope field into the actual Lean structures. It calls
the real resolver and emits the complete decoded registry, envelope, projected
target, and result code.

The driver compares every returned field with the original canonical bundle and
compares outcomes with independently instantiated Quint inputs. This protects
against an omitted field hidden by equal status codes.

The core proves structural-wire round trips. General correctness of the textual
JSON parser and SHA-256 remains a separately exercised host boundary. This
adapter does not accept source authorities or issue admitted source receipts.
