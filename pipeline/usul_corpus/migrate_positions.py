"""One-time, pinned migration for legacy position references.

Only the reviewed source files and ordered case positions captured below may
be migrated. Normal loading never adds or refreshes a receipt. Reordering the
cases and rerunning this command fails, rather than laundering stale indices.
Historical snapshots remain untouched. Run: python -m usul_corpus.migrate_positions
"""
from copy import deepcopy
from hashlib import sha256
import json
from pathlib import Path

from . import takhrij
from .position_receipts import FIELD, digest
from .values import code

SOURCES = {
    "reconciliation/ledger.json": "6c0b837f9a2532e4c92c6bf5e27b50215b1c7f4e6d1f0f165d68f0d184e6af49",
    "reconciliation/entries/pr30.json": "85c0665f226da22172df3b22b09f56ba2a602651aca5b156e74d61539d53cafd",
    "reconciliation/entries/rajab-a1.json": "b3371b60d964429db332048d29acddabbeaa3c456c07c0ed0a613933a096ee15",
    "reconciliation/entries/rajab-a10.json": "e3353858d948b112227284cbbe5c3b00d2df45aa84d47b383925bfffeb1e7985",
    "reconciliation/entries/rajab-a11.json": "749270ef292e63db51c4003f6a20fedb5b0a7a8ac2190d010fbdf4dfbc4bf06a",
    "reconciliation/entries/rajab-a12.json": "35cd67fe17084b1d58332daf8aa8d77dfff7019d2f9b9c641f5c3a59dbde40b2",
    "reconciliation/entries/rajab-a13.json": "1509a9f667380f7238e3557ac78ef32e9153cf8195a0e80be341fca1b6e7edf2",
    "reconciliation/entries/rajab-a14.json": "bf24bd89ce91df1e4d62d581ccb6257094bb2dffe04800044b18ac0dc584f3fa",
    "reconciliation/entries/rajab-a15.json": "4a295108a5ed4e6671e2bd9577a41e632d005b9dbebf0bef3f526f2546e6b3b4",
    "reconciliation/entries/rajab-a16.json": "e3eb12da99e044ecc7d50cea407bf17f33c546e5309aa7ee661234baed2b7750",
    "reconciliation/entries/rajab-a17.json": "7efa81721c702ee7f99c6b725585c9b6b49cef91429d54be3ac78a7efd6df01d",
    "reconciliation/entries/rajab-a18.json": "fb4240b978b8d775e5e52e08c538bcfd8fdcf75e1cb0f148bb58cc3e40a4be11",
    "reconciliation/entries/rajab-a19.json": "493f499df17b7f2a521b96084a20f7006ae7412b98606b62f5d685422bde50a2",
    "reconciliation/entries/rajab-a2.json": "710db8e875dc6b606351f159437993510c048b7a31ec7400f280ddde6a91d4f8",
    "reconciliation/entries/rajab-a20.json": "a51f3fcce39f030169c81942ceaaa4f0cfc15e56345b0f1a1557867c66cfe233",
    "reconciliation/entries/rajab-a21.json": "e074a3876ef16b57b590087ff2a322f69d2e16990dfcc67e809194953ef4ca8f",
    "reconciliation/entries/rajab-a22.json": "6e57fe947e36da65f24b8cf3b63607b7d5e7c5cc887b733e36266b6de7cea0ce",
    "reconciliation/entries/rajab-a23.json": "4473446124bc1a9791b17aa3bcf430f405bcae8d404f9c8544a364b4a142f56e",
    "reconciliation/entries/rajab-a24.json": "a2ead3314ec54dba23fa4fda67017785cf41d1ff2007f939a130aa27cc670524",
    "reconciliation/entries/rajab-a25.json": "39150227e457dc918e1d8d417df6c13fdef8c501006c067a800d8d25772a7eec",
    "reconciliation/entries/rajab-a3.json": "59f396c4e28bea7c1b60fcf80b31208cc7ab8126a005e90c1ca1142a4d3dafa4",
    "reconciliation/entries/rajab-a4.json": "d66d3b7fe91cbb4e001a89cf3884c0b654d1c921a95d3022a455a1a11712a296",
    "reconciliation/entries/rajab-a5.json": "425a9e6e47d5bd62e6b37eec8bcc507ea9c45139bbf0eff458eb5289680131d8",
    "reconciliation/entries/rajab-a6.json": "0b52f5ebf5ae60c13d737bab93cd8a0c2c30c73a722365d9fe644b7ffb7f165c",
    "reconciliation/entries/rajab-a7.json": "21d006a3bcbad869994f2764d46901d45ab72f577064710563953dec43eb83e9",
    "reconciliation/entries/rajab-a8.json": "ce627cca826684c2cc05f15da27b29a2f128a223c6b843ecd9ceaa2fe826d56a",
    "reconciliation/entries/rajab-a9.json": "93b9902cf2d1943cd0deae7267f8f20a5775e329cb92896b74cc960bd6c9b5a3",
    "reconciliation/entries/rajab-q127.json": "3b44b805aa57cf9faa639742bff4c2366f0185c8fcb9980753381d05683cef10",
    "reconciliation/entries/tarjih-backfill.json": "c2bec88e2a9345790f698ac6f70b9f5dcedabc85fe08e342b56571607fb77ff9",
    "reconciliation/weighing/batch-00.json": "0359e3e7d8560d7ec83069cd076e607e20623d8fef52a718048b4f9502af5c66",
    "reconciliation/weighing/batch-01.json": "50cafeabf09a8a1fb4ad2f96be3f8f1ae81d8c863897b0ad9bdf5bbe89f7cf20",
    "reconciliation/weighing/batch-02.json": "c5e295139f05e7b4bd936b2fd8322b8331e99fe6ec7d250773510829576a4179",
    "reconciliation/weighing/batch-03.json": "c88fb05105d6f9fabfcf85cec1620b0cdba87dc43e1492ebbea3b45af1b1bda4",
    "reconciliation/weighing/batch-04.json": "09def227c8bd0379b89f1399fb30009db98228fa918043b443919dc2b2a4bb45",
    "reconciliation/weighing/batch-05.json": "597830cc90b946a14115be56a79131f471937fb20fb8246ad5d3f8f5314dd067",
    "reconciliation/weighing/batch-06.json": "bde9bfb64e1a7d67b2c5ec5bbcca56aff117d1174ace4749c965f349418a84bc",
    "reconciliation/weighing/batch-07.json": "a0afa317612b7bfeac767ad75d7a6090baaa7d1640a251207772f66230bfa786",
    "reconciliation/weighing/batch-08.json": "2fbc5283b9ae0ca6577c158ef8b4c7363c579a79d5d005868b9f488136b67741",
    "reconciliation/weighing/batch-09.json": "e9a40ed902c24f51c3a06a10d029cc471775e8ca55afa0ec667c7a3cb42d89dd",
    "reconciliation/weighing/batch-10.json": "73e423e351a317c701b1c095c927a8ed2d839b203f068100f6f9452b274bd9b1",
    "reconciliation/weighing/batch-11.json": "baff0b80de0c4d6db1cd6ce5a5d6ee34e8bd044275b7b033c858ef1a086a09a5",
    "reconciliation/weighing/batch-12.json": "aca0d1e421865fcdf4ae234828a7bd5ae6cd3afed59c391eb0b4bc0700431580",
    "reconciliation/weighing/batch-13.json": "611ee4c3b851781587e4880a2d6a37e253736f93694c4299ffc4535ad00de0c9",
    "reconciliation/weighing/batch-14.json": "82739783bd974539ba22ce1b9ecf255fad06af18a0df45c62b704e01319b4510",
    "reconciliation/weighing/batch-15.json": "0d8d73fa453c36f33dcc2728e2916304711da55eeae4d8ee3a25e1d7d019224c",
    "reconciliation/weighing/batch-16.json": "f3aab0556f95a7de2c88c80b26d72ceb167e0989845ebb4a6302b6b957bdfe8e",
    "reconciliation/weighing/batch-17.json": "a1b4191bc0460753b3eee1c0a5963560d2355dad4dcd8a4c900981e27e5df68d",
    "reconciliation/weighing/batch-18.json": "ed387da1a6912bd9d645ae4eb4f2083fa06f0f0f61a74af8add8fe260e8c144f",
    "reconciliation/weighing/batch-19.json": "78ba0c1e503c4b1ddd9decfcaefe7fa8bc26f99423b0b304b1fc382f199f16cc",
    "reconciliation/weighing/batch-20.json": "6fac047c133f14eb989b5373abd45be6bc7463a0f047a97bc82eb99d312230b6",
    "reconciliation/weighing/batch-21.json": "07f501e15cde587de2cec003d00ebd54d3a80521e9cb0f0d0811e2cb15633d85",
    "reconciliation/weighing/batch-22.json": "80f9f923d84d4eba6873a080b84197a97e639175f78d8294f531abcdf944ec27",
    "reconciliation/weighing/batch-23.json": "39529448318c31a75031ff45a9fbca84c7b175fb95b0d230c40dda37ec1ca53f",
    "reconciliation/weighing/batch-24.json": "1fa4603dbd9dd3eb98490244d750ac12f48c623a3f059858a33da20b87a3caa5",
    "reconciliation/weighing/batch-25.json": "342aa8668893a395984fe3e6dc1ac02eb2ca8d5235e40aa093282de9db3ede10",
    "reconciliation/weighing/batch-26.json": "6243fa1484d77dc721324c50439918dcc3ba18373f311ce2d6abeae7fbdebfaf",
    "reconciliation/weighing/batch-27.json": "fbfdf3fc9507b1358f185a4adc44f02a28c2ced0585c03b526bb76c34c319c84",
    "reconciliation/weighing/batch-28.json": "d2811856e4ddce0da53c9a036dd41d1efce9f2069286ae6da514c1f87694e63a",
    "reconciliation/weighing/batch-29.json": "5ba8cb2da2767bfd03dccdf6439b04b22a152ad8806d1a11b597db1f44e08c5c",
    "reconciliation/weighing/batch-30.json": "1c1c3b9f48e74956552bbe876b73d3a99050c182530982c7c9b0b6bdb0e77f82",
    "reconciliation/weighing/batch-31.json": "3f66764f6c80a4a5726cf5c0c345e56ea081b1a1748c95fd47825e51e7f9c406",
    "reconciliation/weighing/batch-32.json": "a7c9a36086c0ec7ece5395d883a3cfe8ba8af3e44158bccb820a30bb89ffe81b",
    "reconciliation/weighing/batch-33.json": "36dc570d54719dd13c869b24ac45391d737a301a04d0fc3cb091e8fa63643ef7",
    "reconciliation/weighing/batch-34.json": "8b007b2b471618168451c5ca9f815e177db8a48a50ce5cc294d9babc9e8b4e2f",
    "reconciliation/weighing/batch-35.json": "72474258e373744269e0adae03e6d8de2c0891c303087c5d4c41bacd0c61d23e",
    "reconciliation/weighing/batch-36.json": "6a243685257bd748f815e95201ddebf218f4e7d292d418fbe4fa7cfe7d100ad3",
    "reconciliation/weighing/batch-37.json": "b37e4e889fa0f2c2cfa6163ce2e4740c1f49db997b840c1348613fe013bbb749",
    "reconciliation/weighing/batch-38.json": "4ad02b51c821c2b75fa177957a1b09938a40fd5cdf46bc7ead7f3684b662c99d",
    "reconciliation/weighing/pilot.json": "0fe67ffd66b5356baf52f956387c0b1e0ccc88af4ed26645e9ab3143b3ee4441"
}
SUBJECTS_SHA256 = '76364aefdeb187997f6f220ed8e14910404ef098960c3e819c9a69351b1fc42c'


