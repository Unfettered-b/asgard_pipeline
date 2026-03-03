#!/usr/bin/env python3

import sys
import colorsys
from collections import defaultdict

fasta = sys.argv[1]
output = sys.argv[2]
dataset_label = sys.argv[3]

def hsv_to_hex(h, s=0.85, v=0.9):
    r, g, b = colorsys.hsv_to_rgb(h, s, v)
    return "#{:02x}{:02x}{:02x}".format(
        int(r * 255), int(g * 255), int(b * 255)
    )

leaf_to_label = {}
unique_labels = set()

with open(fasta) as f:
    for line in f:
        if line.startswith(">"):
            header = line[1:].strip()
            parts = header.split()

            leaf = parts[0]

            # Everything after ID becomes label
            label = " ".join(parts[1:]) if len(parts) > 1 else "Unknown"

            leaf_to_label[leaf] = label
            unique_labels.add(label)

unique_labels = sorted(unique_labels)

# Generate distinct colors
n = len(unique_labels)
label_colors = {}

for i, label in enumerate(unique_labels):
    hue = i / n
    label_colors[label] = hsv_to_hex(hue)

# Write iTOL file
with open(output, "w") as out:
    out.write("DATASET_COLORSTRIP\n")
    out.write("SEPARATOR TAB\n")
    out.write("BORDER_WIDTH\t0.5\n")
    out.write("COLOR\t#bebada\n")
    out.write(f"DATASET_LABEL\t{dataset_label}\n")

    # Legend
    out.write("LEGEND_COLORS\t" + "\t".join(label_colors[l] for l in unique_labels) + "\n")
    out.write("LEGEND_LABELS\t" + "\t".join(unique_labels) + "\n")
    out.write("LEGEND_SHAPES\t" + "\t".join(["1"] * n) + "\n")
    out.write("LEGEND_TITLE\t" + dataset_label + "\n")

    out.write("MARGIN\t5\n")
    out.write("STRIP_WIDTH\t25\n")
    out.write("DATA\n")

    for leaf, label in leaf_to_label.items():
        color = label_colors[label]
        out.write(f"{leaf}\t{color}\t{label}\n")