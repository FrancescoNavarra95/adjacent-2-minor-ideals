# plot_collections_file_block.py
import re
from pathlib import Path
from datetime import datetime

# Regex to capture pairs of points {{x,y},{x,y}}
pair_re = re.compile(
    r'\{\s*\{\s*(-?\d+)\s*,\s*(-?\d+)\s*\}\s*,\s*\{\s*(-?\d+)\s*,\s*(-?\d+)\s*\}\s*\}'
)


def parse_rows_from_file(filepath: Path):
    """
    Read the .txt file and return a list of rows.
    Each row corresponds to a collection of unit cells.
    """
    text = filepath.read_text().strip()

    # Remove outer braces if present
    if text.startswith("{") and text.endswith("}"):
        text = text[1:-1].strip()

    # Split into collections by tracking balanced braces
    raw_rows = []
    buffer = ""
    open_braces = 0
    for ch in text:
        buffer += ch
        if ch == "{":
            open_braces += 1
        elif ch == "}":
            open_braces -= 1
        if open_braces == 0 and buffer.strip():
            raw_rows.append(buffer.strip().rstrip(","))
            buffer = ""

    rows = []
    for line in raw_rows:
        matches = pair_re.findall(line)
        cells = []
        for (x1, y1, x2, y2) in matches:
            x1, y1, x2, y2 = map(int, (x1, y1, x2, y2))
            xmin, ymin = min(x1, x2), min(y1, y2)
            dx, dy = abs(x2 - x1), abs(y2 - y1)

            # Decompose rectangles into unit squares
            for xi in range(xmin, xmin + dx):
                for yi in range(ymin, ymin + dy):
                    cells.append((xi, yi))

        if cells:
            rows.append(sorted(set(cells)))
    return rows


def plot_rows(rows, out_dir: Path, prefix: str = "cells_row"):
    """
    Generate PNG images for each row (collection of cells).
    """
    try:
        import matplotlib.pyplot as plt
        from matplotlib.patches import Rectangle
    except ImportError:
        print("Matplotlib is not installed. Skipping image generation.")
        return False

    out_dir.mkdir(parents=True, exist_ok=True)

    for idx, cells in enumerate(rows, start=1):
        xs = [c[0] for c in cells]
        ys = [c[1] for c in cells]

        xmin, xmax = min(xs) - 0.5, max(xs) + 1 + 0.5
        ymin, ymax = min(ys) - 0.5, max(ys) + 1 + 0.5

        fig, ax = plt.subplots(figsize=(4, 4))
        fig.patch.set_facecolor("white")
        ax.set_facecolor("white")

        # Draw unit cells
        for (x, y) in cells:
            ax.add_patch(Rectangle(
                (x, y), 1, 1,
                facecolor="lightgray",
                edgecolor="black",
                linewidth=1.2
            ))

        ax.axis("off")
        ax.set_xlim(xmin, xmax)
        ax.set_ylim(ymin, ymax)
        ax.set_aspect("equal")

        plt.tight_layout(pad=0)
        fname = out_dir / f"{prefix}_{idx}.png"
        plt.savefig(fname, dpi=200, bbox_inches="tight", pad_inches=0, facecolor="white")
        plt.close(fig)
        print(f"[OK] Saved image: {fname}")

    return True


if __name__ == "__main__":
    # Input file must be in the same folder as this script
    filepath = Path(__file__).parent / "input_collections.txt"

    rows = parse_rows_from_file(filepath)
    print(f"Parsing completed: {len(rows)} collections found.")

    # Create output folder with timestamp (in the same directory as the script)
    base_dir = Path(__file__).parent
    timestamp = datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
    out_dir = base_dir / timestamp
    out_dir.mkdir(parents=True, exist_ok=True)

    # Save images
    plot_rows(rows, out_dir=out_dir)
    print(f"[OK] Output folder: {out_dir}")
