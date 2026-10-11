import Usul.Signature
import Usul.Muamalat
import Usul.Refinements
import Usul.Sadi
import Usul.Kulliyyat
import Usul.Dalala
import Usul.CommandSchemata

/-!
# The types the qawāʿid define

Each structure is the type one qāʿida's statement ranges over: the facts it holds, each `Option`
until a text settles it (`Usul.Typing`). A qāʿida that builds on another extends its type. A field
is shared only where qawāʿid state the same notion; two unrelated qawāʿid that happen to use one
word get qualified field names (`mixedSameKind` / `actsSameKind`), since Lean merges same-named
fields of parent structures. Statements are quoted from the committed records
(`corpus/proposals/sadi_qawaid.json`, `corpus/records`).
-/

namespace Usul.Typing.Qaida

open Usul Usul.Muamalat

/-- al-Saʿdī Q11 «الأصل بقاء ما كان على ما كان، واليقين لا يزول بالشك»: the presumption and the
apparent that would displace it, each with its epistemic grade. -/
structure Yaqin where
  asl : Option Grade := none
  zahir : Option Grade := none

/-- al-Saʿdī Q52 «إذا قويت القرائن قدمت على الأصل»: Q11's type, with the indicator (qarīna). -/
structure Qarain extends Yaqin where
  amara : Option Bool := none

/-- al-Saʿdī Q13 «الإتلاف يستوي فيه المتعمد والجاهل والناسي»: the destroyer's state of mind. -/
structure ItlafHal where
  mental : Option MentalState := none

/-- al-Saʿdī Q36 «من أتلف شيئاً لينتفع به ضمنه، ومن أتلفه دفعاً لمضرته فلا ضمان عليه»: the purpose
of the destruction. -/
structure ItlafQasd where
  purpose : Option Purpose := none

/-- al-Saʿdī Q14 «التلف في يد الأمين غير مضمون إذا لم يتعد أو يفرط، وفي يد الظالم مضمون مطلقاً»: the
hand, and the trustee's transgression («يتعد») and negligence in safekeeping («يفرط»); with
`pureTrust`, the pure trust (amāna maḥḍa) that transgression voids. -/
structure Amana where
  hand : Option Hand := none
  pureTrust : Option Bool := none
  transgressed : Option Bool := none
  negligent : Option Bool := none

/-- Ibn Rajab Q6: an act done on a presumption later shown wrong stands, save «لتعلق حق الغير به»
and for one who «فرط بترك البحث والتحقيق» (negligence in inquiry, not in safekeeping). -/
structure ZannError where
  othersRight : Option Bool := none
  negligentInquiry : Option Bool := none

/-! ### The unknown as non-existent: al-Saʿdī Q20, Ibn Rajab 106 and its instances -/

/-- al-Saʿdī Q20 «إذا تعذر معرفة من له الحق جعل كالمعدوم»: whether the right-holder can be known. -/
structure MajhulHaqq where
  ownerIdentifiable : Option Bool := none

/-- Ibn Rajab 106 «ينزل المجهول منزلة المعدوم وإن كان الأصل بقاءه إذا يئس من الوقوف عليه أو شق
اعتباره»: the unknown, despair of learning it, the hardship of taking it into account. -/
structure MajhulMadum where
  unknown : Option Bool := none
  despair : Option Bool := none
  hardship : Option Bool := none

/-- Ibn Rajab 106.f002 «اللقطة بعد الحول فإنها تتملك لجهالة ربها وما لا يتملك منها يتصدق به»:
106's type, with the year of announcement and whether the find is ownable. -/
structure Luqata extends MajhulMadum where
  yearPassed : Option Bool := none
  ownable : Option Bool := none

/-- Ibn Rajab 22 «العين المنغمرة في غيرها إذا لم يظهر أثرها …», read as an instance of 106. -/
structure Istihlak extends MajhulMadum where
  consumed : Option Bool := none

/-! ### The substitute: al-Saʿdī Q28 and Ibn Rajab 7, 16 -/

/-- al-Saʿdī Q28 «يقوم البدل مقام المبدل، ولكن لا يصار إليه إلا إذا تعذر الأصل»: whether the
original is possible. -/
structure Badal where
  originalPossible : Option Bool := none

/-- Ibn Rajab 16, judged at the time of obligation («والاعتبار في الكفارات بحالة الوجوب»). -/
structure BadalWujub extends Badal where
  settledAtObligation : Option Bool := none

/-- Ibn Rajab 7: the substitute was legislated out of necessity, not as a general concession. -/
structure Intiqal extends Badal where
  necessity : Option Bool := none

/-! ### Certainty and doubt: instances of al-Saʿdī Q11 and Q52 -/

