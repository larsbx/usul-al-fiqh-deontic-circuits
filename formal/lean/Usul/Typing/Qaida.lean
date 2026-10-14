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

/-- Ibn Rajab 127 «إذا استند إتلاف أموال الآدميين ونفوسهم إلى مباشرة وسبب تعلق الضمان بالمباشرة دون
السبب إلا إذا كانت المباشرة مبنية على السبب وناشئة عنه»: an itlāf (Q13 ⊔ Q36) resting on a direct
act and a cause; whether the direct act arises from the cause, and whether it has transgression. -/
structure Mubashara extends ItlafHal, ItlafQasd where
  arisingFromSabab : Option Bool := none
  udwanInMubashara : Option Bool := none

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

/-- Ibn Rajab 10 «الألفاظ المعتبرة في العبادات والمعاملات (منها) ما يعتبر لفظه ومعناه وهو القرآن لإعجازه بلفظه ومعناه، فلا تجوز الترجمة عنه بلغة أخرى.». Read by `wording_in_other_tongue`, `wording_need_not_learn`. -/
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

/-- Ibn Rajab 15 «إذا استصحبنا أصلا وأعملنا ظاهرا في طهارة شيء أو حله أو حرمته وكان لازم ذلك تغير أصل آخر يجب استصحابه أو ترك العمل بظاهر آخر يجب إعماله لم يلتفت إلى ذلك اللازم على الصحيح، ولذلك صور: منها) إذا استيقظ من نومه فوجد …». Read by `each_on_its_asl`. -/
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

/-- Ibn Rajab 49 «القبض في العقود على قسمين: أحدهما: أن يكون من موجب العقد ومقتضاه كالبيع اللازم والرهن اللازم والهبة اللازمة والصداق وعوض الخلع فهذه العقود تلزم من غير قبض، وإنما القبض فيها من موجبات عقودها.». Read by `qabd_in_contracts`. -/
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

/-- Ibn Rajab 58 «من تعلق به الامتناع من فعل هو متلبس به فبادر إلى الإقلاع عنه، هل يكون إقلاعه فعلا للممنوع منه أو تركا له فلا يترتب عليه شيء من أحكامه؟». Read by `desisting_at_once`. -/
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

/-- Ibn Rajab 93 «من قبض مغصوبا من غاصبه ولم يعلم أنه مغصوب فالمشهور عن الأصحاب أنه بمنزلة الغاصب في جواز تضمينه ما كان الغاصب يضمنه من عين ومنفعة ثم إن كان القابض قد دخل على ضمان عين أو منفعة استقر ضمانها عليه ولم يرجع على الغاصب …». Read by `taker_from_usurper`. -/
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

/-- al-Saʿdī Q45 «من لا يعتبر رضاه في عقد أو فسخ لا يعتبر علمه»; Ibn Rajab 63 «وهي أن من لا يعتبر رضاه لفسخ عقد أو حله لا يعتبر علمه به ويندرج تحت ذلك مسائل: منها الطلاق ومنها الخلع فإنه يصح مع الأجنبي على المذهب سواء قيل هو فسخ أو طلاق ولنا وجه آخر أنه لا يصح مع الأجنبي إذا قلنا إنه فسخ …». Read by `knowledge`. -/
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

/-! ## Ibn Rajab's qawāʿid read by the parallel shards (RajabA1–A12) -/

/-- Ibn Rajab 53 «من تصرف في عين تعلق بها حق لله تعالى أو لآدمي معين إن كان الحق مستقرا فيها بمطالبة من له الحق بحقه أو يأخذه بحقه لم ينفذ التصرف ولم يوجد سوى تعلق الحق لاستيفائه منها صح التصرف على ظاهر المذهب، وقياس قول أبي بكر لا يصح …». Read by `attached_right_disposal`. -/
structure Rajab53 where
  demanded : Option (Bool) := none
  fixedInAyn : Option (Bool) := none

/-- Ibn Rajab 60 «التفاسخ في العقود الجائزة متى تضمن ضررا على أحد المتعاقدين أو غيرهما ممن له تعلق بالعقد لم يجز ولم ينفذ إلا أن يمكن استدراك الضرر بضمان أو نحوه فيجوز على ذلك الوجه.». Read by `rescission_harm`. -/
structure Rajab60 where
  harm : Option (Bool) := none
  remediable : Option (Bool) := none

