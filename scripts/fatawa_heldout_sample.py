"""Freeze-checked, answer-level sampling. Does not annotate or query the oracle."""
import argparse
import gzip
import hashlib
import json
from pathlib import Path


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def sample(root, answers_path):
    plan = json.loads((root / 'corpus/fatawa/heldout/protocol.json').read_text())
    for path, expected in plan['frozen_sha256'].items():
        if digest(root / path) != expected:
            raise ValueError('frozen input changed: ' + path)
    if digest(answers_path) != plan['answers_sha256']:
        raise ValueError('answer corpus does not match pinned LFS bytes')
    excluded = set(plan['excluded_answer_ids'])
    pools = {e: [] for e in plan['question_keywords']}
    seen = set()
    with gzip.open(answers_path, 'rt', encoding='utf-8') as stream:
        for line in stream:
            a = json.loads(line)
            key = a['id']
            if key in seen:
                raise ValueError('duplicate answer: ' + key)
            seen.add(key)
            if key in excluded:
                continue
            text = (a.get('title') or '') + '\n' + (a.get('question') or '')
            eligible = [e for e, words in plan['question_keywords'].items()
                        if any(w in text for w in words)]
            if eligible:
                # Assign overlapping retrieval candidates once, without consulting answers.
                encoder = min(eligible, key=lambda e: hashlib.sha256(
                    (plan['seed'] + ':assign:' + key + ':' + e).encode()).hexdigest())
                score = hashlib.sha256((plan['seed'] + ':sample:' + key).encode()).hexdigest()
                pools[encoder].append((score, key, a['url']))
    return {'status': 'unannotated', 'protocol_sha256': digest(root / 'corpus/fatawa/heldout/protocol.json'),
            'pools': {e: {'eligible_answers': len(rows), 'selected': [
                {'answer_id': key, 'url': url, 'rank_hash': score}
                for score, key, url in sorted(rows)[:plan['answers_per_encoder']]]}
                for e, rows in sorted(pools.items())}}


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root', type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument('--answers', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    result = sample(args.root, args.answers)
    with args.output.open('x', encoding='utf-8') as stream:
        json.dump(result, stream, ensure_ascii=False, indent=2)
        stream.write('\n')
