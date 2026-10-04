"""Review app translations (TH / MY / ZH) against the English ARB with Claude.

Reads lib/l10n/app_<lang>.arb, sends each language together with the English
source to Claude, and writes a Markdown report for a human to review.
The ARB files are never modified — apply accepted suggestions by hand, then run
`flutter gen-l10n` and `flutter test`.

Setup (once):
    .venv\\Scripts\\pip install anthropic pydantic
    set ANTHROPIC_API_KEY=sk-ant-...

Usage:
    .venv\\Scripts\\python ppe_mobile_app\\tool\\review_translations.py
    .venv\\Scripts\\python ppe_mobile_app\\tool\\review_translations.py --langs th,zh
    .venv\\Scripts\\python ppe_mobile_app\\tool\\review_translations.py --dry-run
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from datetime import date
from pathlib import Path
from typing import Literal

APP_DIR = Path(__file__).resolve().parents[1]
L10N_DIR = APP_DIR / 'lib' / 'l10n'
DEFAULT_OUT = APP_DIR.parent / 'docs' / 'translation-review.md'
MODEL = 'claude-opus-5-5'

LANGUAGES = {
    'th': 'Thai',
    'my': 'Burmese (Myanmar)',
    'zh': 'Simplified Chinese',
}

PLACEHOLDER = re.compile(r'\{(\w+)')

SYSTEM_PROMPT = """You review the UI translations of "PPE SMART", a mobile app for requesting, \
approving and issuing personal protective equipment (PPE) in a factory. Users are factory \
workers, supervisors, store keepers, EHS (environment, health & safety) officers and admins; \
many workers read Thai, Burmese or Chinese as their first language.

For every key you get the English source and the current translation. Report only real problems:
- meaning: the translation says something different from the English, or drops information
- grammar: ungrammatical, wrong word order, wrong particles or classifiers, typos
- terminology: wrong or inconsistent safety/PPE terms (e.g. hard hat, respirator, safety harness, \
earplugs, lifespan, requisition, approval) or a term translated differently across keys
- tone: too casual or too stiff for a workplace app, or inconsistent politeness
- placeholder: a {placeholder} is missing, renamed or translated

