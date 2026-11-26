"""Android accessibility audit adapted from pierridotite/mobile-agent-testers.

Flags:
- interactive controls with no accessible name (TalkBack label),
- touch targets smaller than Android's 48dp minimum (excluding edge-clipped scroll items).
"""
import re

MAX_LISTED = 6


def _bounds(n):
    b = re.findall(r"-?\d+", n.get("bounds", ""))
    return tuple(map(int, b)) if len(b) == 4 else None


def _name(n):
    for m in n.iter("node"):
        t = (m.get("text") or "").strip() or (m.get("content-desc") or "").strip()
        if t:
            return t
    return ""


def _cut(box, frames, small_is_height):
    x1, y1, x2, y2 = box
    for fx1, fy1, fx2, fy2 in frames:
        if small_is_height and (y1 <= fy1 or y2 >= fy2):
            return True
        if not small_is_height and (x1 <= fx1 or x2 >= fx2):
            return True
    return False


def audit_android(root, density, w, h):
    noname, small, seen = [], [], set()
    screen = (0, 0, w, h)

    def visit(n, scrolls):
        b = _bounds(n)
        if b and n.get("scrollable") == "true":
            scrolls = scrolls + [b]
        active = (
            n.get("clickable") == "true"
            or n.get("long-clickable") == "true"
            or n.get("checkable") == "true"
        )
        if b and active and n.get("enabled") != "false":
            x1, y1, x2, y2 = b
            if x2 > x1 and y2 > y1 and (b, "a") not in seen:
                seen.add((b, "a"))
                cx, cy = (x1 + x2) // 2, (y1 + y2) // 2
                name = _name(n)
                big = (x2 - x1) * (y2 - y1) > 0.4 * w * h
                if not name and not big:
                    noname.append({"x": cx, "y": cy})
                wdp = round((x2 - x1) * 160 / density)
                hdp = round((y2 - y1) * 160 / density)
                if min(wdp, hdp) < 48 and not _cut(b, scrolls + [screen], hdp <= wdp):
                    small.append(
                        {"name": name[:36], "w_dp": wdp, "h_dp": hdp, "x": cx, "y": cy}
                    )
        for c in n:
            if c.tag == "node":
                visit(c, scrolls)

    for top in root:
        if top.tag == "node":
            visit(top, [])

    return {"unnamed": noname, "small_targets": small}


def format_summary(result):
    parts = []
    noname = result["unnamed"]
    small = result["small_targets"]
    if noname:
        at = " ".join(f"({p['x']},{p['y']})" for p in noname[:MAX_LISTED])
        more = f" (+{len(noname) - MAX_LISTED} more)" if len(noname) > MAX_LISTED else ""
        parts.append(f"{len(noname)} unnamed control(s) at {at}{more}")
    if small:
        at = ", ".join(
            f"\"{s['name']}\" {s['w_dp']}x{s['h_dp']}dp" if s["name"] else f"{s['w_dp']}x{s['h_dp']}dp at ({s['x']},{s['y']})"
            for s in small[:MAX_LISTED]
        )
        more = f" (+{len(small) - MAX_LISTED} more)" if len(small) > MAX_LISTED else ""
        parts.append(f"{len(small)} target(s) < 48dp: {at}{more}")
    return "; ".join(parts) if parts else "PASS (0 unnamed, 0 undersized targets)"
