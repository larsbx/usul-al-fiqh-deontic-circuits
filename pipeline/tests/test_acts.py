from usul_corpus.acts import act_of, antonyms, stems
from usul_corpus.labels import cues, normalize_ar


def act(text, i=0):
    t = normalize_ar(text)
    return act_of(t, cues(t)[i])


def test_stems_strip_clitics_and_imperfect_prefix():
    assert stems("وبيع الخمر") == {"بيع", "خمر"} and stems("يبيعها") == {"بيع"}


def test_verbal_cue_rules_on_its_complement_with_its_addressee():
    a = act("لا يجوز للمسلم ان يبيع الخمر")
    assert a["addressee"] == "مسلم" and {"بيع", "خمر"} <= set(a["stems"])
    assert act("واجب على الرجال")["addressee"] == "رجال"
    assert act("وليس بواجب عليهن")["addressee"] == "هن"


def test_nominal_cue_rules_on_its_subject():
    assert act("الغصب محرم")["stems"] == ["غصب"]


def test_antonym_pairs():
    assert antonyms({"عدل"}, {"فضيل"}) and antonyms({"متنع"}, {"بقى"}) and not antonyms({"بيع"}, {"خمر"})