/-- Ibn Rajab 67 «من استحق الرجوع بعين أو دين بفسخ أو غيره وكان قد رجع إليه ذلك الحق بهبة أو إبراء ممن يستحق عليه الرجوع فهل يستحق الرجوع ببدله أم لا؟». Read by `recourse_after_return`. -/
structure Rajab67 where
  returnedByGift : Option (Bool) := none

/-- Ibn Rajab 69 «العقد الوارد على عمل معين إما أن يكون لازما ثابتا في الذمة بعوض كالإجارة فالواجب تحصيل ذلك العمل ولا يتعين أن يعمله المعقود معه إلا بشرط أو قرينة تدل عليه وإما أن يكون غير لازم وإنما يستفاد التصرف فيه بمجرد الإذن …». Read by `delegating_work`. -/
structure Rajab69 where
  bindingQ69 : Option (Bool) := none
  personalRequired : Option (Bool) := none
  permissionIndicated : Option (Bool) := none

/-- Ibn Rajab 71 «فيما يجوز الأكل من الأموال بغير إذن مستحقيها وهي نوعان: مملوك تعلق به حق الغير ومملوك للغير.». Read by `eating_without_permission`. -/
structure Rajab71 where
  necessityQ71 : Option (Bool) := none
  wardWilaya : Option (Bool) := none
  compensatedOtherwise : Option (Bool) := none
  unguardedCraved : Option (Bool) := none

/-- Ibn Rajab 72 «اشتراط النفقة والكسوة في العقود يقع على وجهين معاوضة وغير معاوضة فأما المعاوضة فتقع في العقود اللازمة ويملك فيها الطعام والكسوة كما يملك غيرهما من الأموال المعاوض بها فإن وقع التفاسخ قبل انقضاء المدة رجع بما عجل منها …». Read by `nafaqa_stipulated_in_contract`, `nafaqa_taken_owned`. -/
structure Rajab72 where
  muawada : Option (Bool) := none
  bindingContractQ72 : Option (Bool) := none
  spentInPurpose : Option (Bool) := none

/-- Ibn Rajab 73 «اشتراط نفع أحد المتعاقدين في العقد على ضربين: أحدهما: أن يكون استئجارا له مقابلا بعوض فيصح على ظاهر المذهب كاشتراط المشتري على البائع خياطة الثوب أو قصارته أو حمل الحطب ونحوه، ولذلك يزداد به الثمن.». Read by `benefit_condition_against_compensation`. -/
structure Rajab73 where
  againstCompensation : Option (Bool) := none

/-- Ibn Rajab 74 «فيمن يستحق العوض عن عمل بغير شرط وهو نوعان: أحدهما: أن يعمل العمل ودلالة حاله تقتضي المطالبة بالعوض.». Read by `wage_without_stipulation`. -/
structure Rajab74 where
  professional : Option (Bool) := none
  publicOrRescue : Option (Bool) := none

/-- Ibn Rajab 77 «من اتصل ملكه بملك غيره متميزا عنه وهو تابع له ولم يمكن فصله منه بدون ضرر يلحقه وفي إبقائه على الشركة ضرر لم يفصله مالكه فلمالك الأصل أن يتملكه بالقيمة من مالكه ويجبر المالك على القبول.». Read by `attached_takeover_at_value`. -/
structure Rajab77 where
  wrongful : Option (Bool) := none
  separableWithoutHarm : Option (Bool) := none

/-- Ibn Rajab 78 «من أدخل النقص على ملك غيره لاستصلاح تملكه وتخلصه من ملك غيره فإن لم يكن ممن دخل النقص عليه بتفريط باشتغال ملكه بملك غيره فالضمان على من أدخل النقص، وإن كان منه تفريط فلا ضمان على من أدخل النقص وكذا إن وجد ممن دخل النقص …». Read by `rescue_loss_liability`. -/
structure Rajab78 where
  causesLoss : Option (Bool) := none
  suffererNegligent : Option (Bool) := none
  emptyingPermitted : Option (Bool) := none

/-- Ibn Rajab 79 «الزرع النابت في أرض الغير بغير إذن صحيح أقسام] [القسم الأول أن يزرع عدوانا محضا غير مستند إلى إذن بالكلية] : القسم الأول أن يزرع عدوانا محضا غير مستند إلى إذن بالكلية، وهو زرع الغاصب فالمذهب أن المالك إن أدركه …». Read by `crop_without_valid_permission`. -/
structure Rajab79 where
  validPermission : Option (Bool) := none

