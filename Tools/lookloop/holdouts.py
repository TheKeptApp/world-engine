"""Report the frozen A3 views; missing evidence never becomes a score."""
import math


def score(grade):
    value = ((grade or {}).get('calGap') or {}).get('closeness')
    return value if type(value) in (int, float) and math.isfinite(value) and 1 <= value <= 5 else None


def report(rows, contract):
    grades = {view: grade for view, grade, *_ in rows}
    focus, held = {}, {}
    for view in contract['views']:
        target = focus if view.get('area') == 'sloans-lake' else held
        target[view['id']] = score(grades.get(view['id']))
    pending = {v['area']: v['status'] for v in contract.get('pendingHoldouts', [])}
    return {'sloansScores': focus, 'holdoutScores': held, 'pendingHoldouts': pending,
            'coverage': 'PENDING' if pending or any(v is None for v in [*focus.values(), *held.values()]) else 'RECORDED',
            'metric': 'human calibration closeness /5; coverage is not gate clearance'}


def cells(result):
    def cell(values):
        return '; '.join(f'{view}: {value}/5' if value is not None else f'{view}: PENDING' for view, value in values.items()) or 'PENDING'
    return cell(result['sloansScores']), cell(result['holdoutScores']) + ''.join(
        f'; {area}: PENDING' for area in result['pendingHoldouts'])