/-- Ibn Rajab 160 (Taqī al-Dīn): «متى علق الطلاق بشرط وأمكن وجوده فإنه يعتزل امرأته حتى يعلم
انتفاؤه»; the certain marriage stands (Q11), abstention is a rule of conduct. -/
structure Itizal extends Yaqin where
  suspended : Option Bool := none
  possible : Option Bool := none
  absenceKnown : Option Bool := none

/-- Ibn Rajab 68: acting while doubting a condition of validity, firm intention needed or not,
ghalabat al-ẓann, a presumption that has not been shown to cease (Q11, Q52). Its «غلبة ظن» is not a field of its own: it is Q11's
ẓāhir graded at least ẓann (`Grade.IsYaqin`), read through `Qarain` (identified, 2026-10-11). -/
structure ShakkShart extends Qarain where
  needsFirm : Option Bool := none
  aslMustashab : Option Bool := none

/-- Ibn Rajab 68.f001 «لأن المسح رخصة ولم تتحقق إباحتها فلم يصح»: a concession is 68's first type. -/
structure Rukhsa extends ShakkShart where
  rukhsaNeedsCertainty : Option Bool := none
  permissionEstablished : Option Bool := none

/-- A forgotten iḥrām intention (Q11): what is valid on every possible rite suffices. -/
structure NiyyaMansiyya extends Yaqin where
  component : Option (Refinements.Nusuk → Bool) := none

/-! ## The remaining encoders' qawāʿid -/

/-- Ibn al-Laḥḥām 43 «الأمر المجرد عن قرينة هل يقتضى الوجوب أم لا؟». Read by `amr`, `amr_mixed`, `command_intended_usage`, `command_nonverbal_usage`, `command_obligation_status`, `command_prophetic_act_usage`. -/
structure Lahham43 where
  qarina : Option (Option Usul.Hukm) := none
  perItemStatus : Option (Usul.Hukm) := none
  intendedReading : Option (Usul.CommandSchemata.IntendedUseReading) := none
  intended : Option (Usul.CommandSchemata.IntendedRuling) := none
  nonverbalReading : Option (Usul.CommandSchemata.NonverbalReading) := none
  commandForm : Option (Usul.CommandSchemata.NonverbalForm) := none
  obligationReading : Option (Usul.CommandSchemata.ObligationReading) := none
  expression : Option (Usul.CommandSchemata.ObligationExpression) := none
  propheticActReading : Option (Usul.CommandSchemata.PropheticActReading) := none
  imitationEstablished : Option (Bool) := none

/-- Ibn al-Laḥḥām 52 «المفرد المحلى بالألف واللام يقتضى العموم إذا لم تكن هناك قرينة عهد.». Read by `haml_ala_adna`. -/
structure Lahham52 where
  unspecified : Option (Bool) := none
  ranked : Option (Bool) := none

/-- Ibn al-Laḥḥām 61 «إذا ورد دليل بلفظ عام مستقبل ولكن على سبب خاص فهل العبرة بعموم اللفظ أم بخصوص السبب؟». Read by `umum_lafz`. -/
structure Lahham61 where
  inOccasion : Option (Bool) := none
  generalWording : Option (Bool) := none

/-- Ibn Rajab 1 «الماء الجاري هل هو كالراكد أو كل جرية منه لها حكم الماء المنفرد.». Read by `running_water`. -/
structure Rajab1 where
  running : Option (Bool) := none

/-- Ibn Rajab 2 «شعر الحيوان في حكم المنفصل عنه لا في حكم المتصل، وكذلك الظفر.». Read by `hair_detached`. -/
structure Rajab2 where
  hairOrNail : Option (Bool) := none

/-- Ibn Rajab 3 «من وجبت عليه عبادة فأتى بما لو اقتصر على ما دونه لأجزأه هل يوصف الكل بالوجوب أو قدر الإجزاء منه.». Read by `excess_in_following`, `excess_over_sufficient`. -/
structure Rajab3 where
  separable : Option (Bool) := none
  lightened : Option (Bool) := none
  following : Option (Bool) := none

/-- Ibn Rajab 4 «العبادات كلها سواء كانت بدنية أو مالية أو مركبة منهما لا يجوز تقديمها على سبب وجوبها ويجوز تقديمها بعد سبب الوجوب وقبل الوجوب أو قبل شرط الوجوب ويتفرع على ذلك مسائل كثيرة: (منها) الطهارة سبب وجوبها الحدث وشرط الوجوب فعل …». Read by `advance_after_cause`. -/
structure Rajab4 where
  causePresent : Option (Bool) := none

/-- Ibn Rajab 5 «من عجل عبادة قبل وقت الوجوب ثم جاء وقت الوجوب وقد تغير الحال بحيث لو فعل المعجل في وقت الوجوب لم يجزئه فهل تجزئه أم لا؟». Read by `advanced_kaffara_at_obligation`, `advanced_worship`. -/
structure Rajab5 where
  dueAtPerformance : Option (Bool) := none
  kaffaraChanged : Option (Bool) := none