/-- Ibn Rajab 80 «ما تكرر حمله من أصول البقول والخضراوات هل هو ملحق بالزرع أو بالشجر] ؟». Read by `repeat_bearing_roots_as_trees`. -/
structure Rajab80 where
  repeatedBearing : Option (Bool) := none

/-- Ibn Rajab 81 «النماء المتصل في الأعيان المملوكة العائدة إلى من انتقل الملك عنه بالمفسوخ تتبع الأعيان على ظاهر المذهب عند أصحابنا والمنصوص عن أحمد أنه لا يتبع وهو الذي ذكره الشيرازي في المبهج، ولم يحك فيه خلافا وهو اختيار ابن عقيل صرح …». Read by `attached_growth_follows`, `cut_sale_left_to_ripen`. -/
structure Rajab81 where
  revertsToTransferor : Option (Bool) := none
  securityOrLiability : Option (Bool) := none
  leftUntilRipe : Option (Bool) := none

/-- Ibn Rajab 90 «الأيدي المستولية على مال الغير بغير إذنه ثلاثة يد يمكن أن يثبت باستيلائها الملك فينتفي الضمان عما يستولي عليه سواء حصل الملك به أو لم يحصل ويد لا يثبت لها الملك وينتفي عنها الضمان ويد لا يثبت لها الملك ويثبت عليها …». Read by `seizing_hand_liable`. -/
structure Rajab90 where
  canOwnBySeizure : Option (Bool) := none
  transgressing : Option (Bool) := none

/-- Ibn Rajab 92 «هل تثبت يد الضمان مع ثبوت يد المالك أم لا؟». Read by `hand_with_owner_liable`. -/
structure Rajab92 where
  ownerControlRemoved : Option (Bool) := none

/-- Ibn Rajab 94 «قبض مال الغير من يد قابضه بحق بغير إذن مالكه إن كان يجوز له إقباضه فهو أمانة عند الثاني إن كان الأول أمينا وإلا فلا، وإن لم يك إقباضه جائزا فالضمان عليهما، ويتخرج وجه آخر ألا يضمن غير الأول ويندرج تحت ذلك صور: …». Read by `second_receiver_liable`. -/
structure Rajab94 where
  handoverPermitted : Option (Bool) := none
  firstTrustee : Option (Bool) := none

/-- Ibn Rajab 95 «من أتلف مال غيره وهو يظن أنه له أو تصرف فيه يظن لنفسه ولاية عليه ثم يتبين خطأ ظنه فإن كان مستندا إلى سبب ظاهر من غيره ثم تبين خطأ المتسبب أو أقر بتعمده للجناية ضمن المتسبب وإن كان مستندا إلى اجتهاد مجرد كمن دفع مالا تحت …». Read by `error_actor_liable`. -/
structure Rajab95 where
  externalCause : Option (Bool) := none
  basisVoid : Option (Bool) := none
  rulingOverturned : Option (Bool) := none
  asOwner : Option (Bool) := none
  negligentQ95 : Option (Bool) := none

/-- Ibn Rajab 96 «من وجب عليه أداء عين مال فأداه عنه بغير إذنه هل تقع موقعه وينتفي الضمان عن المؤدي؟». Read by `performed_without_leave_not_owned`, `performed_without_leave_owned`. -/
structure Rajab96 where
  recipientDetermined : Option (Bool) := none
  wilaya : Option (Bool) := none
  distinct : Option (Bool) := none

/-- Ibn Rajab 97 «من بيده مال أو في ذمته دين يعرف مالكه ولكنه غائب يرجى قدومه، فليس له التصرف فيه بدون إذن الحاكم إلا أن يكون تافها فله الصدقة به عنه، نص عليه في مواضع، وإن كان قد آيس من قدومه بأن مضت مدة يجوز فيها أن تزوج امرأته ويقسم …». Read by `dispose_without_judge`. -/
structure Rajab97 where
  ownerKnown : Option (Bool) := none
  trivial : Option (Bool) := none
  despaired : Option (Bool) := none

/-- Ibn Rajab 98 «من ادعى شيئا ووصفه دفع إليه بالصفة إذا جهل ربه ولم يثبت عليه يد من جهة مالكه وإلا فلا.». Read by `handover_by_description`. -/
structure Rajab98 where
  described : Option (Bool) := none
  ownerUnknown : Option (Bool) := none
  ownerHand : Option (Bool) := none

