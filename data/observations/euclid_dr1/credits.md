# Euclid observation starter pack

This non-commercial game uses Euclid DR1-Foundation observations, DOI
[10.57780/esa-d079c51](https://doi.org/10.57780/esa-d079c51).

Science field and catalogue: **Data from ESA Euclid/Euclid Consortium/NASA/DR1-2026.**
Licensed under [CC BY-NC 3.0 IGO](https://creativecommons.org/licenses/by-nc/3.0/igo/).
[Release terms and credits](https://www.cosmos.esa.int/web/euclid/dr1-data-credits).
The VIS field is display-processed in Godot using the manifest's documented
monochrome logarithmic stretch; original science hashes/calibration are retained.

The published M81, NGC 1291 and Abell 3128 colour images are credited to
ESA/Euclid/Euclid Consortium/NASA, image processing by J.-C. Cuillandre and E. Bertin,
under each linked ESA image page's **CC BY-SA 3.0 IGO** option. Those composites are
retained as unregistered archival plates. Their original observation dates are
not inferred from their November 2026 publication dates. See individual URLs,
licences, modifications and hashes in `manifest.json`.
The colour products are resized into display levels and re-encoded as PNG tiles
with one-pixel gutters; these display derivatives retain the same attribution
and CC BY-SA 3.0 IGO terms. The source composites are retained separately.

The independent registration report describes five empirical source centroids,
the analytical TAN oracle and its limitations. The scratch oracle is an independent
reference, not a production pipeline step. Science source IDs preserve release,
table, tile and object identity; raw `object_id` alone is not guaranteed unique.
Quality flags are preserved, and galaxy/star morphology is not inferred from the
display or the imported probability fields.
