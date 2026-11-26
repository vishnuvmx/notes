"""Zero-dependency Android screenshot + UIAutomator + a11y + crash capturer
adapted from pierridotite/mobile-agent-testers for Windows/macOS/Linux.

Usage:
    python qa/mobile-agent-testers/screen.py <out_dir> <screen_name> [--serial <adb_serial>]
"""
import argparse
import json
import re
import struct
import subprocess
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import a11y  # noqa: E402


def run_adb(serial, *args, raw=False):
    cmd = ["adb"]
    if serial:
        cmd += ["-s", serial]
    cmd += list(args)
    r = subprocess.run(cmd, capture_output=True, timeout=60)
    return r.stdout if raw else r.stdout.decode("utf-8", "replace")


def png_dimensions(data: bytes):
    idx = data.find(b"\x89PNG\r\n\x1a\n")
    if idx < 0 or len(data) < idx + 24:
        return (0, 0)
    w, h = struct.unpack(">II", data[idx + 16 : idx + 24])
    return (w, h)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("out_dir")
    parser.add_argument("screen_name")
    parser.add_argument("--serial", default=None)
    args = parser.parse_args()

    out = Path(args.out_dir)
    out.mkdir(parents=True, exist_ok=True)
    name = args.screen_name

    raw_png = run_adb(args.serial, "exec-out", "screencap", "-p", raw=True)
    sig = raw_png.find(b"\x89PNG\r\n\x1a\n")
    if sig > 0:
        raw_png = raw_png[sig:]
    png_path = out / f"{name}.png"
    png_path.write_bytes(raw_png)
    w, h = png_dimensions(raw_png)

    run_adb(args.serial, "shell", "uiautomator", "dump", "/data/local/tmp/tack_ui.xml")
    xml_text = run_adb(args.serial, "exec-out", "cat", "/data/local/tmp/tack_ui.xml")
    xml_start = xml_text.find("<")
    clean_xml = xml_text[xml_start:] if xml_start >= 0 else ""
    (out / f"{name}.xml").write_text(clean_xml, encoding="utf-8")

    try:
        root = ET.fromstring(clean_xml) if clean_xml else ET.Element("hierarchy")
    except ET.ParseError:
        root = ET.Element("hierarchy")

    elements = []
    for n in root.iter("node"):
        text = (n.get("text") or "").strip()
        desc = (n.get("content-desc") or "").strip()
        edit = n.get("class", "").endswith("EditText")
        b = re.findall(r"\d+", n.get("bounds", ""))
        if not (text or desc or edit) or len(b) != 4:
            continue
        x1, y1, x2, y2 = map(int, b)
        kind = "field" if edit else ("button" if n.get("clickable") == "true" else "text")
        elements.append(
            {
                "kind": kind,
                "label": (text or desc)[:80],
                "cx": (x1 + x2) // 2,
                "cy": (y1 + y2) // 2,
                "bounds": [x1, y1, x2, y2],
            }
        )

    dpi_out = run_adb(args.serial, "shell", "wm", "density")
    dpi_nums = re.findall(r"\d+", dpi_out)
    density = int(dpi_nums[-1]) if dpi_nums else 420

    a11y_result = a11y.audit_android(root, density, w, h) if w > 0 and h > 0 else {"unnamed": [], "small_targets": []}
    a11y_line = a11y.format_summary(a11y_result)

    crash_log = (
        run_adb(args.serial, "logcat", "-d", "-b", "crash")
        + "\n"
        + run_adb(args.serial, "logcat", "-d", "AndroidRuntime:E", "flutter:E", "*:S")
    )
    run_adb(args.serial, "logcat", "-c")
    crash_lines = [
        line for line in crash_log.splitlines()
        if line.strip() and not line.startswith("-----")
    ][-20:]

    meta = {
        "screen": name,
        "width": w,
        "height": h,
        "density": density,
        "element_count": len(elements),
        "elements": elements,
        "a11y": a11y_result,
        "a11y_summary": a11y_line,
        "errors": crash_lines,
    }
    (out / f"{name}.meta.json").write_text(json.dumps(meta, indent=2), encoding="utf-8")

    print(f"[{name}] {w}x{h} @ {density}dpi | {len(elements)} elements | a11y: {a11y_line}")
    if crash_lines:
        print(f"  !! {len(crash_lines)} error/crash line(s) captured in {name}.meta.json")


if __name__ == "__main__":
    main()