/-- Ibn Rajab 9 «في العبادات الواقعة على وجه محرم، إن كان التحريم عائدا إلى ذات العبادة على وجه يختص بها لم يصح، وإن كان عائدا إلى شرطها فإن كان على وجه يختص بها فكذلك أيضا، وإن كان لا يختص بها ففي الصحة روايتان أشهرهما عدمها، وإن عاد …». Read by `prohibited_worship`. -/
structure Rajab9 where
  target : Option (Usul.Refinements.Prohibited) := none

/-- Ibn Rajab 10 «الألفاظ المعتبرة في العبادات والمعاملات (منها) ما يعتبر لفظه ومعناه وهو ms012 القرآن لإعجازه بلفظه ومعناه، فلا تجوز الترجمة عنه بلغة أخرى.». Read by `wording_in_other_tongue`, `wording_need_not_learn`. -/
structure Rajab10 where
  meaningOnly : Option (Bool) := none
  able : Option (Bool) := none
  needNotLearn : Option (Bool) := none

/-- Ibn Rajab 11 «من عليه فرض هل له أن يتنفل قبل أدائه بجنسه أم لا.». Read by `nafl_before_fard`. -/
structure Rajab11 where
  narrow : Option (Bool) := none
  financial : Option (Bool) := none

/-- Ibn Rajab 12 «المذهب أن العبادات الواردة على وجوه متعددة يجوز فعلها على جميع تلك الوجوه الواردة فيها من غير كراهة لبعضها وإن كان بعضها أفضل من بعض، لكن هل الأفضل المداومة على نوع منها أو فعل جميع الأنواع في أوقات شتى، ظاهر كلام …». Read by `combining_forms`. -/
structure Rajab12 where
  substitutes : Option (Bool) := none

/-- Ibn Rajab 14 «(القاعدة الرابعة عشر) : إذا وجد سبب إيجاب أو تحريم من أحد رجلين لا يعلم عينه منهما، فهل يلحق الحكم بكل منهما أو لا يلحق بواحد منهما شيء في المسألة خلاف ولها صور: (إحداها) إذا وجد اثنان منيا في ثوب ينامان فيه أو سمعا …». Read by `cause_from_one_of_two`. -/
structure Rajab14 where
  harmless : Option (Bool) := none

/-- Ibn Rajab 15 «إذا استصحبنا أصلا وأعملنا ظاهرا في طهارة شيء أو حله أو حرمته وكان لازم ذلك تغير أصل آخر يجب استصحابه أو ترك العمل بظاهر آخر ms020 يجب إعماله لم يلتفت إلى ذلك اللازم على الصحيح، ولذلك صور: منها) إذا استيقظ من نومه فوجد …». Read by `each_on_its_asl`. -/
structure Rajab15 where
  separateMatters : Option (Bool) := none

/-- Ibn Rajab 17 «إذا تقابل عملان أحدهما ذو شرف في نفسه ورفعة وهو واحد، والآخر ذو تعدد في نفسه وكثرة، فأيهما يرجح.». Read by `many_over_noble`. -/
structure Rajab17 where
  sameCost : Option (Bool) := none

/-- Ibn Rajab 19 «إمكان الأداء ليس بشرط في استقرار الواجبات بالشرع في الذمة على ظاهر المذهب ويندرج تحت ذلك صور: (منها) الطهارة فإذا وصل عادم الماء إلى الماء وقد ضاق الوقت فعليه أن يتطهر ويصلي بعد الوقت ذكره صاحب المغني.». Read by `settles_without_ability`. -/
structure Rajab19 where
  makingUp : Option (Bool) := none

/-- Ibn Rajab 20 «النماء المتولد من العين حكمه حكم الجزء، والمتولد من الكسب بخلافه على الصحيح.»; Ibn Rajab 21 «وقد يختص الولد من بين سائر النماء المتولد من العين بأحكام ويعبر عن ذلك بأن الولد هل هو كالجزء أو كالكسب؟». Read by `growth_from_substance`. -/
structure Rajab20 where
  fromSubstance : Option (Bool) := none

/-- Ibn Rajab 22 «العين المنغمرة في غيرها إذا لم يظهر أثرها فهل هي كالمعدومة حكما أو لا؟». Read by `khalt_as_shirka`, `mixed_haram_by_proportion`. -/
structure Khalt extends Istihlak where
  mixedSameKind : Option (Bool) := none
  indistinct : Option (Bool) := none
  lawfulMany : Option (Bool) := none

