#!/usr/bin/env python3
"""Récupère les cours de clôture BRVM et écrit cours-brvm.json à la racine du dépôt."""

from __future__ import annotations

import json
import re
import sys
from datetime import datetime, timezone
from pathlib import Path
from urllib.request import Request, urlopen

from bs4 import BeautifulSoup

ROOT = Path(__file__).resolve().parent.parent
OUT_PATH = ROOT / "cours-brvm.json"
USER_AGENT = "BRVM-Gestion/1.0 (+https://github.com/PgLand/modi; cours auto)"

URLS = [
    "https://www.brvm.org/en/cours-actions/0/status/200",
    "https://www.brvm.org/fr/cours-actions/0/status/200",
    "https://www.brvm.org/",
]


def fetch_html(url: str) -> str:
    req = Request(url, headers={"User-Agent": USER_AGENT, "Accept-Language": "fr-FR,fr;q=0.9"})
    with urlopen(req, timeout=90) as resp:
        return resp.read().decode("utf-8", errors="replace")


def parse_price(raw: str) -> int:
    cleaned = re.sub(r"\s+", "", str(raw).strip()).replace(",", ".")
    cleaned = re.sub(r"[^\d.]", "", cleaned)
    if not cleaned:
        raise ValueError(f"Prix invalide: {raw!r}")
    return int(round(float(cleaned)))


def is_ticker(value: str) -> bool:
    return bool(re.fullmatch(r"[A-Z]{3,5}", value.strip().upper()))


def scrape_tables(html: str) -> dict[str, int]:
    soup = BeautifulSoup(html, "lxml")
    prices: dict[str, int] = {}

    for table in soup.find_all("table"):
        header_cells = table.find_all("th")
        if not header_cells:
            continue

        headers = [th.get_text(" ", strip=True).lower() for th in header_cells]
        ticker_idx = None
        close_idx = None

        for idx, header in enumerate(headers):
            if any(k in header for k in ("ticker", "symbole", "symbol", "code")):
                ticker_idx = idx
            if any(k in header for k in ("closing", "clôture", "cloture", "close", "cours")):
                if "variation" not in header and "change" not in header and "var" not in header:
                    close_idx = idx

        if ticker_idx is None:
            ticker_idx = 0
        if close_idx is None:
            for idx, header in enumerate(headers):
                if "previous" in header or "ouverture" in header or "opening" in header:
                    continue
                if "cours" in header or "close" in header or "clôture" in header:
                    close_idx = idx
                    break

        for row in table.find_all("tr"):
            cells = row.find_all("td")
            if not cells:
                continue
            texts = [cell.get_text(" ", strip=True) for cell in cells]
            if len(texts) <= max(ticker_idx, close_idx or 0):
                continue

            sym = texts[ticker_idx].upper().strip()
            if not is_ticker(sym):
                continue

            for candidate_idx in filter(lambda i: i is not None, [close_idx, len(texts) - 2, len(texts) - 1]):
                try:
                    prices[sym] = parse_price(texts[candidate_idx])
                    break
                except (ValueError, IndexError):
                    continue

    return prices


def scrape_homepage(html: str) -> dict[str, int]:
    """Parse le bandeau ticker de la page d'accueil BRVM (ex: BOABF 5 585 2,97%)."""
    prices: dict[str, int] = {}
    pattern = re.compile(
        r"\b([A-Z]{3,5})\s+([\d][\d\s]{1,12})\s+([-+]?\d+[,.]\d*)\s*%",
        re.MULTILINE,
    )
    for sym, price_raw, _variation in pattern.findall(html):
        if not is_ticker(sym):
            continue
        try:
            prices[sym.upper()] = parse_price(price_raw)
        except ValueError:
            continue
    return prices


def main() -> int:
    merged: dict[str, int] = {}

    for url in URLS:
        try:
            html = fetch_html(url)
        except Exception as exc:
            print(f"Avertissement — échec {url}: {exc}", file=sys.stderr)
            continue

        table_prices = scrape_tables(html)
        home_prices = scrape_homepage(html)
        merged.update(home_prices)
        merged.update(table_prices)

        if len(merged) >= 30:
            break

    if len(merged) < 10:
        print("Erreur — moins de 10 cours récupérés, fichier non mis à jour.", file=sys.stderr)
        return 1

    payload = {
        "updated": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "source": "BRVM (cours de clôture)",
        "prices": dict(sorted(merged.items())),
    }

    OUT_PATH.write_text(json.dumps(payload, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"OK — {len(payload['prices'])} cours écrits dans {OUT_PATH.name}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
