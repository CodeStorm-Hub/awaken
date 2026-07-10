"""One-off script: forks the OpenFreeMap "dark" style JSON and re-paints it
with Awaken's AppColors tokens so the vector basemap matches the app's neon
dark theme instead of OpenFreeMap's stock palette. Not part of the app build;
re-run manually if OpenFreeMap's upstream style changes.

Usage: python tool/retheme_map_style.py <source_style.json> <output.json>
"""

import json
import sys

# Exact string replacements against known OpenFreeMap "dark" style paint
# values, keyed by (layer id, paint property) so unrelated layers that
# happen to share a color aren't accidentally retouched.
REPAINT = {
    ("background", "background-color"): "rgb(0,0,0)",
    ("water", "fill-color"): "rgb(8,14,26)",
    ("landcover_ice_shelf", "fill-color"): "rgb(0,0,0)",
    ("landuse_residential", "fill-color"): "rgb(14,14,14)",
    ("landcover_wood", "fill-color"): "rgb(14,26,20)",
    ("landuse_park", "fill-color"): "rgb(14,26,20)",
    ("waterway", "line-color"): "rgb(8,14,26)",
    ("building", "fill-color"): "rgb(16,16,16)",
    ("building", "fill-outline-color"): "rgb(34,34,34)",
    ("road_area_pier", "fill-color"): "rgb(0,0,0)",
    ("road_pier", "line-color"): "rgb(0,0,0)",
    ("highway_path", "line-color"): "rgb(40,40,42)",
    ("highway_minor", "line-color"): "#242424",
    ("highway_major_casing", "line-color"): "rgba(74,158,255,0.22)",
    ("highway_major_inner", "line-color"): "rgb(28,28,30)",
    ("highway_major_subtle", "line-color"): "#303030",
    ("highway_motorway_casing", "line-color"): "rgba(74,158,255,0.32)",
    ("highway_motorway_subtle", "line-color"): "#242424",
    ("railway_transit", "line-color"): "rgb(42,42,44)",
    ("railway_transit_dashline", "line-color"): "rgb(0,0,0)",
    ("railway_minor", "line-color"): "rgb(42,42,44)",
    ("railway_minor_dashline", "line-color"): "rgb(0,0,0)",
    ("railway", "line-color"): "rgb(42,42,44)",
    ("railway_dashline", "line-color"): "rgb(0,0,0)",
    ("highway_name_other", "text-color"): "rgb(158,158,158)",
    ("highway_name_motorway", "text-color"): "rgb(140,140,140)",
    ("boundary_state", "line-color"): "rgb(50,50,54)",
    ("boundary_country_z0-4", "line-color"): "rgb(60,55,70)",
    ("boundary_country_z5-", "line-color"): "rgb(60,55,70)",
}

PLACE_LAYER_PREFIX = "place_"
PLACE_TEXT_COLOR = "rgb(140,140,140)"


def repaint(style: dict) -> dict:
    for layer in style.get("layers", []):
        layer_id = layer.get("id", "")
        paint = layer.get("paint", {})

        for (target_id, prop), value in REPAINT.items():
            if layer_id == target_id and prop in paint:
                paint[prop] = value

        # All place-label layers share the same muted foreground tone for
        # consistency, rather than special-casing each rank/class.
        if layer_id.startswith(PLACE_LAYER_PREFIX) and "text-color" in paint:
            paint["text-color"] = PLACE_TEXT_COLOR

    return style


def main() -> None:
    if len(sys.argv) != 3:
        print(__doc__)
        sys.exit(1)

    src_path, out_path = sys.argv[1], sys.argv[2]
    with open(src_path, "r", encoding="utf-8") as f:
        style = json.load(f)

    style = repaint(style)

    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(style, f, indent=2)
        f.write("\n")

    print(f"Wrote re-themed style to {out_path}")


if __name__ == "__main__":
    main()
