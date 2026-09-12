"""catalog.json 教程 ↔ docs/setup-guide-sources.json 出处。

出处不进 App、不进 Worker。闸拿这份对 stepsFingerprint，改教程不碰出处就红。
"""

from __future__ import annotations

import hashlib
import json
import re
from pathlib import Path
from typing import Any
from urllib.parse import urlparse

SOURCES_REL = Path("docs/setup-guide-sources.json")
CATALOG_REL = Path(
    "Packages/MeterKit/Sources/MeterPersistence/Catalog/catalog.json"
)
PROVIDER_ID_REL = Path("Packages/MeterKit/Sources/MeterCore/ProviderID.swift")
PROVIDERS_DIR_REL = Path("Packages/MeterKit/Sources/MeterProviders")

DESCRIPTOR_OPEN = re.compile(r"public static let \w+ = ProviderDescriptor\(")
DESCRIPTOR_CLOSE = re.compile(r"\n    \)\n")
CREDENTIAL_URL = re.compile(
    r'credentialSetupURL:\s*URL\(\s*string:\s*"([^"]+)"',
    re.S,
)
BILLING_URL = re.compile(
    r'billingURL:\s*URL\(\s*string:\s*"([^"]+)"',
    re.S,
)


def sources_path(root: Path) -> Path:
    return root / SOURCES_REL


def catalog_path(root: Path) -> Path:
    return root / CATALOG_REL


def load_catalog_guides(root: Path) -> dict[str, dict[str, Any]]:
    data = json.loads(catalog_path(root).read_text(encoding="utf-8"))
    guides = data.get("guides") or {}
    if not isinstance(guides, dict):
        raise ValueError("catalog.json guides 不是对象")
    return guides


def guides_with_steps(guides: dict[str, dict[str, Any]]) -> dict[str, dict[str, Any]]:
    out: dict[str, dict[str, Any]] = {}
    for key, guide in guides.items():
        if not isinstance(guide, dict):
            continue
        if any(
            (step.get("text") or "").strip()
            for part in guide.get("parts") or []
            if isinstance(part, dict)
            for step in part.get("steps") or []
            if isinstance(step, dict)
        ):
            out[key] = guide
    return out


def steps_fingerprint(guide: dict[str, Any]) -> str:
    parts: list[dict[str, Any]] = []
    for part in guide.get("parts") or []:
        if not isinstance(part, dict):
            continue
        fields = [
            {"key": field.get("key") or "", "label": field.get("label") or ""}
            for field in part.get("fields") or []
            if isinstance(field, dict)
        ]
        steps = []
        for step in part.get("steps") or []:
            if not isinstance(step, dict):
                continue
            en = step.get("en") if isinstance(step.get("en"), dict) else {}
            ja = step.get("ja") if isinstance(step.get("ja"), dict) else {}
            steps.append(
                {
                    "en": (en or {}).get("text") or "",
                    "ja": (ja or {}).get("text") or "",
                    "text": step.get("text") or "",
                }
            )
        parts.append({"fields": fields, "steps": steps})
    payload = json.dumps(parts, ensure_ascii=False, sort_keys=True, separators=(",", ":"))
    digest = hashlib.sha256(payload.encode("utf-8")).hexdigest()
    return f"sha256:{digest}"


def load_sources(root: Path) -> dict[str, Any]:
    path = sources_path(root)
    if not path.is_file():
        raise FileNotFoundError(f"找不到 {SOURCES_REL}")
    data = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(data, dict):
        raise ValueError("setup-guide-sources.json 不是对象")
    return data


def dump_sources(root: Path, data: dict[str, Any]) -> None:
    guides = data.get("guides") or {}
    data = {
        "schemaVersion": 1,
        "doc": (
            "教程出处。App 和 Worker 都不读这份文件。"
            "改 catalog.json 某家的 fields / steps 必须同步核对 sourceURL，"
            "然后 python3 scripts/refresh-setup-guide-source.py <id>。"
        ),
        "guides": {key: guides[key] for key in sorted(guides)},
    }
    text = json.dumps(data, ensure_ascii=False, indent=2) + "\n"
    sources_path(root).write_text(text, encoding="utf-8")


