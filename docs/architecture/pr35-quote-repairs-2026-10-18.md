# PR-35 quotation repairs (2026-10-18)

Step 3 of the [audit plan](audit-2026-10-15-plan.md). The source gate (`source_verify.check_quote`) now
requires every quotation to start and end on a word boundary, to keep a negation that stands just before
it, and not to stop before a qualifier, whatever markup lies between; presentation forms such as «ﻻ» key
as their letters, and an excerpt may not hold an Arabic letter the key does not carry.

On the required witnesses the stricter gate rejected 77 of 4,467 verified excerpts: 59 dropped a
negation just before them, 13 ended and 4 started mid-word, and 1 (al-Iqnāʿ v04:p060)
stopped before «- لكن قال الموفق …». No excerpt held a letter outside the key. Each was extended from its
locked witness only: back over the rest of the word or the negation, forward to the end of the word, and
for al-Iqnāʿ through «لكن قال الموفق ومن تابعه الورع التزام الطلاق». No excerpt was shortened or reworded,
no locator changed, and the gate then verifies all of them.

## Evidence associations to review

An excerpt that began just after a negation may have been read as saying the opposite. Two were checked
(`tarjih-backfill.json` `/entries/43/evidence/0`, whose cited claim follows the negated riwāya, and
`ledger.json` `/entries/20/evidence/1`, whose «لم يلزمه» is the position it supports); the others are
listed for a reviewer to confirm that each still supports the position it is attached to. No resolution
depends on attribution evidence (`reconcile.attribution` is a record), but weighing proofs among them
(`weighing/*.json`) do bear on tarjīḥ.