/-- Ibn Rajab 24 «من تعلق بماله حق واجب عليه فبادر إلى نقل الملك عنه صح، ثم إن كان الحق متعلقا بالمال نفسه لم يسقط وإن كان متعلقا بمالكه لمعنى زال بانتقاله عنه سقط، وإن كان لا يزول بانتقاله لم يسقط على الأصح، ويدخل تحت ذلك صور: (منها) لو …». Read by `right_after_transfer`. -/
structure Rajab24 where
  onProperty : Option (Bool) := none
  reasonCeases : Option (Bool) := none

/-- Ibn Rajab 25 «من ثبت له ملك عين ببينة أو إقرار فهل يتبعها ما يتصل بها أو تولد منها أم لا؟». Read by `follows_proven_ownership`. -/
structure Rajab25 where
  followsInSale : Option (Bool) := none

/-- Ibn Rajab 27 «: من أتلف نفسا أو أفسد عبادة لنفع يعود إلى نفسه فلا ضمان عليه، وإن كان النفع يعود إلى غيره فعليه الضمان.». Read by `benefit_to_other`. -/
structure Rajab27 where
  benefitsOther : Option (Bool) := none

/-- Ibn Rajab 28 «إذا حصل التلف من فعلين أحدهما مأذون فيه والآخر غير مأذون فيه وجب الضمان كاملا على الصحيح، وإن كان من فعلين غير مأذون فيهما فالضمان بينهما نصفين حتى لو كان أحدهما من فعل من لا يجب الضمان عليه لم يجب على الآخر أكثر من …». Read by `concurrent_causes`. -/
structure Rajab28 where
  otherActPermitted : Option (Bool) := none

/-- Ibn Rajab 29 «من سومح في مقدار يسير فزاد عليه فهل تنتفي المسامحة في الزيادة وحدها أو في الجميع فيه وجهان وللمسألة صور: (منها) : الوكيل في البيع مع الإطلاق يملك البيع بثمن المثل وبدونه بما يتغابن بمثله عادة فإذا باع بما لا يتغابن …». Read by `tolerance_exceeded`. -/
structure Rajab29 where
  atFault : Option (Bool) := none

/-- Ibn Rajab 30 «والوجوب فهل يعود إلى ملكه أم لا؟». Read by `failed_obligation_returns`. -/
structure Rajab30 where
  failedToCount : Option (Bool) := none

/-- Ibn Rajab 31 «من شرع في عبادة تلزم بالشروع ثم فسدت فعليه قضاؤها على صفة التي أفسدها سواء كانت واجبة في الذمة على تلك الصفة أو دونها ويتخرج على ذلك مسائل: (منها) إذا صلى المسافر خلف مقيم وفسدت صلاته فإنه يجب عليه قضاؤها تامة (ومنها) …». Read by `makeup_after_failure`. -/
structure Rajab31 where
  failure : Option (Usul.Refinements.MakeupFailure) := none

/-- Ibn Rajab 32 «يصح عندنا استثناء منفعة العين المنتقل ملكها من ناقلها مدة معلومة، ويتخرج على ذلك مسائل منها: المبيع إذا استثنى البائع منفعته مدة معلومة صح، وحكي فيه رواية أخرى بعدم الصحة.». Read by `benefit_exception`. -/
structure Rajab32 where
  knownPeriod : Option (Bool) := none
  toleratesUncertainty : Option (Bool) := none

/-- Ibn Rajab 33 «الاستثناء الحكمي هل هو كالاستثناء اللفظي أم تغتفر فيه الجهالة بخلاف اللفظي فيه وجهان، والصحيح عند صاحب المغني الصحة، وهو قياس المذهب، خلافا للقاضي، ويخرج على ذلك مسائل: منها: لو باعه أمة حاملا بحر وقلنا يصح استثناء …». Read by `implicit_exception`. -/
structure Rajab33 where
  implicit : Option (Bool) := none

/-- Ibn Rajab 34 «استحقاق منافع العبد بعقد لازم يمنع من سريان العتق إليها كالاستثناء في العقد وأولى ; لأن الاستثناء الحكمي أقوى، ولهذا يصح بيع العين المؤجرة والأمة المزوجة عند من لا يرى استثناء المنافع في العقد خلافا للشيخ تقي الدين في …». Read by `manumission_spread`. -/
structure Rajab34 where
  bindingContract : Option (Bool) := none

/-- Ibn Rajab 35 «من ملك منفعة عين بعقد ثم ملك العين بسبب آخر هل ينفسخ العقد الأول أم لا؟». Read by `benefit_then_thing`. -/
structure Rajab35 where
  perpetualCommutative : Option (Bool) := none

/-- Ibn Rajab 36 «من استأجر عينا ممن له ولاية الإيجار ثم زالت ولايته قبل انقضاء المدة فهل تنفسخ الإجارة؟». Read by `lease_after_authority`. -/
structure Rajab36 where
  succeedsLessor : Option (Bool) := none