/-- Ibn Rajab 99 «ما تدعوا الحاجة إلى الانتفاع به من الأعيان ولا ضرر في بذله لتيسيره وكثرة وجوده أو المنافع المحتاج إليها يجب بذله مجانا بغير عوض في الأظهر ويندرج تحت ذلك مسائل: (منها) الهر لا يجوز بيعه على أصح الروايتين وثبت في صحيح …». Read by `free_bestowal_of_needed_ayn`, `free_bestowal_of_needed_benefit`. -/
structure Rajab99 where
  needed : Option (Bool) := none
  harmlessQ99 : Option (Bool) := none

/-- Ibn Rajab 100 «الواجب بالنذر.». Read by `vowed_as_shar_obligation`. -/
structure Rajab100 where
  sharRuling : Option (Bool) := none
  mandubRuling : Option (Bool) := none

/-- Ibn Rajab 101 «من خير بين شيئين وأمكنه الإتيان بنصفيهما معا فهل يجزئه أم لا؟». Read by `split_halves_suffice`. -/
structure Rajab101 where
  commonUnit : Option (Bool) := none

/-- Ibn Rajab 102 «من أتى بسبب يفيد الملك أو الحل أو يسقط الواجبات على وجه محرم وكان مما تدعو النفوس إليه ألغى ذلك السبب وصار وجوده كالعدم ولم يترتب عليه أحكامه ويتخرج على ذلك مسائل كثيرة: منها) الفار من الزكاة قبل تمام الحول بتنقيص …». Read by `forbidden_cause_voided`, `hastened_right_forfeited`. -/
structure Rajab102 where
  forbiddenManner : Option (Bool) := none
  soulsDrawn : Option (Bool) := none
  hastenedForbidden : Option (Bool) := none

/-- Ibn Rajab 104 «الرضا بالمجهول قدرا أو جنسا أو وصفا هل هو رضا معتبر لازم؟». Read by `unknown_consent_binds`. -/
structure Rajab104 where
  vaguenessAdmitted : Option (Bool) := none

/-- Ibn Rajab 105 «في إضافة الإنشاءات والإخبارات إلى المبهمات: أما الإنشاءات فمنها العقود وهي أنواع: أحدها، عقود التمليكات المحضة كالبيع والصلح بمعناه وعقود التوثقات كالرهن والكفالة والتبرعات اللازمة بالعقد أو بالقبض بعده كالهبة والصدقة.». Read by `lot_distinguishes_hidden_entitled`, `shared_name_insha_valid`, `vague_insha_valid`, `vague_report_accepted`. -/
structure Rajab105 where
  specificInFact : Option (Bool) := none
  vagueValid : Option (Bool) := none
  intendedSpecific : Option (Bool) := none
  witnessingRequired : Option (Bool) := none
  bindingTransfer : Option (Bool) := none
  equalMixed : Option (Bool) := none
  religiousOrAgainstSelf : Option (Bool) := none

/-- Ibn Rajab 107 «تمليك المعدوم، والإباحة له نوعان: أحدهما: أن يكون بطريق الأصالة فالمشهور أنه لا يصح.». Read by `maadum_grant_valid`. -/
structure Rajab107 where
  byOrigin : Option (Bool) := none
  explicitInclusion : Option (Bool) := none
  objectEntails : Option (Bool) := none

/-- Ibn Rajab 108 «ما جهل وقوعه مترتبا أو متقارنا هل يحكم عليه بالتقارن أو بالتعاقب؟». Read by `unknown_order_judged_sequential`. -/
structure Rajab108 where
  knownSimultaneous : Option (Bool) := none
  knownSequential : Option (Bool) := none

/-- Ibn Rajab 109 «المنع من واحد مبهم من أعيان أو معين مشتبهة بأعيان يؤثر الاشتباه فيها المنع بمنع التصرف في تلك الأعيان قبل تمييزه، والمنع من الجمع يمنع من التصرف في القدر الذي يحصل به الجمع خاصة، فإن حصل الجمع دفعة واحدة منع من …». Read by `combination_bars_its_amount`, `common_amount_general`, `simultaneous_combination_voids`, `vague_one_bars_all`. -/
structure Rajab109 where
  combiningAmount : Option (Bool) := none
  barsCommonAmount : Option (Bool) := none
  hasPrecedence : Option (Bool) := none
  confusionEffective : Option (Bool) := none
  distinguished : Option (Bool) := none

