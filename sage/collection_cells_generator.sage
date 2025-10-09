###########################################################################################
# SageMath Script: Generation of Collections of Cells
#
# Purpose:
#   Generates all distinct weakly connected collections of cells (polyplets) of rank n.
#   Each shape is represented as a set of cells (x, y) and canonicalized 
#   up to rotations and reflections.
#
# Output:
#   - Saved in Macaulay2-friendly format as a .txt file.
#   - Format: { {{x1,y1},{x1+1,y1+1}}, ... }
#
# Usage:
#   1. Set desired order with n = <number>.
#   2. Run in SageMath.
#   3. Generated file will be saved as weak_polyplets_n<n>.txt in Macaulay2-friendly format
###########################################################################################

import time

# ------------------- Geometry Utilities -------------------

def normalize(cells):
    """Translate shape so that its smallest x and y become 0, then sort the cells."""
    min_x = min(x for x, y in cells)
    min_y = min(y for x, y in cells)
    return tuple(sorted((x - min_x, y - min_y) for x, y in cells))

def rotate90(cells):
    """Rotate shape 90 degrees counterclockwise."""
    return tuple((-y, x) for x, y in cells)

def reflect(cells):
    """Reflect shape across the vertical axis (y-axis)."""
    return tuple((-x, y) for x, y in cells)

def all_symmetries(cells):
    """Return all 8 symmetries of a shape: 4 rotations and their reflections."""
    forms = []
    current = cells
    for _ in range(4):
        current = rotate90(current)
        forms.append(normalize(current))       # add rotated form
        forms.append(normalize(reflect(current)))  # add reflected form
    return forms

def canonical_form(cells):
    """Return the canonical form of a shape (minimum among all symmetries)."""
    return tuple(min(all_symmetries(cells)))

# ------------------- Neighbor Utilities -------------------

def neighbors_weak(cell):
    """Return all 8 neighbors (edge- or corner-adjacent) of a cell."""
    x, y = cell
    return [(x+dx, y+dy) for dx in (-1, 0, 1) for dy in (-1, 0, 1) if not (dx == 0 and dy == 0)]

# ------------------- Polyplet Generation -------------------

def generate_free_weakly_connected(n):
    """
    Generate all distinct weakly connected shapes of n cells.
    Shapes are free, i.e., unique up to rotations and reflections.
    """
    seen = set()  # store canonical forms to avoid duplicates

    def grow(poly, excl):
        """Recursively grow a polyplet by adding neighboring cells."""
        if len(poly) == n:
            seen.add(canonical_form(poly))
            return
        frontier = set()  # potential new cells to add
        new_excl = set()  # keep track of excluded cells to avoid duplicates
        for cell in poly:
            for nb in neighbors_weak(cell):
                if nb not in poly and nb not in excl:
                    frontier.add(nb)
        for new_cell in frontier:
            grow(poly | {new_cell}, excl | new_excl)  # recursive growth
            new_excl.add(new_cell)

    grow({(0, 0)}, set())  # start from the origin
    return seen

# ------------------- Output Formatting -------------------

def to_diagonal_format(cells):
    """Convert set of cells [(x,y), ...] to diagonal format [[[x,y],[x+1,y+1]], ...] for M2."""
    return [[[x, y], [x + 1, y + 1]] for x, y in cells]

def format_as_curly_braces(obj):
    """Convert Python-style lists [ ] to curly braces { } for Macaulay2 compatibility."""
    return repr(obj).replace('[', '{').replace(']', '}')

# ------------------- Main Execution -------------------

n = 8  # Order of the polyplet

start = time.perf_counter()
shapes = generate_free_weakly_connected(n)  # generate all weakly connected shapes
end = time.perf_counter()

# Print execution info
print(f"Execution time: {end - start:.2f} seconds")
print(f"Number of weakly connected shapes of order {n}: {len(shapes)}")

# Write shapes to file in Macaulay2-friendly format
filename = f"weak_polyplets_n{n}.txt"
with open(filename, 'w') as f:
    f.write("{\n")  # start of list
    for i, shape in enumerate(shapes):
        diag = to_diagonal_format(shape)
        s = format_as_curly_braces(diag)
        if i < len(shapes) - 1:
            f.write(f"  {s},\n")  # separate shapes with commas
        else:
            f.write(f"  {s}\n")  # last element without comma
    f.write("}\n")  # end of list