/-- Ibn Rajab 37 «في توارد العقود المختلفة بعضها على بعض، وتداخل أحكامها وتندرج تحتها صور: منها: إذا رهنه شيئا ثم أذن له في الانتفاع به، فهل يصير عارية حالة الانتفاع أم لا؟». Read by `successive_by_binding`, `successive_contracts`. -/
structure Rajab37 where
  successive : Option (Bool) := none
  earlierBinding : Option (Bool) := none
  laterBinding : Option (Bool) := none

/-- Ibn Rajab 38 «فيما إذا وصل بألفاظ العقود ما يخرجها عن موضوعها فهل يفسد العقد بذلك أو يجعل كناية عما يمكن صحته على ذلك الوجه؟». Read by `words_out_of_nature`. -/
structure Rajab38 where
  otherContractPossible : Option (Bool) := none

/-- Ibn Rajab 39 «في انعقاد العقود بالكنايات واختلاف الأصحاب في ذلك.». Read by `contract_by_kinaya`. -/
structure Rajab39 where
  needsWitnessing : Option (Bool) := none

/-- Ibn Rajab 41 «إذا تعلق بعين حق تعلقا لازما فأتلفها من يلزمه الضمان] فهل يعود الحق إلى البدل المأخوذ من غير عقد آخر؟». Read by `right_to_substitute`. -/
structure Rajab41 where
  boundToThing : Option (Bool) := none

/-- Ibn Rajab 42 «في أداء الواجبات المالية وهي منقسمة إلى دين وعين فأما الدين فلا يجب أداؤه بدون مطالبة المستحق إذا كان آدميا حتى ذكر ابن عقيل في جواز السفر قبل المطالبة وجهين، وهذا ما لم يكن قراخاني له وقتا للوفاء فأما إن عين وقتا كيوم …». Read by `return_of_held_property`. -/
structure Rajab42 where
  heldByConsent : Option (Bool) := none
  guaranteed : Option (Bool) := none

/-- Ibn Rajab 43 «فيما يضمن من الأعيان بالعقد أو باليد القابض لمال غيره، لا يخلو إما يقبضه بإذنه أو بغير إذنه فإن قبضه بغير إذنه فإن استند إلى إذن شرعي كاللقطة لم يضمن وكذا إن استند إلى إذن عرفي كالمنقذ لمال غيره من التلف ونحوه وحكى في …». Read by `continued_holding`, `holding_after_contract_end`. -/
structure Rajab43 where
  withholds : Option (Bool) := none
  endedByHolder : Option (Bool) := none

/-- Ibn Rajab 46 «في العقود الفاسدة هل هي منعقدة أو لا؟». Read by `void_contract_concluded`. -/
structure Rajab46 where
  binding : Option (Bool) := none
  pervasive : Option (Bool) := none

/-- Ibn Rajab 47 «في ضمان المقبوض بالعقد الفاسد] ، كل عقد يجب الضمان في صحيحه يجب الضمان في فاسده وكل عقد لا يجب الضمان في صحيحه لا يجب الضمان في فاسده.». Read by `defective_compensation`. -/
structure Rajab47 where
  contractLiability : Option (Bool) := none

/-- Ibn Rajab 49 «القبض في العقود على قسمين: أحدهما: أن يكون من موجب العقد ومقتضاه كالبيع ms084 اللازم والرهن اللازم والهبة اللازمة والصداق وعوض الخلع فهذه العقود تلزم من غير قبض، وإنما القبض فيها من موجبات عقودها.». Read by `qabd_in_contracts`. -/
structure Rajab49 where
  qabdCompletes : Option (Bool) := none

/-- Ibn Rajab 50 «هل يتوقف الملك في العقود القهرية على دفع الثمن أو يقع بدونه مضمونا في الذمة هذا على ضربين: أحدهما: التملك الاضطراري كمن اضطر إلى طعام الغير ومنعه وقدر على أخذه فإنه يأخذه مضمونا سواء كان معه ثمن يدفعه في الحال أو لا لأن …». Read by `forced_acquisition`, `forced_acquisition_solvent`. -/
structure Rajab50 where
  acquisitionNecessity : Option (Bool) := none
  shufa : Option (Bool) := none
  solvent : Option (Bool) := none

/-- Ibn Rajab 51 «فيما يعتبر القبض لدخوله في ضمان مالكه وما لا يعتبر] له الملك يقع تارة بعقد وتارة بغير عقد والعقود نوعان: أحدهما عقود المعاوضات المحضة فينتقل الضمان فيها إلى من ينتقل الملك إليه بمجرد التمكن من القبض التام والحيازة إذا …». Read by `daman_without_qabd`. -/
structure Rajab51 where
  determined : Option (Bool) := none