/-- Ibn Rajab 110 «من ثبت له أحد أمرين فإن اختار أحدهما سقط الآخر، وإن أسقط أحدهما أثبت الآخر، وإن امتنع منهما فإن كان امتناعه ضررا على غيره استوفى له الحق الأصلي الثابت له إذا كان ماليا، وإن لم يكن حقا ثابتا سقط وإن كان الحق غير مالي …». Read by `other_option_stands`, `refusal_compelled_to_choose`, `refusal_exacted_for_him`, `refusal_right_falls`, `right_on_refuser_exacted`, `substitute_refusal_judged_by_original`. -/
structure Rajab110 where
  choseOne : Option (Bool) := none
  harmsOther : Option (Bool) := none
  financialQ110 : Option (Bool) := none
  established : Option (Bool) := none
  rightOnHim : Option (Bool) := none
  exactable : Option (Bool) := none
  refusedSubstitute : Option (Bool) := none

/-- Ibn Rajab 111 «إذا كان الواجب بسبب واحد أحد شيئين فقامت حجة بها أحدهما دون الآخر فهل يثبت أم لا؟». Read by `alternative_proven_alone`. -/
structure Rajab111 where
  proofEstablishesCause : Option (Bool) := none

/-- Ibn Rajab 112 «إذا اجتمع للمضطر محرمان كل منهما لا يباح بدون الضرورة وجب تقديم أخفهما مفسدة وأقلهما ضررا ; لأن الزيادة لا ضرورة إليها فلا يباح، ويتخرج على ذلك مسائل: (منها) إذا وجد المحرم صيدا وميتة فإنه يأكل الميتة نص عليه أحمد ; لأن …». Read by `necessity_spares_lighter`. -/
structure Rajab112 where
  heavier : Option (Bool) := none

/-- Ibn Rajab 113 «إذا وجدنا جملة ذات أعداد موزعة على جملة أخرى، فهل يتوزع أفراد الجمل الموزعة على أفراد الأخرى أو كل فرد على مجموع الجملة الأخرى، هذه على قسمين: الأول أن توجد قرينة تدل على تعيين أحد الأمرين فلا خلاف في ذلك.». Read by `distribution_each_over_whole`. -/
structure Rajab113 where
  qarinaOneToOne : Option (Bool) := none

/-- Ibn Rajab 114 «إطلاق الشركة هل يتنزل على المناصفة أو هو مبهم يفتقر إلى تفسير؟». Read by `unqualified_sharika_halves`. -/
structure Rajab114 where
  isIqrar : Option (Bool) := none

/-- Ibn Rajab 115 «الحقوق المشتركة بين اثنين فصاعدا نوعان: أحدهما: ما يقع استحقاق كل واحد بانفراده لجميع الحق ويتزاحمون فيه عند الاجتماع.». Read by `shared_right_accrues_to_rest`. -/
structure Rajab115 where
  eachEntitledWhole : Option (Bool) := none

/-- Ibn Rajab 116 «من استند تملكه إلى سبب مستقر لا يمكن إبطاله وتأخر حصول الملك عنه فهل ينعطف إحكام ملكه إلى أول وقت انعقاد السبب ويثبت إحكامه من حينئذ أم لا يثبت إلا من حين ثبوت الملك؟». Read by `ownership_relates_back`, `worship_ruled_from_start`. -/
structure Rajab116 where
  settledCause : Option (Bool) := none
  conditionWithinTime : Option (Bool) := none

/-- Ibn Rajab 117 «كل عقد معلق يختلف باختلاف حالين إذا وجد تعليقه في أحدهما ووقوعه في الآخر فهل يغلب عليه جانب التعليق أو جانب الوقوع في المسألة قولان إلا أن يقتضي اعتبار أحدهما إلى ما هو ممتنع شرعا فيلغي ويتفرع على ذلك مسائل: (منها) …». Read by `occurrence_state_governs`. -/
structure Rajab117 where
  suspensionBarred : Option (Bool) := none
  occurrenceBarred : Option (Bool) := none

/-- Ibn Rajab 118 «تعليق فسخ العقد وإبطاله لوجوده إن كان فيه مقصود معتبر شرعا صح وإلا لم يصح إذ لو صح لصار العقد غير مقصود في نفسه هذا مقتضى قواعد المذهب، ويتخرج على ذلك مسائل: (منها) إذا علق الطلاق بالنكاح فالمذهب المنصوص عن أحمد …». Read by `cancel_on_existence_valid`. -/
structure Rajab118 where
  legitimatePurpose : Option (Bool) := none

end Usul.Typing.Qaida