| Item | Negation | Position ruling | Excerpt now begins |
|---|---|---|---|
| `dossier/refinements.json` `/entries/31/refs/0` | لم | — | لم يلزمه) تعلمها بالعربية لأن النكاح غير واجب … |
| `reconciliation/entries/rajab-a10.json` `/entries/0/evidence/1` | لا | `true` | لا حد فيه ولزمه أن يمسك عنهما حتى … |
| `reconciliation/entries/rajab-a11.json` `/entries/5/evidence/2` | لم | `false` | لم تكمل الحرية) فيهما لأنها لو كملت لم … |
| `reconciliation/entries/rajab-a17.json` `/entries/2/evidence/3` | لم | `false` | لم يعقلوا عنه كأهل محلته لأنهم لا يرثونه … |
| `reconciliation/entries/rajab-a17.json` `/entries/7/evidence/2` | غير | `false` | غير وطء في فرج) ; لأن تحريمها لعارض … |
| `reconciliation/entries/tarjih-backfill.json` `/entries/1/evidence/2` | لا | `true` | لا أو في ضمين فقول من ينفيه نص … |
| `reconciliation/entries/tarjih-backfill.json` `/entries/1/evidence/5` | ما | `true` | ما يفسد العقد من سفه أو صغر أو … |
| `reconciliation/entries/tarjih-backfill.json` `/entries/11/evidence/4` | ما | `false` | ما لي بينة ثم أتى بها أو قال: … |
| `reconciliation/entries/tarjih-backfill.json` `/entries/116/evidence/0` | غير | `true` | غير جنسهما، كمد عجوة ودرهم بمدين، أو بدرهمين، … |
| `reconciliation/entries/tarjih-backfill.json` `/entries/116/evidence/2` | غير | `true` | غير جنسهما كمد عجوة ودرهم بمثلهما) أي بمد … |
| `reconciliation/entries/tarjih-backfill.json` `/entries/116/evidence/4` | غير | `true` | غير جنسهما كمد عجوة ودرهم بمثلهما) أي بمد … |
| `reconciliation/entries/tarjih-backfill.json` `/entries/120/evidence/0` | لا | `true` | لا ترث. فعليها: لأم الأم مع الأب وأمه: … |
| `reconciliation/entries/tarjih-backfill.json` `/entries/124/evidence/1` | لم | `"whole"` | لم يرتفع حدثه حتى يخرج مرتبا نصا كالراكد … |
| `reconciliation/entries/tarjih-backfill.json` `/entries/124/evidence/3` | لم | `"whole"` | لم يجزئه. ولو انغمس في ماء راكد أو … |
| `reconciliation/entries/tarjih-backfill.json` `/entries/133/evidence/0` | لم | `true` | لم يرجع على الغاصب بقيمة العين. ويرجع عليه … |
| `reconciliation/entries/tarjih-backfill.json` `/entries/142/evidence/6` | لم | `true` | لم يعلم سبق أحدهما ولا معيتهما (صلوا ظهرا) … |
| `reconciliation/entries/tarjih-backfill.json` `/entries/150/evidence/2` | ما | `false` | ما أمرني به أو محوت المصحف إن فعلت … |
| `reconciliation/entries/tarjih-backfill.json` `/entries/151/evidence/3` | ما | `false` | ما حلف لا يفعله قاصدا له (إلا في … |
| `reconciliation/entries/tarjih-backfill.json` `/entries/181/evidence/4` | ما | `false` | ما فرضه فارض في المستقبل ولا ينعزل حيث … |
| `reconciliation/entries/tarjih-backfill.json` `/entries/194/evidence/2` | لم | `true` | لم يدفعها لحاكم (الصدقة بها عنهم) أي: عن … |
| `reconciliation/entries/tarjih-backfill.json` `/entries/195/evidence/2` | لم | `true` | لم يدفعها لحاكم (الصدقة بها عنهم) أي: عن … |
| `reconciliation/entries/tarjih-backfill.json` `/entries/196/evidence/3` | لم | `true` | لم يدفعها لحاكم (الصدقة بها عنهم) أي: عن … |
| `reconciliation/entries/tarjih-backfill.json` `/entries/208/evidence/0` | لا | `false` | لا يكون مقرا بذلك وهو المذهب قال في … |
| `reconciliation/entries/tarjih-backfill.json` `/entries/217/evidence/4` | ما | `true` | ما بقي أو نصف قنين أجزأ لا ما … |
| `reconciliation/entries/tarjih-backfill.json` `/entries/228/evidence/0` | لم | `false` | لم يصر موليا حتى يطأ ثلاثا، فحينئذ يصير … |
| `reconciliation/entries/tarjih-backfill.json` `/entries/231/evidence/3` | لم | `false` | لم يجتمع معها فيه مثلها فصح كما لو … |
| `reconciliation/entries/tarjih-backfill.json` `/entries/238/evidence/3` | ما | `false` | ما طلق فلان زوجته (فطلقة) لأنها اليقين وما … |
| `reconciliation/entries/tarjih-backfill.json` `/entries/24/evidence/4` | لا | `true` | لا قيمته وله التصرف ببيع وغيره ولا يرجع … |
| `reconciliation/entries/tarjih-backfill.json` `/entries/244/evidence/5` | ما | `"part"` | ما لو حابى أجيرا في الأجر فإن الأجر … |
| `reconciliation/entries/tarjih-backfill.json` `/entries/27/evidence/1` | لا | `false` | لا إشكال في عدم النفوذ. وعلى المذهب قيل: … |
| `reconciliation/entries/tarjih-backfill.json` `/entries/27/evidence/6` | لا | `true` | لا يزيل الملك في حق الجاني والراهن والمفلس … |
| `reconciliation/entries/tarjih-backfill.json` `/entries/41/evidence/2` | لم | `true` | لم يتحر للنكاح وكف عنهن وفى قبيلة كبيرة … |
| `reconciliation/entries/tarjih-backfill.json` `/entries/43/evidence/0` | لا | `true` | لا يضمن إذا كسر ختم كيسها، أو حله. … |
| `reconciliation/entries/tarjih-backfill.json` `/entries/45/evidence/1` | ما | `true` | ما اختاره الخرقي والشيخ هو الصحيح واختاره الشارح … |
| `reconciliation/entries/tarjih-backfill.json` `/entries/51/evidence/5` | لم | `false` | لم يضمن كرديف ربها ورائض ووكيل ومن قال … |
| `reconciliation/entries/tarjih-backfill.json` `/entries/51/evidence/6` | لم | `false` | لم ينفرد بحفظها. أشبه ما لو غطى ضيفه … |
| `reconciliation/entries/tarjih-backfill.json` `/entries/58/evidence/2` | لم | `true` | لم يضمنه وإن أرسله إنسان من يده المشاهدة … |
| `reconciliation/entries/tarjih-backfill.json` `/entries/59/evidence/3` | لم | `true` | لم يضمنه وإن وصى بإعطاء مدع عينه دينا … |
| `reconciliation/entries/tarjih-backfill.json` `/entries/68/evidence/2` | لم | `true` | لم يقل: إلي فهو مقر بقبضه, لا أبرأتك, … |
| `reconciliation/entries/tarjih-backfill.json` `/entries/69/evidence/3` | لم | `false` | لم يقيد عليه وإن وكل فكوكيل ومتى عزل … |
| `reconciliation/entries/tarjih-backfill.json` `/entries/70/evidence/3` | لم | `false` | لم يقيد عليه وإن وكل فكوكيل ومتى عزل … |
| `reconciliation/entries/tarjih-backfill.json` `/entries/71/evidence/0` | لم | `false` | لم يعجز عنه فكذلك هنا. والطريق الثاني: يجوز … |
| `reconciliation/entries/tarjih-backfill.json` `/entries/73/evidence/3` | لم | `true` | لم يحتج أكل) منه (بمعروف) إلحاقا له بعامل … |
| `reconciliation/entries/tarjih-backfill.json` `/entries/77/evidence/2` | لا | `"half"` | لا يغرقها اتفاقا, ذكره ابن عقيل, وعنه: نصفها … |
| `reconciliation/entries/tarjih-backfill.json` `/entries/77/evidence/6` | لا | `"full"` | لا يحتمله) المضروب (فتلف ضمنه) الضارب (بديته) كاملة … |
| `reconciliation/entries/tarjih-backfill.json` `/entries/79/evidence/5` | ما | `"full"` | ما نقصه من خرق جلده ونحوه وإن كان … |
| `reconciliation/history/pr49-q014-resolved.json` `/entries/1/evidence/2` | لم | `"neither"` | لم تعتقا) أي الأمتان (ولم تطلقا) أي المرأتان، … |
| `reconciliation/ledger.json` `/entries/148/evidence/1` | لا | `"lot"` | لا تصح، للإبهام. واختار الصحة في غير الأولى: … |
| `reconciliation/ledger.json` `/entries/153/evidence/2` | لم | `"no divorce; each rests on certainty of his marriage"` | لم تعتقا) أي الأمتان (ولم تطلقا) أي المرأتان، … |
| `reconciliation/ledger.json` `/entries/155/evidence/0` | لم | `"no lot; lineage lost"` | لم يوجد قافة) أو اختلف قائفان (ضاع نسبه … |
| `reconciliation/ledger.json` `/entries/20/evidence/1` | لم | `true` | لم يلزمه) تعلمها بالعربية لأن النكاح غير واجب … |
| `reconciliation/ledger.json` `/entries/3/evidence/0` | لم | `false` | لم يجزه على الصحيح من المذهب، وقيل: يجزيه، … |
| `reconciliation/ledger.json` `/entries/59/evidence/3` | لا | `false` | لا يعضد شوكه» ، وقدمه ابن رزين في … |
| `reconciliation/weighing/batch-01.json` `/entries/6/proofs/3` | لم | `false` | لم تتحقق نجاسته وهو قول الثوري وأصحاب الرأي … |
| `reconciliation/weighing/batch-02.json` `/entries/3/proofs/1` | لا | `false` | لا والأظهر أن المطالبة تمنع التصرف كالشفعة … |
| `reconciliation/weighing/batch-10.json` `/entries/7/proofs/1` | لم | `true` | لم يحتج أكل) منه (بمعروف) إلحاقا له بعامل … |
| `reconciliation/weighing/batch-24.json` `/entries/10/proofs/1` | لا | `true` | لا إن ألحقناها بالشجر لتكرر حملها جاز فيه … |
| `reconciliation/weighing/batch-36.json` `/entries/2/proofs/0` | ما | `false` | ما طلق فلان زوجته (فطلقة) لأنها اليقين وما … |
| `reconciliation/weighing/batch-38.json` `/entries/11/proofs/1` | غير | `true` | غير نية حقيقة، كما لو نسي الصوم بعد … |