/-- Ibn Rajab 52 «في التصرف في المملوكات قبل قبضها: وهي منقسمة إلى عقود وغيرها فالعقود نوعان: أحدهما: عقود المعاوضات وتنقسم إلى بيع وغيره، فأما المبيع فقالت طائفة من الأصحاب التصرف قبل القبض والضمان متلازمان فإن كان البيع مضمونا على …». Read by `disposal_before_qabd`, `disposal_before_qabd_debt`. -/
structure Rajab52 where
  mubham : Option (Bool) := none
  settled : Option (Bool) := none
  debtToThird : Option (Bool) := none

/-- Ibn Rajab 54 «من ثبت له حق في عين وسقط بتصرف غيره فيها، فهل يجوز للمتصرف فيها الإقدام على التصرف المسقط لحق غيره قبل استئذانه أم لا؟». Read by `disposal_over_anothers_right`. -/
structure Rajab54 where
  extinguishes : Option (Bool) := none

/-- Ibn Rajab 55 «من ثبت له حق التملك بفسخ أو عقد هل يكون تصرفه فسخا أم لا وهل ينفذ تصرفه أم لا؟». Read by `right_to_own_disposal`. -/
structure Rajab55 where
  causeComplete : Option (Bool) := none
  tieRemains : Option (Bool) := none

/-- Ibn Rajab 56 «شروط العقود من أهلية العاقد أو المعقود له أو عليه إذا وجدت مقترنة بها ولم يتقدم عليها هل يكتفى بها في صحتها أم لا بد من سبقها؟». Read by `concurrent_condition`. -/
structure Rajab56 where
  prior : Option (Bool) := none
  concurrent : Option (Bool) := none

/-- Ibn Rajab 57 «إذا تقارن الحكم ووجود المنع منه، فهل يثبت الحكم أم لا؟». Read by `ruling_with_bar`. -/
structure Rajab57 where
  withBar : Option (Bool) := none

/-- Ibn Rajab 58 «من تعلق به الامتناع من فعل هو متلبس به فبادر إلى الإقلاع عنه، هل ms127 يكون إقلاعه فعلا للممنوع منه أو تركا له فلا يترتب عليه شيء من أحكامه؟». Read by `desisting_at_once`. -/
structure Rajab58 where
  foresaw : Option (Bool) := none

/-- Ibn Rajab 59 «العقود لا ترد إلا على موجود بالفعل أو بالقوة، وأما الفسوخ فترد على المعدوم حكما واختيارا على الصحيح وقد دل عليه حديث المصراة حيث أوجب الشارع رد صاع التمر عوضا عن اللبن بعد تلفه وهو مما ورد العقد عليه فدل على أنه حكم …». Read by `annulment_on_nonexistent`, `annulment_without_return`. -/
structure Rajab59 where
  annulment : Option (Bool) := none
  defectReturn : Option (Bool) := none

/-- Ibn Rajab 61 «المتصرف تصرفا عاما على الناس كلهم من غير ولاية أحد معين وهو الإمام، هل يكون تصرفه عليهم بطريق الوكالة لهم أو بطريق الولاية؟». Read by `deputy_of_principal`, `deputy_of_qadi`. -/
structure Rajab61 where
  general : Option (Bool) := none
  ofQadi : Option (Bool) := none

/-- Ibn Rajab 62 «فيما ينعزل قبل العلم بالعزل، المشهور أن كل من ينعزل بموت أو عزل هل ينعزل بمجرد ذلك أم يقف عزله على علمه؟». Read by `removal_before_knowledge`. -/
structure Rajab62 where
  publicOffice : Option (Bool) := none

/-- Ibn Rajab 64 «من توقف نفوذ تصرفه أو سقوط الضمان أو الحنث عنه على الإذن فتصرف قبل العلم به ثم تبين أن الإذن كان موجودا هل يكون كتصرف المأذون له أو لا؟»; Ibn Rajab 65 «وهي من تصرف في شيء يظن أنه لا يملكه فتبين أنه كان يملكه، وفيها خلاف أيضا ويندرج تحتها صور: منها لو باع ملك أبيه بغير إذنه ثم تبين أن أباه كان قد مات ولا وارث له وفي صحة تصرفه وجهان ويقال روايتان.». Read by `unknown_condition`, `unknown_condition_in_fact`. -/
structure Rajab64 where
  knew : Option (Bool) := none
  liabilityOnly : Option (Bool) := none
  transactionAuthority : Option (Bool) := none

/-- Ibn Rajab 65 «وهي من تصرف في شيء يظن أنه لا يملكه فتبين أنه كان يملكه، وفيها خلاف أيضا ويندرج تحتها صور: منها لو باع ملك أبيه بغير إذنه ثم تبين أن أباه كان قد مات ولا وارث له وفي صحة تصرفه وجهان ويقال روايتان.». Read by `qisas_belongs_to_whom`. -/
structure Rajab65 where
  rightIsVictims : Option (Bool) := none

