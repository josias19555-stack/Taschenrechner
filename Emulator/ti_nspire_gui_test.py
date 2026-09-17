#!/usr/bin/env python3
"""Controlled GUI smoke test for the TI-Nspire desktop application.

The script is deliberately dry-run by default. Use --run only after the
TI-Nspire window is open and the target document is ready for input.
"""

from __future__ import annotations

import argparse
import ctypes
import ctypes.wintypes
import json
import sys
import time
from dataclasses import dataclass, asdict
from datetime import datetime
from pathlib import Path
from typing import Any

try:
    import pyautogui
except ImportError:  # pragma: no cover - dependency is optional until --run
    pyautogui = None

try:
    from PIL import Image
except ImportError:  # pragma: no cover - only needed for calibrated GUI runs
    Image = None


DEFAULT_OUTPUT = Path("ti_nspire_gui_runs")


@dataclass
class Point:
    x: int
    y: int


@dataclass
class Step:
    name: str
    action: str
    value: Any = None
    delay: float = 0.5


FRAME_POINTS = {
    "A": Point(1446, 1032),
    "C": Point(1760, 1032),
    "D": Point(1760, 500),
    "B": Point(2074, 1032),
}

GRID_STEP_CORRECTION = 1.6
HORIZONTAL_STEP_CORRECTION = 1.2


STEPS = [
    Step("focus_window", "hotkey", ["alt", "tab"], 1.0),
    Step("capture_before", "screenshot", "before_export", 0.2),
    Step("open_settings", "press", "o", 0.5),
    Step("open_export_page", "press", "right", 0.3),
    Step("select_new_bending_export", "press", "down", 0.3),
    Step("run_new_bending_export", "press", "enter", 2.0),
    Step("capture_bending_export", "screenshot", "after_bending_export", 0.5),
    Step("close_menu", "press", "escape", 0.5),
    Step("capture_final", "screenshot", "final", 0.2),
]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--run", action="store_true", help="send real keyboard input")
    parser.add_argument("--dry-run", action="store_true", help="only print planned actions")
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    parser.add_argument("--interval", type=float, default=0.05)
    parser.add_argument("--settle", type=float, default=1.0)
    parser.add_argument("--no-alt-tab", action="store_true", help="do not change the active window")
    parser.add_argument(
        "--reenter-frame",
        action="store_true",
        help="clear the Statik model, redraw the frame, and enter its supports, spring, and load",
    )
    parser.add_argument(
        "--calibrated-reenter",
        action="store_true",
        help="use live axis detection and verify every frame point while re-entering",
    )
    parser.add_argument(
        "--focus-only",
        action="store_true",
        help="activate TI-Nspire and capture a screenshot without sending input",
    )
    parser.add_argument(
        "--prepare-statik",
        action="store_true",
        help="activate TI-Nspire, switch one page left, and capture the page without editing",
    )
    parser.add_argument(
        "--reload-code",
        action="store_true",
        help="focus Script Editor, replace its contents with Biegelinieneu.lua, and save",
    )
    parser.add_argument(
        "--set-script",
        action="store_true",
        help="focus Script Editor and activate its 'Skript festlegen' command",
    )
    parser.add_argument(
        "--full-cycle",
        action="store_true",
        help="reload code, set script, enter/calculate the frame, export, and inspect vne1 in CAS",
    )
    parser.add_argument(
        "--calibration-screenshot",
        action="store_true",
        help="capture TI-Nspire with calibrated A/C/D/B targets and cursor overlay",
    )
    parser.add_argument(
        "--place-nodes-only",
        action="store_true",
        help="clear the Statik page and place only A, C, D, and B with a screenshot after each action",
    )
    parser.add_argument(
        "--place-frame",
        action="store_true",
        help="clear, place A/C/D/B, connect them into beams, and set the A/B supports",
    )
    return parser.parse_args()


def require_dependency() -> None:
    if pyautogui is None:
        raise RuntimeError(
            "pyautogui is missing. Install it with: python -m pip install pyautogui"
        )
    if Image is None:
        raise RuntimeError("Pillow is missing. Install it with: python -m pip install pillow")