Rules:
- Placeholders in braces (e.g. {name}, {count}) must stay exactly as in English. ICU syntax \
such as {count, plural, ...} must keep its structure; only the human text inside may change.
- Brand and code names (PPE SMART, QR, EHS, KPI, PR) may stay in Latin script.
- Short UI labels are fine; do not flag a translation only because it is shorter than the English.
- Do not report stylistic preferences when the current text is already correct and natural.
- "suggestion" must be the full corrected string, ready to paste into the ARB file.
- Write "problem" in Thai so the project team can read it.
- If you are not sure a native speaker would agree, set confidence to "low"."""


def load_arb(lang: str) -> dict[str, str]:
    path = L10N_DIR / f'app_{lang}.arb'
    data = json.loads(path.read_text(encoding='utf-8'))
    return {k: v for k, v in data.items() if not k.startswith('@') and isinstance(v, str)}


def build_user_prompt(lang: str, en: dict[str, str], target: dict[str, str]) -> str:
    rows = [{'key': k, 'en': en[k], 'current': target.get(k, '')} for k in en]
    return (
        f'Target language: {LANGUAGES[lang]} (locale "{lang}").\n'
        f'Review these {len(rows)} strings and return only the ones that need a change.\n\n'
        + json.dumps(rows, ensure_ascii=False, indent=1)
    )


def review_language(client, lang: str, en: dict[str, str], target: dict[str, str]):
    import anthropic

    from pydantic import BaseModel

    class Issue(BaseModel):
        key: str
        category: Literal['meaning', 'grammar', 'terminology', 'tone', 'placeholder']
        severity: Literal['high', 'medium', 'low']
        confidence: Literal['high', 'low']
        problem: str
        suggestion: str

    class Review(BaseModel):
        issues: list[Issue]
        summary: str

    try:
        response = client.beta.messages.parse(
            model=MODEL,
            max_tokens=16000,
            betas=['server-side-fallback-2026-07-01'],
            fallbacks='default',  # re-run on a fallback model if the request is declined
            output_config={'effort': 'high'},
            system=SYSTEM_PROMPT,
            messages=[{'role': 'user', 'content': build_user_prompt(lang, en, target)}],
            output_format=Review,
        )
    except (anthropic.AuthenticationError, TypeError):  # TypeError: no credentials configured at all
        sys.exit('ANTHROPIC_API_KEY is missing or invalid.')
    except anthropic.RateLimitError as e:
        raise SystemExit(f'Rate limited while reviewing {lang}: {e}')
    except anthropic.APIStatusError as e:
        raise SystemExit(f'API error {e.status_code} while reviewing {lang}: {e.message}')
    except anthropic.APIConnectionError as e:
        raise SystemExit(f'Could not reach the Claude API: {e}')

    if response.stop_reason == 'refusal':
        raise SystemExit(f'Review of {lang} was declined: {response.stop_details}')
    if response.stop_reason == 'max_tokens':
        raise SystemExit(f'Review of {lang} was cut off (max_tokens). Try again with fewer keys.')

    review = response.parsed_output
    u = response.usage
    print(f'  {lang}: {len(review.issues)} issue(s) · {u.input_tokens} in / {u.output_tokens} out tokens · {response.model}')
    return review


def md(text: str) -> str:
    return text.replace('|', '\\|').replace('\n', '<br>')


def render_report(results: dict, en: dict[str, str], targets: dict[str, dict[str, str]]) -> str:
    order = {'high': 0, 'medium': 1, 'low': 2}
    lines = [
        '# รายงานตรวจคำแปลด้วย LLM',
        '',
        f'- วันที่: {date.today().isoformat()}',
        f'- โมเดล: `{MODEL}`',
        '- สคริปต์: `ppe_mobile_app/tool/review_translations.py`',
        '- สถานะ: **ข้อเสนอแนะ ยังไม่ได้แก้ไฟล์ .arb** ให้คนทบทวนก่อน แล้วแก้ด้วยมือ → `flutter gen-l10n` → `flutter test`',
        '',
    ]
    for lang, review in results.items():
        target = targets[lang]
        lines += [f'## {LANGUAGES[lang]} (`app_{lang}.arb`)', '', review.summary, '']
        if lang == 'my':
            lines += ['> ภาษาพม่า: LLM แม่นน้อยกว่าภาษาไทย/จีน ควรให้เจ้าของภาษาตรวจซ้ำก่อนใช้จริง', '']
        issues = sorted(review.issues, key=lambda i: (order[i.severity], i.key))
        if not issues:
            lines += ['ไม่พบปัญหา', '']
            continue
        lines += [
            '| key | ระดับ | ประเภท | มั่นใจ | EN | ปัจจุบัน | ปัญหา | ข้อเสนอแนะ |',
            '|---|---|---|---|---|---|---|---|',
        ]
        for i in issues:
            note = ''
            if i.key not in en:
                note = ' ⚠️ key ไม่มีในไฟล์'
            elif set(PLACEHOLDER.findall(i.suggestion)) != set(PLACEHOLDER.findall(en[i.key])):
                note = ' ⚠️ placeholder ไม่ตรงกับ EN'
            lines.append(
                f'| `{i.key}`{note} | {i.severity} | {i.category} | {i.confidence} | {md(en.get(i.key, ""))} '
                f'| {md(target.get(i.key, ""))} | {md(i.problem)} | {md(i.suggestion)} |'
            )
        lines.append('')
    return '\n'.join(lines)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('--langs', default=','.join(LANGUAGES), help='comma-separated: th,my,zh')
    parser.add_argument('--out', type=Path, default=DEFAULT_OUT, help=f'report path (default: {DEFAULT_OUT})')
    parser.add_argument('--dry-run', action='store_true', help='show what would be sent, without calling the API')
    args = parser.parse_args()

    langs = [l.strip() for l in args.langs.split(',') if l.strip()]
    unknown = [l for l in langs if l not in LANGUAGES]
    if unknown:
        parser.error(f'unknown language(s): {", ".join(unknown)}')

    en = load_arb('en')
    targets = {lang: load_arb(lang) for lang in langs}

    if args.dry_run:
        for lang in langs:
            prompt = build_user_prompt(lang, en, targets[lang])
            missing = [k for k in en if k not in targets[lang]]
            print(f'{lang}: {len(en)} keys, prompt {len(prompt):,} chars, missing {len(missing)} key(s)')
        return

    import anthropic

    client = anthropic.Anthropic()
    print(f'Reviewing {", ".join(langs)} with {MODEL} ...')
    results = {lang: review_language(client, lang, en, targets[lang]) for lang in langs}

    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text(render_report(results, en, targets), encoding='utf-8')
    print(f'Report: {args.out}')


if __name__ == '__main__':
    main()