/-- Ibn Rajab 66 «ولو تصرف مستندا إلى سبب ثم تبين خطؤه فيه وأن السبب المعتمد غيره وهو موجود فهو نوعان: أحدهما: أن يكون الاستناد إلى ما ظنه صحيحا أيضا فالتصرف صحيح مثل أن يستدل على القبلة بنجم يظنه الجدي ثم تبين أنه نجم آخر مسامته.». Read by `mistaken_basis`. -/
structure Rajab66 where
  believedBasis : Option (Bool) := none
  actualBasis : Option (Bool) := none

/-- Ibn Rajab 68 «إيقاع العبادات أو العقود أو غيرهما مع الشك في شرط صحتها هل يجعلها كالمعلقة على تحقيق ذلك الشرط أم لا؟». Read by `hukm_against_own_ijtihad`, `taliq_al_bay`. -/
structure ShakkShartFuru extends ShakkShart where
  contradictsNass : Option (Bool) := none
  conditional : Option (Bool) := none
  knownToHold : Option (Bool) := none

/-- Ibn Rajab 91 «يضمن بالعقد وباليد الأموال المحضة المنقولة إذا وجد فيها النقل.». Read by `hand_liability`. -/
structure Rajab91 where
  propertyLike : Option (Bool) := none

/-- Ibn Rajab 93 «من قبض مغصوبا من غاصبه ولم يعلم أنه مغصوب فالمشهور عن الأصحاب أنه بمنزلة الغاصب في جواز تضمينه ما كان الغاصب يضمنه من عين ومنفعة ثم إن كان القابض قد دخل على ضمان عين أو منفعة استقر ضمانها عليه ولم يرجع ms272 على الغاصب …». Read by `taker_from_usurper`. -/
structure Rajab93 where
  enteredOnLiability : Option (Bool) := none

/-- al-Saʿdī Q9 «العرف والعادة يرجع إليه في كل حكم حكم به الشارع ولم يحده بحد»; Ibn Rajab 1 «الماء الجاري هل هو كالراكد أو كل جرية منه لها حكم الماء المنفرد.». Read by `ayman_by_urf`. -/
structure Sadi9 where
  customOneBody : Option (Bool) := none

/-- al-Saʿdī Q25 «تشرع القرعة إذا جهل المستحق وتعذرت القسمة»; Ibn Rajab 160 «تستعمل القرعة في تميز المستحق إذا ثبت الاستحقاق ابتداء لمبهم غير معين عند تساوي أهل الاستحقاق.». Read by `fay_tie_break`, `lots`. -/
structure Sadi25 where
  tieBreakCriteria : Option (Bool) := none
  entitledKnown : Option (Bool) := none
  divisible : Option (Bool) := none
  confusionCategory : Option (Bool) := none

/-- al-Saʿdī Q30 «الشركاء في الأملاك والحقوق والمنافع يلزم الممتنع منهم بما يعود على المشترك من الأمور الضرورية»; Ibn Rajab 76 «الشريكان في عين مال أو منفعة إذا كانا محتاجين إلى رفع مضرة أو إبقاء منفعة أجبر أحدهما على موافقة الآخر في الصحيح من المذهب وفي رواية أخرى إن أمكن أحدهما أن يستقل بدفع الضرر فعله ولم يجبر الآخر معه لكن إن أراد الآخر …». Read by `partners`. -/
structure Sadi30 where
  necessary : Option (Bool) := none
  consents : Option (Bool) := none

/-- al-Saʿdī Q32 «من أدى عن غيره واجباً رجع عليه»; Ibn Rajab 75 «فيمن يرجع بما أنفق على مال غيره بغير إذنه وهو نوعان: أحدهما: من أدى واجبا عن غيره والثاني: من أنفق على ما تعلق به حقه من مال غيره.». Read by `recourse`. -/
structure Sadi32 where
  gift : Option (Bool) := none
  owedByOther : Option (Bool) := none
  permission : Option (Bool) := none
  permissionUnobtainable : Option (Bool) := none

/-- al-Saʿdī Q35 «من سقطت عنه العقوبة لموجب ضوعف عليه الضمان»; Ibn Rajab 140 «من سقطت عنه العقوبة بإتلاف نفس أو طرف مع قيام المقتضى له لمانع فإنه يتضاعف عليه الغرم، ويتخرج على ذلك مسائل: منها: إذا قتل مسلم ذميا عمدا ضمنه بدية مسلم.». Read by `doubled`, `ghulul_forfeiture`. -/
structure Sadi35 where
  lapsed : Option (Bool) := none
  asGhulul : Option (Bool) := none

