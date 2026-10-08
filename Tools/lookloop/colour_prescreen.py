#!/usr/bin/env python3
"""Colour-only screening against stored human grades. Never a grade or a gate.

Fits one linear model per grader to mean-RGB distance from the first approved
mock in stored signals. Reference: house-contrast-v1 hero images (signal target),
style-b-calibration-v2 calibration closeness (human response). Whole-frame colour
cannot measure shape, materials, seasons or the six visual aspects.
"""
import argparse
import json
import math
from pathlib import Path


def feature(signals):
    current = signals.get('current', {}).get('rgbMean')
    targets = signals.get('targets') or []
    target = targets[0].get('rgbMean') if targets else None
    if not current or not target or len(current) != 3 or len(target) != 3:
        return None
    if any(type(v) not in (int, float) or not math.isfinite(v) for v in current + target):
        return None
    return math.sqrt(sum((a-b)**2 for a, b in zip(current, target)))


def observations(docs):
    found = {}
    for path in sorted(docs.rglob('grades.json')):
        doc = json.loads(path.read_text())
        for view, entry in doc.get('views', {}).items():
            add(found, doc.get('run', {}).get('stamp', str(path.relative_to(docs))), view,
                entry.get('grade') or {}, entry.get('signals') or {}, str(path.relative_to(docs)))
    for path in sorted(docs.rglob('evidence.json')):
        signals_path = path.parent / 'signals.json'
        if not signals_path.exists():
            continue
        doc, signals = json.loads(path.read_text()), json.loads(signals_path.read_text())
        for view in doc.get('lookGate', {}).get('heroes', {}):
            grade_path = path.parent / f'{view}.json'
            if grade_path.exists():
                add(found, doc.get('run', {}).get('stamp', str(path.parent.relative_to(docs))), view,
                    json.loads(grade_path.read_text()), signals.get(view, {}), str(grade_path.relative_to(docs)))
    return list(found.values())


def add(found, run, view, grade, signals, source):
    x = feature(signals)
    y = (grade.get('calGap') or {}).get('closeness')
    grader = grade.get('grader')
    if x is not None and grader and type(y) in (int, float) and math.isfinite(y) and 1 <= y <= 5:
        found[(run, view, grader)] = dict(run=run, view=view, grader=grader, x=x, y=y, source=source)


def linear(rows):
    mx = sum(r['x'] for r in rows)/len(rows)
    my = sum(r['y'] for r in rows)/len(rows)
    denom = sum((r['x']-mx)**2 for r in rows)
    slope = sum((r['x']-mx)*(r['y']-my) for r in rows)/denom if denom else 0.0
    return my-slope*mx, slope


def fit(rows):
    result = {'kind': 'SCREEN ONLY — never a grade or gate', 'feature': 'RGB mean distance to first approved mock', 'models': {}}
    for grader in sorted({r['grader'] for r in rows}):
        group = [r for r in rows if r['grader'] == grader]
        a, b = linear(group)
        errors = [a+b*r['x']-r['y'] for r in group]
        validation = []
        # Keep all observations of the same view together to avoid repeated-view leakage.
        for view in sorted({r['view'] for r in group}):
            train = [r for r in group if r['view'] != view]
            if not train:
                continue
            aa, bb = linear(train)
            validation.extend(aa+bb*r['x']-r['y'] for r in group if r['view'] == view)
        informative = len({r['y'] for r in group}) > 1 and len({r['x'] for r in group}) > 1 and len({r['view'] for r in group}) >= 3
        result['models'][grader] = dict(n=len(group), intercept=a, slope=b,
            trainingMAE=sum(abs(e) for e in errors)/len(errors),
            trainingRMSE=math.sqrt(sum(e*e for e in errors)/len(errors)),
            leaveViewOutMAE=sum(abs(e) for e in validation)/len(validation) if validation else None,
            status='experimental screen' if informative else 'INSUFFICIENT VARIATION — no predictive screening',
            informative=informative, featureRange=[min(r['x'] for r in group), max(r['x'] for r in group)],
            scoreRange=[min(r['y'] for r in group), max(r['y'] for r in group)], sources=group)
    return result


def screen(model, signals, grader):
    m, x = model['models'].get(grader), feature(signals)
    if not m or not m['informative'] or x is None:
        return {'status': 'UNAVAILABLE', 'reason': 'missing evidence or insufficient fitting variation', 'isGrade': False}
    if not m['featureRange'][0] <= x <= m['featureRange'][1]:
        return {'status': 'OUTSIDE FIT RANGE', 'isGrade': False}
    return {'status': 'SCREEN ONLY', 'estimate': m['intercept'] + m['slope']*x,
            'validationMAE': m['leaveViewOutMAE'], 'isGrade': False}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--docs', type=Path, default=Path(__file__).resolve().parents[2]/'docs/lookloop')
    args = parser.parse_args()
    print(json.dumps(fit(observations(args.docs)), indent=2, allow_nan=False))


if __name__ == '__main__':
    main()
