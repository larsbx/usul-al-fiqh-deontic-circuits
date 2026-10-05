import pytest

from usul_corpus.ocr import (
    Line,
    PageOCR,
    choose,
    clean_line,
    page_markdown,
    parse_tsv,
    quality,
)
from usul_corpus.openiti import parse_markdown
from usul_corpus.segment import segment_lines

HEADER = "level\tpage_num\tblock_num\tpar_num\tline_num\tword_num\tleft\ttop\twidth\theight\tconf\ttext"


def row(block, par, line, word, conf, text):
    return f"5\t1\t{block}\t{par}\t{line}\t{word}\t0\t0\t1\t1\t{conf}\t{text}"


TSV = "\n".join([
    HEADER,
    "4\t1\t1\t1\t1\t0\t0\t0\t1\t1\t-1\t",                 # line container, no text
    row(1, 1, 1, 1, 92.0, "القاعدة"),
    row(1, 1, 1, 2, 88.0, "الأولى"),
    row(1, 1, 2, 1, 40.0, "النية"),
    row(1, 1, 2, 2, 50.0, "شرط"),
    row(2, 1, 1, 1, 95.0, "  "),                          # whitespace-only word dropped
])


def test_parse_tsv_groups_words_into_lines_in_logical_order():
    lines = parse_tsv(TSV)
    assert [l.text for l in lines] == ["القاعدة الأولى", "النية شرط"]
    assert [l.conf for l in lines] == [90.0, 45.0]


@pytest.mark.parametrize(
    "raw, expected",
    [
        ("ﺍﻟﻘﺎﻋﺪﺓ", "القاعدة"),                  # presentation forms → base letters (NFKC)
        ("قال» ثم", "قال، ثم"),                 # » glued to a word is the OCR'd Arabic comma
        ("«ابدأ بنفسك»", "«ابدأ بنفسك»"),         # real guillemets stay
        ("جزء من الماء", "جزء من الماء"),         # genuine final hamza is untouched
        ("الفقهی", "الفقهي"),                   # Persian yeh → Arabic yeh
        ("  ‏ ", ""),
    ],
)
def test_clean_line(raw, expected):
    assert clean_line(raw) == expected


def test_quality_reports_mean_and_low_confidence_share():
    q = quality((Line("a", 90.0), Line("b", 50.0), Line("c", 70.0)), low=60.0)
    assert q == {"mean_conf": 70.0, "low_conf_lines": 1, "lines": 3}


def test_choose_takes_highest_mean_confidence_per_page():
    a = PageOCR(7, "fast", (Line("x", 80.0),))
    b = PageOCR(7, "best", (Line("y", 85.0),))
    assert choose((a, b)).engine == "best"
    assert choose((b, a)).engine == "best"
    empty = PageOCR(7, "best", ())
    assert choose((empty, a)).engine == "fast"


def test_page_markdown_round_trips_through_reader_and_line_segmenter():
    pages = (
        PageOCR(1, "best", (Line("مقدمة", 90.0),)),
        PageOCR(2, "best", (Line("القاعدة الأولى", 90.0), Line("النية شرط", 80.0))),
        PageOCR(3, "fast", (Line("القاعدة الثانية", 90.0), Line("اليقين لا يزول بالشك", 80.0))),
    )
    md = "".join(page_markdown(p) for p in pages)
    assert md.splitlines()[-1] == "PageV01P003"
    units = segment_lines(md, marker="القاعدة")
    assert [(u.number, u.page) for u in units] == [(1, (1, 2)), (2, (1, 3))]
    assert units[1].statement == "اليقين لا يزول بالشك"
    assert parse_markdown(md) == ()  # OCR text has no ### headers; segmentation is line-based


def test_schema_engine_enum_matches_pinned_models():
    import json
    from pathlib import Path

    from usul_corpus.ocr import MODELS

    schema = json.loads((Path(__file__).parents[2] / "schemas" / "corpus_registry.schema.json").read_text())
    enum = schema["$defs"]["witness"]["properties"]["ocr"]["properties"]["engines"]["items"]["enum"]
    assert sorted(enum) == sorted(MODELS)


def test_is_noise_drops_lines_with_too_little_arabic():
    from usul_corpus.ocr import is_noise

    assert is_noise("|") and is_noise("أ ) 20 0") and is_noise("e")
    assert not is_noise("القاعدة الرابعة")
    assert not is_noise("قال الله تعالى : « فاتقوا الله ما استطعتم »")


def test_strip_running_heads_removes_lines_repeated_across_pages():
    from usul_corpus.ocr import strip_running_heads

    title = "القواعد والأصول الجامعة"
    pages = tuple(
        PageOCR(n, "best", (Line(title, 90.0), Line(f"نص الصفحة رقم {n}", 80.0)))
        for n in range(1, 6)
    ) + (PageOCR(6, "best", (Line("القاعدة الأولى", 90.0),)),)
    out = strip_running_heads(pages, min_share=0.5)
    assert [l.text for p in out for l in p.lines] == [f"نص الصفحة رقم {n}" for n in range(1, 6)] + ["القاعدة الأولى"]


def test_frame_box_crops_inside_a_decorative_border():
    from usul_corpus.ocr import frame_box

    # 1000 columns: margin, 60-px border band (density 0.4), text (≤ 0.1), border, margin
    cols = [0.0] * 30 + [0.4] * 60 + [0.05] * 820 + [0.4] * 60 + [0.0] * 30
    x0, x1 = frame_box(cols, pad=5)
    assert (x0, x1) == (95, 905)


def test_frame_box_leaves_unframed_pages_alone_and_ignores_text_runs_outside_the_zone():
    from usul_corpus.ocr import frame_box

    plain = [0.0] * 50 + [0.08] * 900 + [0.0] * 50
    assert frame_box(plain) == (0, 1000)
    dense_text = [0.0] * 200 + [0.4] * 100 + [0.05] * 700        # dense run at 20–30%: outside the 12% zone
    assert frame_box(dense_text) == (0, 1000)


def test_frame_box_bridges_short_dips_inside_a_border_band():
    from usul_corpus.ocr import frame_box

    # measured on PDF p. 28: a zigzag band with two 2–3 px dips below the density threshold
    rows = [0.0] * 135 + [0.4] * 30 + [0.2] * 2 + [0.4] * 14 + [0.2] * 3 + [0.4] * 7 + [0.02] * 2600
    y0, _ = frame_box(rows, pad=20)
    assert y0 == 191 + 20