/-- al-Saʿdī Q40 «يجب فعل المأمور به كله، فإن قدر على بعضه وعجز عن باقيه وجب عليه فعل ما قدر عليه»; Ibn Rajab 8 «من قدر على بعض العبادة وعجز عن باقيها هل يلزمه الإتيان بما قدر عليه منها أم لا؟». Read by `partial_capability`. -/
structure Sadi40 where
  capableOfPart : Option (Bool) := none
  pureMeans : Option (Bool) := none

/-- al-Saʿdī Q41 «إذا اجتمعت عبادتان من جنس واحد تداخلت أفعالهما واكتفي عنهما بفعل واحد إذا كان مقصودهما واحداً»; Ibn Rajab 18 «إذا اجتمعت عبادتان من جنس في وقت واحد ليست إحداهما مفعولة على جهة القضاء ولا على طريق التبعية للأخرى في الوقت تداخلت أفعالهما، واكتفى فيهما بفعل واحد وهو على ضربين: (أحدهما) : أن يحصل له بالفعل الواحد العبادتان [جميعا] …». Read by `tadakhul`. -/
structure Sadi41 where
  actsSameKind : Option (Bool) := none
  samePurpose : Option (Bool) := none

/-- al-Saʿdī Q45 «من لا يعتبر رضاه في عقد أو فسخ لا يعتبر علمه»; Ibn Rajab 63 «وهي أن من لا يعتبر رضاه لفسخ عقد أو حله لا يعتبر علمه به ويندرج تحت ذلك مسائل: منها الطلاق ومنها الخلع فإنه يصح مع ms143 الأجنبي على المذهب سواء قيل هو فسخ أو طلاق ولنا وجه آخر أنه لا يصح مع الأجنبي إذا قلنا إنه فسخ …». Read by `knowledge`. -/
structure Sadi45 where
  consentRequired : Option (Bool) := none

/-- al-Saʿdī Q48 «الفعل الواحد ينبني بعضه على بعض مع الاتصال المعتاد»; Ibn Rajab 103 «الفعل الواحد يبنى بعضه على بعض مع الاتصال المعتاد ولا ينقطع بالتفرق اليسير ولذلك صور: (منها) مكاثرة الماء النجس القليل بالماء الكثير يعتبر له الاتصال المعتاد دون صب القلتين دفعة واحدة.». Read by `continuity`. -/
structure Sadi48 where
  customaryContinuity : Option (Bool) := none

/-- al-Saʿdī Q50 «يثبت تبعاً ما لا يثبت استقلالاً»; Ibn al-Laḥḥām 43 «الأمر المجرد عن قرينة هل يقتضى الوجوب أم لا؟»; Ibn Rajab 133 «يثبت تبعا ما لا يثبت استقلالا في مسائل: (منها) شهادة النساء بالولادة يثبت بها النسب ولا يثبت النسب بشهادتهن به استقلالا ومنها: شهادة النساء على إسقاط الجنين بالضربة يوجب الغرة إن سقط ميتا والدية إن سقط حيا.». Read by `residual_jawaz_after_sarf`, `tabaa`. -/
structure Sadi50 where
  sarf : Option (Bool) := none
  independentProof : Option (Bool) := none
  followsEstablished : Option (Bool) := none

/-- al-Saʿdī Q55 «لا عذر لمن أقر ولو ادعى غلطاً»; Ibn al-Laḥḥām 54 «النكرة في سياق النفي تعم سواء باشرها النافي نحو ما أحد قائم أو باشرها عاملها نحو ما قام أحد وسواء كان النافي نحو ما أو لم أو لن أو ليس أو غيرها.». Read by `right_for_or_against_self`. -/
structure Sadi55 where
  forHimself : Option (Bool) := none

/-- al-Saʿdī Q59 «النكرة في سياق النفي أو النهي أو الشرط تفيد العموم»; al-Saʿdī Q60 «من وما وأل وأي ومتى يدل كل واحد منها على العموم، وكذلك المفرد المضاف»; Ibn al-Laḥḥām 52 «المفرد المحلى بالألف واللام يقتضى العموم إذا لم تكن هناك قرينة عهد.»; Ibn al-Laḥḥām 53 «المفرد المضاف يعم هذا مذهبنا ونص عليه إمامنا تبعا لابن عباس وعلى رضى الله عنهما قاله صاحب المحصول ومختصر كلامه.»; Ibn al-Laḥḥām 54 «النكرة في سياق النفي تعم سواء باشرها النافي نحو ما أحد قائم أو باشرها عاملها نحو ما قام أحد وسواء كان النافي نحو ما أو لم أو لن أو ليس أو غيرها.». Read by `generality`. -/
structure Sadi59 where
  nounForm : Option (Usul.Sadi.NounForm) := none
  context : Option (Usul.Sadi.Context) := none
  ahd : Option (Bool) := none

end Usul.Typing.Qaida