def focus_ti_nspire_window() -> bool:
    if sys.platform != "win32":
        return False
    user32 = ctypes.windll.user32
    found = []

    @ctypes.WINFUNCTYPE(ctypes.c_bool, ctypes.c_void_p, ctypes.c_void_p)
    def enum_callback(hwnd, _lparam):
        if not user32.IsWindowVisible(hwnd):
            return True
        length = user32.GetWindowTextLengthW(hwnd)
        buffer = ctypes.create_unicode_buffer(length + 1)
        user32.GetWindowTextW(hwnd, buffer, length + 1)
        if "TI-Nspire" in buffer.value:
            found.append(hwnd)
            return False
        return True

    user32.EnumWindows(enum_callback, 0)
    if not found:
        print("[focus] no TI-Nspire window found")
        return False
    hwnd = found[0]
    print(f"[focus] TI-Nspire window found: {hwnd}")
    user32.ShowWindow(hwnd, 9)
    rect = ctypes.wintypes.RECT()
    user32.GetWindowRect(hwnd, ctypes.byref(rect))
    user32.SetWindowPos(hwnd, -1, rect.left, rect.top, 0, 0, 0x0001 | 0x0002)
    user32.SetForegroundWindow(hwnd)
    pyautogui.click((rect.left + rect.right) // 2, rect.top + 25)
    time.sleep(0.8)
    foreground = user32.GetForegroundWindow()
    success = foreground == hwnd
    print(f"[focus] foreground_verified={success}")
    return success


def focus_window_with_title(fragment: str) -> bool:
    if sys.platform != "win32":
        return False
    user32 = ctypes.windll.user32
    found = []

    @ctypes.WINFUNCTYPE(ctypes.c_bool, ctypes.c_void_p, ctypes.c_void_p)
    def enum_callback(hwnd, _lparam):
        if not user32.IsWindowVisible(hwnd):
            return True
        length = user32.GetWindowTextLengthW(hwnd)
        buffer = ctypes.create_unicode_buffer(length + 1)
        user32.GetWindowTextW(hwnd, buffer, length + 1)
        if fragment.lower() in buffer.value.lower():
            found.append(hwnd)
            return False
        return True

    user32.EnumWindows(enum_callback, 0)
    if not found:
        print(f"[focus] no window containing {fragment!r} found")
        return False
    hwnd = found[0]
    user32.ShowWindow(hwnd, 9)
    rect = ctypes.wintypes.RECT()
    user32.GetWindowRect(hwnd, ctypes.byref(rect))
    user32.SetForegroundWindow(hwnd)
    pyautogui.click((rect.left + rect.right) // 2, rect.top + 25)
    time.sleep(0.8)
    return user32.GetForegroundWindow() == hwnd


def copy_to_clipboard(text: str) -> None:
    import tkinter

    root = tkinter.Tk()
    root.withdraw()
    root.clipboard_clear()
    root.clipboard_append(text)
    root.update()
    root.destroy()


def screen_to_mouse(point: Point) -> tuple[int, int]:
    """Convert physical screenshot pixels to the logical mouse coordinate space."""
    if sys.platform == "win32":
        dpi = ctypes.windll.user32.GetDpiForSystem()
        scale = max(1.0, dpi / 96.0)
        return round(point.x / scale), round(point.y / scale)
    return point.x, point.y


def win32_move_physical(point: Point) -> None:
    if sys.platform == "win32":
        ctypes.windll.user32.SetCursorPos(point.x, point.y)
    else:
        pyautogui.moveTo(point.x, point.y)


def win32_click_physical(point: Point) -> None:
    win32_move_physical(point)
    time.sleep(0.15)
    if sys.platform == "win32":
        user32 = ctypes.windll.user32
        user32.mouse_event(0x0002, 0, 0, 0, 0)
        user32.mouse_event(0x0004, 0, 0, 0, 0)
    else:
        pyautogui.click(point.x, point.y)


def timestamp() -> str:
    return datetime.now().strftime("%Y%m%d_%H%M%S")


def save_metadata(output_dir: Path, run_id: str, args: argparse.Namespace) -> None:
    output_dir.mkdir(parents=True, exist_ok=True)
    metadata = {
        "run_id": run_id,
        "started_at": datetime.now().isoformat(timespec="seconds"),
        "mode": "run" if args.run and not args.dry_run else "dry-run",
        "screen_size": list(pyautogui.size()) if pyautogui else None,
        "steps": [asdict(step) for step in STEPS],
    }
    (output_dir / f"{run_id}_metadata.json").write_text(
        json.dumps(metadata, indent=2), encoding="utf-8"
    )


def capture(output_dir: Path, run_id: str, name: str) -> None:
    if pyautogui is None:
        return
    path = output_dir / f"{run_id}_{name}.png"
    pyautogui.screenshot(str(path))
    print(f"[capture] {path}")


def capture_calibration_overlay(output_dir: Path, run_id: str) -> None:
    from PIL import ImageDraw

    if not focus_ti_nspire_window():
        raise RuntimeError("Could not activate TI-Nspire")
    image = pyautogui.screenshot()
    points = calibrated_frame_points()
    cursor = pyautogui.position()
    draw = ImageDraw.Draw(image)
    for name, point in points.items():
        color = (220, 0, 0) if name == "D" else (0, 120, 255)
        draw.line((point.x - 28, point.y, point.x + 28, point.y), fill=color, width=3)
        draw.line((point.x, point.y - 28, point.x, point.y + 28), fill=color, width=3)
        draw.text((point.x + 10, point.y + 10), name, fill=color)
    draw.ellipse((cursor.x - 8, cursor.y - 8, cursor.x + 8, cursor.y + 8), outline=(0, 180, 0), width=3)
    draw.line((cursor.x - 20, cursor.y, cursor.x + 20, cursor.y), fill=(0, 180, 0), width=2)
    draw.line((cursor.x, cursor.y - 20, cursor.x, cursor.y + 20), fill=(0, 180, 0), width=2)
    path = output_dir / f"{run_id}_calibration_overlay.png"
    image.save(path)
    print(f"[calibration] cursor=({cursor.x},{cursor.y})")
    print(f"[capture] {path}")


def execute_step(step: Step, output_dir: Path, run_id: str, args: argparse.Namespace) -> None:
    print(f"[step] {step.name}: {step.action} {step.value or ''}".rstrip())
    if not args.run or args.dry_run:
        time.sleep(min(step.delay, 0.1))
        return

    if step.action == "screenshot":
        capture(output_dir, run_id, str(step.value))
    elif step.action == "hotkey":
        pyautogui.hotkey(*step.value)
    elif step.action == "press":
        pyautogui.press(step.value)
    elif step.action == "click":
        pyautogui.click(step.value.x, step.value.y)
    else:
        raise ValueError(f"Unknown action: {step.action}")
    time.sleep(step.delay)


def frame_click(point: Point, pause: float = 0.4) -> None:
    win32_click_physical(point)
    time.sleep(pause)


def frame_key(key: str, pause: float = 0.3) -> None:
    pyautogui.press(key)
    time.sleep(pause)


def frame_menu(point: Point, page: int, row: int, text: str | None = None) -> None:
    win32_move_physical(point)
    time.sleep(0.35)
    frame_key("enter")
    for _ in range(page - 1):
        frame_key("right")
    for _ in range(row - 1):
        frame_key("down")
    frame_key("enter")
    if text is not None:
        pyautogui.write(text, interval=0.04)
        frame_key("enter")
    frame_key("escape")


def upper_menu(page: int, row: int, text: str | None = None) -> None:
    frame_key("o")
    for _ in range(page - 1):
        frame_key("right")
    for _ in range(row - 1):
        frame_key("down")
    frame_key("enter")
    if text is not None:
        pyautogui.write(text, interval=0.04)
        frame_key("enter")
    frame_key("escape")


def detect_axis_origin(image: Image.Image) -> Point:
    """Find the long light-blue axes drawn by the Statik Lua canvas."""
    width, height = image.size
    x_scores = [0] * width
    y_scores = [0] * height
    pixels = image.load()
    for y in range(220, height - 120, 4):
        for x in range(700, width - 150, 4):
            r, g, b = pixels[x, y][:3]
            if b >= 220 and b > r + 25 and b > g + 15:
                x_scores[x] += 1
                y_scores[y] += 1
    origin_x = max(range(700, width - 150, 4), key=lambda x: x_scores[x])
    if x_scores[origin_x] < 100:
        raise RuntimeError("Could not reliably detect the Statik axes")
    origin_y = max(range(220, height - 120, 4), key=lambda y: y_scores[y])
    if y_scores[origin_y] < 100:
        raise RuntimeError("Could not reliably detect the Statik axes")
    return Point(origin_x, origin_y)


def marker_present(image: Image.Image, point: Point) -> bool:
    """Check for a dark or selected-red node marker near a target point."""
    pixels = image.load()
    hits = 0
    for y in range(max(0, point.y - 70), min(image.height, point.y + 71)):
        for x in range(max(0, point.x - 70), min(image.width, point.x + 71)):
            r, g, b = pixels[x, y][:3]
            if (r < 45 and g < 45 and b < 45) or (r > 180 and g < 80 and b < 80):
                hits += 1
    return hits >= 12


def locate_selected_marker(image: Image.Image) -> Point | None:
    pixels = image.load()
    coordinates = []
    for y in range(250, image.height - 100):
        for x in range(700, image.width - 120):
            r, g, b = pixels[x, y][:3]
            if r > 180 and g < 90 and b < 90:
                coordinates.append((x, y))
    if len(coordinates) < 20:
        return None
    return Point(
        round(sum(x for x, _ in coordinates) / len(coordinates)),
        round(sum(y for _, y in coordinates) / len(coordinates)),
    )


def calibrated_frame_points() -> dict[str, Point]:
    image = pyautogui.screenshot()
    origin = detect_axis_origin(image)
    pixels = image.load()
    canvas_top = None
    for y in range(400, origin.y):
        white_count = 0
        for x in range(max(850, origin.x - 600), min(image.width - 250, origin.x + 600), 8):
            r, g, b = pixels[x, y][:3]
            if r > 235 and g > 235 and b > 235:
                white_count += 1
        if white_count > 80:
            canvas_top = y
            break
    if canvas_top is None:
        canvas_top = max(420, origin.y - 680)
        print(f"[calibration] canvas top fallback={canvas_top}")
    grid_spacing = (image.height - canvas_top - 40) / 7
    unit = min(400, grid_spacing * 2, origin.x - 850, image.width - origin.x - 250)
    if unit < 180:
        raise RuntimeError(f"Not enough calibrated canvas space for frame: unit={unit:.0f}")
    unit = round(unit / GRID_STEP_CORRECTION)
    points = {
        "A": Point(origin.x - unit, origin.y),
        "C": Point(origin.x, origin.y),
        "D": Point(origin.x, max(canvas_top + 20, origin.y - 2 * unit)),
        "B": Point(origin.x + unit, origin.y),
    }
    print(f"[calibration] axis origin=({origin.x},{origin.y}), canvas_top={canvas_top}, unit={unit}")
    print("[calibration] " + ", ".join(f"{name}=({p.x},{p.y})" for name, p in points.items()))
    return points


def find_statik_page() -> bool:
    """Try neighboring TI-Nspire pages until the Statik axes are visible."""
    if not focus_ti_nspire_window():
        return False
    directions = ["left", "right", "left", "right"]
    for direction in directions:
        time.sleep(0.6)
        try:
            detect_axis_origin(pyautogui.screenshot())
            print(f"[page] Statik page detected after ctrl+{direction}")
            return True
        except RuntimeError:
            pyautogui.hotkey("ctrl", direction)
    return False


def calibrated_reenter_frame(output_dir: Path, run_id: str) -> None:
    points = None
    last_error = None
    for attempt in range(4):
        try:
            candidate = calibrated_frame_points()
            if candidate["D"].y < 260:
                raise RuntimeError("detected upper node would be outside the canvas")
            points = candidate
            break
        except RuntimeError as error:
            last_error = error
            if attempt < 3:
                pyautogui.hotkey("alt", "tab")
                time.sleep(1.0)
    if points is None:
        raise RuntimeError(f"Could not focus a valid TI-Nspire canvas: {last_error}")
    pyautogui.press("c")
    time.sleep(0.8)
    capture(output_dir, run_id, "calibrated_after_clear")
    frame_click(points["A"])
    image = pyautogui.screenshot()
    actual_a = locate_selected_marker(image)
    if actual_a is None:
        if not marker_present(image, points["A"]):
            raise RuntimeError("Could not locate the first node for click calibration")
        actual_a = points["A"]
    print(f"[calibration] first snapped marker=({actual_a.x},{actual_a.y})")
    capture(output_dir, run_id, "calibrated_after_A")
    if not marker_present(image, points["A"]):
        raise RuntimeError("First calibrated node marker was not verified")

    verified_nodes = {"A"}
    for name in ("C", "D", "C", "B", "C"):
        frame_click(points[name])
        image = pyautogui.screenshot()
        capture(output_dir, run_id, f"calibrated_after_{name}")
        if name == "D" and not marker_present(image, points[name]):
            fallback = Point(points["D"].x, points["C"].y - 300)
            print(f"[calibration] retry D at ({fallback.x},{fallback.y})")
            frame_click(fallback)
            points["D"] = fallback
            image = pyautogui.screenshot()
            capture(output_dir, run_id, "calibrated_after_D_retry")
        if name == "B" and not marker_present(image, points[name]):
            fallback = Point(points["C"].x + 300, points["C"].y)
            print(f"[calibration] retry B at ({fallback.x},{fallback.y})")
            frame_click(fallback)
            points["B"] = fallback
            image = pyautogui.screenshot()
            capture(output_dir, run_id, "calibrated_after_B_retry")
        if name in ("A", "C", "D", "B") and name not in verified_nodes and not marker_present(image, points[name]):
            raise RuntimeError(f"Node {name} was not detected after its click")
        if name in ("C", "D", "B"):
            verified_nodes.add(name)

    frame_menu(points["A"], page=1, row=5)
    frame_menu(points["B"], page=1, row=4)
    frame_menu(points["D"], page=3, row=1, text="EI/l^3")
    frame_menu(Point((points["C"].x + points["B"].x) // 2, points["C"].y), page=1, row=3, text="q")
    frame_key("b", pause=2.0)
    capture(output_dir, run_id, "calibrated_frame_calculated")


def place_nodes_only(output_dir: Path, run_id: str) -> None:
    if not focus_ti_nspire_window():
        raise RuntimeError("Could not activate TI-Nspire")
    pyautogui.press("c")
    time.sleep(1.0)
    capture(output_dir, run_id, "nodes_after_clear")
    image = pyautogui.screenshot()
    origin = detect_axis_origin(image)
    # These are the proven physical grid coordinates for the visible 1.1 page.
    horizontal_step = round(314 / GRID_STEP_CORRECTION / HORIZONTAL_STEP_CORRECTION)
    vertical_step = round(584 / GRID_STEP_CORRECTION)
    points = {
        "A": Point(origin.x - horizontal_step, origin.y),
        "C": Point(origin.x, origin.y),
        "D": Point(origin.x, origin.y - vertical_step),
        "B": Point(origin.x + horizontal_step, origin.y),
    }
    for name in ("A", "C", "D", "B"):
        frame_click(points[name])
        time.sleep(.8)
        capture(output_dir, run_id, f"nodes_after_{name}")
        print(f"[nodes] placed {name} at ({points[name].x},{points[name].y})")
    frame_key("escape")


def sync_code_to_calculator(output_dir: Path, run_id: str) -> None:
    """Push the current Biegelinieneu.lua into the calculator before any system entry.

    Switches to the Tragwerk page first, then replaces and saves the Script
    Editor contents, then activates the script via "Skript festlegen".
    """
    if not focus_ti_nspire_window():
        raise RuntimeError("Could not activate TI-Nspire before syncing the code")
    pyautogui.hotkey("ctrl", "left")
    time.sleep(1.0)
    capture(output_dir, run_id, "sync_tragwerk_page_selected")

    source = Path(__file__).with_name("Biegelinieneu.lua").read_text(encoding="utf-8")
    if not focus_window_with_title("Script Editor"):
        raise RuntimeError("Could not activate Script Editor")
    copy_to_clipboard(source)
    pyautogui.hotkey("ctrl", "a")
    pyautogui.hotkey("ctrl", "v")
    pyautogui.hotkey("ctrl", "s")
    time.sleep(1.0)
    pyautogui.click(305, 160)
    time.sleep(1.5)
    capture(output_dir, run_id, "sync_script_saved")
    print("[sync] code copied, saved, and script set on the Tragwerk page")

    if not focus_ti_nspire_window():
        raise RuntimeError("Could not reactivate TI-Nspire after syncing the code")


def place_frame_with_supports(output_dir: Path, run_id: str) -> None:
    """Sync the current code, then place A/C/D/B, connect beams, and set supports.

    A node click only creates a Stab when it lands on an *already existing*
    node while another node is selected (`auswahl`). Two brand-new points
    clicked back-to-back never form a beam. So every node is created first,
    then each connection is made by clicking two existing nodes in turn.
    """
    sync_code_to_calculator(output_dir, run_id)
    time.sleep(1.0)
    pyautogui.press("c")
    time.sleep(1.0)
    capture(output_dir, run_id, "frame_after_clear")
    image = pyautogui.screenshot()
    origin = detect_axis_origin(image)
    horizontal_step = round(314 / GRID_STEP_CORRECTION / HORIZONTAL_STEP_CORRECTION)
    vertical_step = round(584 / GRID_STEP_CORRECTION)
    points = {
        "A": Point(origin.x - horizontal_step, origin.y),
        "C": Point(origin.x, origin.y),
        "D": Point(origin.x, origin.y - vertical_step),
        "B": Point(origin.x + horizontal_step, origin.y),
    }

    for name in ("A", "C", "D", "B"):
        frame_click(points[name])
        time.sleep(.8)
        capture(output_dir, run_id, f"frame_after_{name}")
        print(f"[frame] placed node {name} at ({points[name].x},{points[name].y})")
    frame_key("escape")
    capture(output_dir, run_id, "frame_after_nodes_escape")

    connections = [("A", "C"), ("C", "B"), ("C", "D")]
    for first, second in connections:
        frame_click(points[first])
        time.sleep(.5)
        frame_click(points[second])
        time.sleep(.8)
        capture(output_dir, run_id, f"frame_after_stab_{first}{second}")
        print(f"[frame] connected {first}-{second}")

    # A: vertical support (page 1, row 5); B: horizontal support (page 1, row 4).
    frame_menu(points["A"], page=1, row=5)
    time.sleep(.5)
    capture(output_dir, run_id, "frame_after_lager_A")
    frame_menu(points["B"], page=1, row=4)
    time.sleep(.5)
    capture(output_dir, run_id, "frame_after_lager_B")
    print("[frame] set support A (vertical) and support B (horizontal)")

    upper_menu(page=1, row=3, text="EI")
    capture(output_dir, run_id, "frame_after_global_EI")
    print("[frame] set global bending stiffness EI")

    frame_menu(points["D"], page=3, row=1, text="EI/l^3")
    capture(output_dir, run_id, "frame_after_spring_D")
    print("[frame] set horizontal spring at D to EI/l^3")

    lower_right_midpoint = Point((points["C"].x + points["B"].x) // 2, points["C"].y)
    frame_menu(lower_right_midpoint, page=1, row=3, text="q")
    capture(output_dir, run_id, "frame_after_load_CB")
    print("[frame] set distributed load q on member C-B")

    upper_menu(page=2, row=8)
    print("[frame] exported all new boundary-LGS bending lines to the calculator")
    pyautogui.hotkey("ctrl", "right")
    time.sleep(1.0)
    for index in range(1, 3):
        pyautogui.write(f"vne{index}(x)", interval=0.04)
        pyautogui.press("enter")
        time.sleep(1.0)
    capture(output_dir, run_id, "calculator_vne1_vne2")
    pyautogui.write("vne3(x)", interval=0.04)
    pyautogui.press("enter")
    time.sleep(1.0)
    capture(output_dir, run_id, "calculator_vne1_vne2_vne3")
    print("[calculator] displayed vne1(x), vne2(x), screenshot, then vne3(x) and screenshot")
    pyautogui.hotkey("ctrl", "left")
    time.sleep(1.0)
    capture(output_dir, run_id, "tragwerk_after_calculator")
    print("[frame] returned to the Tragwerk page")


def reenter_symbolic_frame(output_dir: Path, run_id: str) -> None:
    """Rebuild the visible test frame after a Lua code reload/reset."""
    pyautogui.press("c")
    time.sleep(0.8)
    capture(output_dir, run_id, "after_clear")

    # Draw A-C, C-D, and C-B. The application creates a member when the
    # second clicked point is selected or created.
    frame_click(FRAME_POINTS["A"])
    frame_click(FRAME_POINTS["C"])
    frame_click(FRAME_POINTS["D"])
    frame_click(FRAME_POINTS["C"])
    frame_click(FRAME_POINTS["B"])
    frame_click(FRAME_POINTS["C"])
    time.sleep(0.8)
    capture(output_dir, run_id, "frame_geometry")

    # A: vertical support (page 1, row 5); B: horizontal support (row 4).
    frame_menu(FRAME_POINTS["A"], page=1, row=5)
    frame_menu(FRAME_POINTS["B"], page=1, row=4)

    # D: horizontal spring on page 3, row 1.
    frame_menu(FRAME_POINTS["D"], page=3, row=1, text="EI/l^3")

    # C-B: distributed transverse load q on page 1, row 3.
    frame_menu(Point(1975, 1447), page=1, row=3, text="q")
    frame_key("b", pause=2.0)
    capture(output_dir, run_id, "frame_reentered_calculated")


def run(args: argparse.Namespace) -> int:
    if args.run and not args.dry_run:
        require_dependency()
        pyautogui.FAILSAFE = True
        pyautogui.PAUSE = args.interval

    run_id = timestamp()
    output_dir = args.output.resolve()
    save_metadata(output_dir, run_id, args)

    print(f"Output: {output_dir}")
    print("Emergency stop: move the mouse to the top-left screen corner.")
    if args.run and not args.dry_run:
        print("Starting in 3 seconds. Focus the TI-Nspire window now.")
        time.sleep(3.0)

    if args.focus_only:
        if not args.run or args.dry_run:
            print("[focus-only] dry-run")
        else:
            focused = focus_ti_nspire_window()
            capture(output_dir, run_id, "focus_only")
            if not focused:
                raise RuntimeError("Could not activate TI-Nspire")
        print(f"Completed: {run_id}")
        return 0

    if args.calibration_screenshot:
        if not args.run or args.dry_run:
            print("[calibration-screenshot] focus TI-Nspire and overlay calibrated targets")
        else:
            capture_calibration_overlay(output_dir, run_id)
        print(f"Completed: {run_id}")
        return 0

    if args.place_nodes_only:
        if not args.run or args.dry_run:
            print("[place-nodes-only] clear, then place A, C, D, B with screenshots")
        else:
            place_nodes_only(output_dir, run_id)
        print(f"Completed: {run_id}")
        return 0

    if args.place_frame:
        if not args.run or args.dry_run:
            print("[place-frame] sync code -> frame inputs -> export Biegelinien -> calculator screenshot -> Tragwerk page")
        else:
            place_frame_with_supports(output_dir, run_id)
        print(f"Completed: {run_id}")
        return 0

    if args.prepare_statik:
        if not args.run or args.dry_run:
            print("[prepare-statik] dry-run")
        else:
            if not find_statik_page():
                raise RuntimeError("Could not find the Statik Lua page")
            capture(output_dir, run_id, "prepared_statik_page")
        print(f"Completed: {run_id}")
        return 0

    if args.reload_code:
        if not args.run or args.dry_run:
            print("[reload-code] focus Script Editor, paste Biegelinieneu.lua, save")
        else:
            source = Path(__file__).with_name("Biegelinieneu.lua").read_text(encoding="utf-8")
            if not focus_window_with_title("Script Editor"):
                raise RuntimeError("Could not activate Script Editor")
            copy_to_clipboard(source)
            pyautogui.hotkey("ctrl", "a")
            pyautogui.hotkey("ctrl", "v")
            pyautogui.hotkey("ctrl", "s")
            time.sleep(1.5)
            capture(output_dir, run_id, "script_editor_after_reload")
        print(f"Completed: {run_id}")
        return 0

    if args.set_script:
        if not args.run or args.dry_run:
            print("[set-script] focus Script Editor, click Skript festlegen")
        else:
            if not focus_window_with_title("Script Editor"):
                raise RuntimeError("Could not activate Script Editor")
            pyautogui.hotkey("ctrl", "s")
            time.sleep(0.4)
            pyautogui.click(305, 160)
            time.sleep(1.5)
            capture(output_dir, run_id, "script_editor_after_set_script")
        print(f"Completed: {run_id}")
        return 0

    if args.full_cycle:
        if not args.run or args.dry_run:
            print("[full-cycle] reload-code -> set-script -> Statik -> frame -> export -> CAS vne1")
            print(f"Completed: {run_id}")
            return 0
        if not focus_ti_nspire_window():
            raise RuntimeError("Could not activate TI-Nspire before selecting the Tragwerk page")
        pyautogui.hotkey("ctrl", "left")
        time.sleep(1.0)
        capture(output_dir, run_id, "full_cycle_tragwerk_page_selected")
        source = Path(__file__).with_name("Biegelinieneu.lua").read_text(encoding="utf-8")
        if not focus_window_with_title("Script Editor"):
            raise RuntimeError("Could not activate Script Editor")
        copy_to_clipboard(source)
        pyautogui.hotkey("ctrl", "a")
        pyautogui.hotkey("ctrl", "v")
        pyautogui.hotkey("ctrl", "s")
        time.sleep(1.0)
        pyautogui.click(305, 160)
        time.sleep(1.5)
        capture(output_dir, run_id, "full_cycle_script_saved")
        if not focus_ti_nspire_window():
            raise RuntimeError("Could not reactivate the Tragwerk page after code reload")
        time.sleep(1.0)
        calibrated_reenter_frame(output_dir, run_id)
        pyautogui.hotkey("ctrl", "right")
        time.sleep(1.0)
        pyautogui.write("vne1(x)", interval=0.05)
        pyautogui.press("enter")
        time.sleep(2.0)
        capture(output_dir, run_id, "full_cycle_cas_vne1")
        print(f"Completed: {run_id}")
        return 0

    if args.reenter_frame or args.calibrated_reenter:
        if not args.run or args.dry_run:
            mode = "calibrated" if args.calibrated_reenter else "fixed"
            print(f"[reenter-frame:{mode}] clear, draw A-C/D/C-B, set supports, spring, and q")
        elif args.calibrated_reenter:
            if not focus_ti_nspire_window() and not args.no_alt_tab:
                pyautogui.hotkey("alt", "tab")
                time.sleep(1.0)
            calibrated_reenter_frame(output_dir, run_id)
        else:
            reenter_symbolic_frame(output_dir, run_id)
        print(f"Completed: {run_id}")
        return 0

    for step in STEPS:
        if args.no_alt_tab and step.name == "focus_window":
            print("[skip] focus_window")
            continue
        execute_step(step, output_dir, run_id, args)

    print(f"Completed: {run_id}")
    return 0


def main() -> int:
    try:
        return run(parse_args())
    except KeyboardInterrupt:
        print("Aborted by user.", file=sys.stderr)
        return 130
    except Exception as error:
        print(f"ERROR: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