def outputs(corpus: Path) -> list[tuple[Path, bytes]]:
    cases = {c["far"]: c for c in takhrij.load(corpus)}
    parsed = []
    subjects = set()
    for relative, expected in SOURCES.items():
        path = corpus / relative
        raw = path.read_text(encoding="utf-8")
        data = json.loads(raw)
        original = deepcopy(data)
        for entry in original["entries"]:
            entry.pop(FIELD, None)
            subjects.add(entry["far"])
        # Preserve each source's existing indentation and terminal newline.
        indent = len(raw.splitlines()[1]) - len(raw.splitlines()[1].lstrip())
        if sha256(code(original).encode()).hexdigest() != expected:
            raise ValueError(f"{relative}: differs from the pinned pre-migration entry data")
        parsed.append((path, data, indent))
    actual = sha256(code({far: digest(cases[far]) for far in sorted(subjects)}).encode()).hexdigest()
    if actual != SUBJECTS_SHA256:
        raise ValueError("ordered positions differ from the pinned migration subjects; revalidate evidence")
    result = []
    for path, data, indent in parsed:
        for entry in data["entries"]:
            receipt = digest(cases[entry["far"]])
            if FIELD in entry and entry[FIELD] != receipt:
                raise ValueError(f"{path.name}: refusing to replace a stale receipt")
            entry[FIELD] = receipt
        result.append((path, (json.dumps(data, ensure_ascii=False, indent=indent) + "\n").encode()))
    return result


def main():
    corpus = Path(__file__).resolve().parents[2] / "corpus"
    pending = outputs(corpus)  # Validate every source and subject before any write.
    for path, raw in pending:
        path.write_bytes(raw)
    print(f"pinned position receipts in {len(pending)} files")


if __name__ == "__main__":
    main()
