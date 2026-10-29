#!/bin/bash
# VF0 authoring recovery: copies sources, opens masters read-only, extracts embedded texts.
# Run from a game clone. Never saves or changes an original Blender scene.
set -euo pipefail
GAME=$(git rev-parse --show-toplevel)
STUDIO=${1:-/Users/voightkampff/dev/blender}
DEST="$GAME/build/view-finish-source"
test ! -e "$DEST" || { echo "Refusing to overwrite preservation directory: $DEST" >&2; exit 1; }
mkdir -p "$DEST/scripts" "$DEST/scenes" "$DEST/inputs" "$DEST/extracted"
: > "$DEST/.gdignore"
for script in configure.py stapledon_bridge_mesh_paint_v1.py stapledon_bridge_mesh_paint_render.py stapledon_bridge_floor_restore_v2.py stapledon_deck_layout_v2.py stapledon_bridge_props_v1.py stapledon_bridge_props_v2.py stapledon_bridge_props_v3.py stapledon_bridge_props_v4.py; do
  cp -p "$STUDIO/scripts/$script" "$DEST/scripts/$script"
done
for scene in stapledon_bridge_mesh_grounded_v2.blend stapledon_bridge_deck_layout_a_v2.blend stapledon_bridge_props_v4.blend; do
  cp -p "$STUDIO/scenes/$scene" "$DEST/scenes/$scene"
done
cp -p "$GAME/art/ship-commons-v1/ship_commons_master_v3.blend" "$DEST/scenes/"
cp -p "$GAME/art/ship-commons-v1/paint-atlas-v1.png" "$GAME/art/deck-layout-v2/bow_a.json" "$GAME/art/deck-layout-v2/asset-pins.json" "$DEST/inputs/"
cp -p "$STUDIO/blender.sh" "$DEST/"
(cd "$STUDIO" && ./blender.sh --background --factory-startup --python-exit-code 1 --python-expr '
import bpy, sys, pathlib, hashlib, json
out = pathlib.Path(sys.argv[sys.argv.index("--")+1])
checks = []
for filename in ["stapledon_bridge_props_v4.blend", "ship_commons_master_v3.blend"]:
    master = out / "scenes" / filename
    bpy.ops.wm.open_mainfile(filepath=str(master), load_ui=False)
    target = out / "extracted" / master.stem
    target.mkdir()
    texts = []
    for i, block in enumerate(bpy.data.texts):
        name = pathlib.Path(block.name).name
        if name in ["", ".", ".."]: name = "text_%03d" % i
        path = target / name
        path.write_text(block.as_string())
        texts.append({"name":block.name,"path":str(path.relative_to(out)),"sha256":hashlib.sha256(path.read_bytes()).hexdigest()})
    images = [{"name":im.name,"packed":bool(im.packed_file or im.packed_files),"source":im.source,"size":list(im.size),"filepath":im.filepath,"missing":im.source == "FILE" and not bool(im.packed_file or im.packed_files) and not pathlib.Path(bpy.path.abspath(im.filepath)).is_file()} for im in bpy.data.images]
    libraries = [{"name":lib.name,"missing":not pathlib.Path(bpy.path.abspath(lib.filepath)).is_file()} for lib in bpy.data.libraries]
    check = {"master":filename,"objects":len(bpy.data.objects),"meshes":len(bpy.data.meshes),"images":images,"libraries":libraries,"texts":texts,"missing_resources":sum(x["missing"] for x in images+libraries)}
    checks.append(check)
files = [{"path":str(p.relative_to(out)),"bytes":p.stat().st_size,"sha256":hashlib.sha256(p.read_bytes()).hexdigest()} for p in sorted(out.rglob("*")) if p.is_file()]
result={"schema":"stapledons.view-finish.sources/1","blender_version":bpy.app.version_string,"status":"local snapshot; remote archive publication pending","masters":checks,"files":files}
(out/"inventory.json").write_text(json.dumps(result,indent=2)+"\n")
assert all(c["missing_resources"] == 0 for c in checks), "Missing master resources"
assert any("commons" in t["name"].lower() and t["name"].endswith(".py") for c in checks if "commons" in c["master"] for t in c["texts"]), "Commons generator not recovered"
print("view-finish-source: masters open; resources present; Commons generator recovered")
' -- "$DEST")
cp "$DEST/inventory.json" "$GAME/art/view-finish-v1/source-inventory.json"
(cd "$GAME/build" && COPYFILE_DISABLE=1 tar -czf view-finish-source.tar.gz view-finish-source)
shasum -a 256 "$GAME/build/view-finish-source.tar.gz"