def provider_id_raw_values(root: Path) -> dict[str, str]:
    text = (root / PROVIDER_ID_REL).read_text(encoding="utf-8")
    return dict(
        re.findall(
            r'static let ([A-Za-z0-9_]+)\s*=\s*ProviderID\(rawValue:\s*"([^"]+)"\)',
            text,
        )
    )


def credential_setup_urls(root: Path) -> dict[str, str]:
    """catalog key → credentialSetupURL。没有创建页的家不出现。"""
    name_to_raw = provider_id_raw_values(root)
    credential: dict[str, str] = {}
    billing: dict[str, str] = {}
    directory = root / PROVIDERS_DIR_REL
    for path in [directory / "ProviderCatalog.swift", *sorted(directory.glob("ProviderCatalog+Batch*.swift"))]:
        if not path.is_file():
            continue
        text = path.read_text(encoding="utf-8")
        for open_match in DESCRIPTOR_OPEN.finditer(text):
            close_match = DESCRIPTOR_CLOSE.search(text, open_match.end())
            if close_match is None:
                continue
            block = text[open_match.end() : close_match.start()]
            ident = re.search(r"\bid:\s*\.(\w+)", block)
            if ident is None:
                continue
            raw = name_to_raw.get(ident.group(1), ident.group(1))
            cred = CREDENTIAL_URL.search(block)
            if cred:
                credential[raw] = cred.group(1)
            bill = BILLING_URL.search(block)
            if bill:
                billing[raw] = bill.group(1)
    found = dict(billing)
    found.update(credential)
    return found


def source_url_errors(url: str, key: str) -> list[str]:
    errors: list[str] = []
    if not url.startswith("https://"):
        errors.append(f"{SOURCES_REL} {key}: sourceURL 必须是 https://")
        return errors
    host = urlparse(url).hostname
    if not host:
        errors.append(f"{SOURCES_REL} {key}: sourceURL 没有 host")
    if " " in url or "\n" in url:
        errors.append(f"{SOURCES_REL} {key}: sourceURL 含空白")
    return errors


def collect_sync_errors(root: Path) -> list[str]:
    errors: list[str] = []
    try:
        catalog_guides = guides_with_steps(load_catalog_guides(root))
    except (OSError, ValueError, json.JSONDecodeError) as exc:
        return [f"读不了 catalog.json：{exc}"]
    try:
        data = load_sources(root)
    except FileNotFoundError:
        return [
            f"找不到 {SOURCES_REL}。每家有教程就必须有出处。"
            f"先 python3 scripts/refresh-setup-guide-source.py --bootstrap"
        ]
    except (OSError, ValueError, json.JSONDecodeError) as exc:
        return [f"读不了 {SOURCES_REL}：{exc}"]

    guides = data.get("guides")
    if not isinstance(guides, dict):
        return [f"{SOURCES_REL} 缺少 guides 对象"]

    catalog_keys = set(catalog_guides)
    source_keys = set(guides)
    for key in sorted(catalog_keys - source_keys):
        errors.append(
            f"catalog.json 有 {key} 的教程，{SOURCES_REL} 没有。"
            f"补上 sourceURL 后执行 python3 scripts/refresh-setup-guide-source.py --url https://… {key}"
        )
    for key in sorted(source_keys - catalog_keys):
        errors.append(
            f"{SOURCES_REL} 有 {key}，catalog.json 没有对应教程。删掉这条，或补教程。"
        )

    for key in sorted(catalog_keys & source_keys):
        entry = guides[key]
        if not isinstance(entry, dict):
            errors.append(f"{SOURCES_REL} {key} 不是对象")
            continue
        url = entry.get("sourceURL")
        if not isinstance(url, str) or not url.strip():
            errors.append(f"{SOURCES_REL} {key} 缺 sourceURL")
        else:
            errors.extend(source_url_errors(url.strip(), key))
        expected = steps_fingerprint(catalog_guides[key])
        actual = entry.get("stepsFingerprint")
        if actual != expected:
            errors.append(
                f"catalog.json 的 {key} 教程和 {SOURCES_REL} 的 stepsFingerprint 对不上。"
                f"核对 sourceURL 仍指向写这篇教程时看的那页，然后 "
                f"python3 scripts/refresh-setup-guide-source.py {key}"
            )
    return errors
