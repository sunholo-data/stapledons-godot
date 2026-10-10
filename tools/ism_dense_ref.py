#!/usr/bin/env python3
"""Independent I3b oracle, never a production generator.

Default: checks the committed geometry against independent stellar tracer rows.
--sources FITS LEIKE_H5 CROP_PREFIX: additionally checks raw FITS/crop values,
cloud distances and 20 preselected Fibonacci-sphere columns against Leike2020.
Optional --write-report saves verification evidence, never game data.
Raw mode needs astropy/healpy/h5py/numpy; default needs only the standard library.
"""
import argparse
import csv
import json
import math
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PC_LY = 3.0856775814913673e16 / 9460730472580800.0
PC_CM = 3.0856775814913673e18
RV, NH_EBV = 3.1, 5.8e21
# Published equatorial J2000 -> Galactic matrix, IAU/Hipparcos convention.
ROT = ((-.0548755604162154, -.8734370902348850, -.4838350155487132),
       (.4941094278755837, -.4448296299600112, .7469822444972189),
       (-.8676661490190047, -.1980763734312015, .4559837761750669))


def dot(a, b):
    return sum(x*y for x, y in zip(a, b))


def sky(lon, lat):
    a, b = map(math.radians, (lon, lat))
    return (math.cos(a)*math.cos(b), math.sin(a)*math.cos(b), math.sin(b))


def equatorial(ra, dec):
    v = sky(ra, dec)
    return tuple(dot(row, v) for row in ROT)


def sheet_chord(s, direction, end):
    lo, hi = 0., end * PC_LY
    for p in s['planes']:
        velocity = dot(p['normal'], direction)
        if abs(velocity) < 1e-15:
            if not p['d0_ly'] <= 0. <= p['d1_ly']:
                return None
        else:
            a, b = p['d0_ly']/velocity, p['d1_ly']/velocity
            lo, hi = max(lo, min(a, b)), min(hi, max(a, b))
    return (lo/PC_LY, hi/PC_LY) if hi > lo else None


def ellipse_chord(c, v, end=160.):
    centre = [x/PC_LY for x in c['centre_ly']]
    radii = [x/PC_LY for x in c['radii_ly']]
    a = sum((x/r)**2 for x, r in zip(v, radii))
    b = -2*sum(x*y/r**2 for x, y, r in zip(v, centre, radii))
    cc = sum((x/r)**2 for x, r in zip(centre, radii))-1
    disc = b*b-4*a*cc
    if disc <= 0:
        return None
    lo, hi = max(0., (-b-math.sqrt(disc))/(2*a)), min(end, (-b+math.sqrt(disc))/(2*a))
    return (lo, hi) if hi > lo else None


def rows(path):
    with path.open() as f:
        return list(csv.reader((x for x in f if x.strip() and not x.startswith('#')), delimiter='\t'))


def geometry(data):
    result = {'clumps': len(data['clumps']), 'sheet_triangles': len(data['sheets']), 'llcc': []}
    for name, ra, dec, distance, nai, hi21, cite in rows(ROOT/'data/ism/sources/llcc_members.tsv'):
        v = equatorial(float(ra), float(dec))
        chords = [x for s in data['sheets'] if (x := sheet_chord(s, v, float(distance)))]
        angular = any(sheet_chord(s, v, 250.) for s in data['sheets'])
        result['llcc'].append(dict(name=name, nai=bool(int(nai)), hi21=bool(int(hi21)),
                                   angular_intersection=angular, finite_intersection=bool(chords),
                                   chord_pc=chords, cite=cite))
    result['sol_inside_clump'] = any(sum((x/r)**2 for x, r in zip(c['centre_ly'], c['radii_ly'])) < 1 for c in data['clumps'])
    # Geometry represents the 21cm footprint, not the larger optical absorption envelope.
    expected = {'HD83023': True, 'HD85259': True, 'HD84722': True,
                'HIP47513': False, 'Regulus': False}
    result['llcc_21cm_controls_pass'] = all(x['finite_intersection'] == expected[x['name']]
                                           for x in result['llcc'] if x['name'] in expected)
    result['llcc_all_nai_detections_pass'] = all(x['finite_intersection'] for x in result['llcc'] if x['nai'])
    assert not result['sol_inside_clump'], 'connected-wall ellipsoid filled the solar cavity'
    assert result['llcc_21cm_controls_pass'], 'independent 21cm / foreground controls disagree'
    return result


def raw_checks(data, source, leike, crop):
    import healpy as hp
    import h5py
    import numpy as np
    from astropy.io import fits
    f = fits.open(source, memmap=True)
    mean = f['MEAN'].data
    bounds = f['RADIAL PIXEL BOUNDARIES'].data.field(0).astype(float)
    inner = f['MEAN OF INTEGRATED INNER 68.8 PC'].data
    meta = json.loads(Path(str(crop)+'.json').read_text())
    mapped = np.memmap(str(crop)+'.f32', dtype='<f4', mode='r', shape=(meta['shells'], meta['pixels']))
    assert meta['ordering'] == 'NEST' and mean.shape == (516, 786432)
    assert np.allclose(meta['boundaries_pc'], bounds[:meta['shells']+1], rtol=0, atol=1e-10)
    # Independent Astropy decode vs Godot LE crop; fixed corners + deterministic samples.
    checks = [(s, p) for s in (0, 1, 75, 150) for p in (0, 1, 196607, 393216, 786431)]
    checks += [(i*37 % 151, i*7919 % 786432) for i in range(100)]
    assert all(mapped[s,p] == mean[s,p] for s,p in checks)
    cloud_anchors = [('Taurus', 173.5, -14.2, 147.), ('Ophiuchus',352.7,15.4,139.),
                     ('Lupus',339.0,16.3,151.)]
    distances = []
    for name, lon, lat, published in cloud_anchors:
        v = sky(lon, lat)
        chords = [z for c in data['clumps'] if (z := ellipse_chord(c,v))]
        first = min(z[0] for z in chords) if chords else None
        pix = hp.vec2pix(256,*v,nest=True)
        dense = np.flatnonzero(mean[:,pix] * 2.8 * NH_EBV / RV / PC_CM > 1.)
        raw_first = float(bounds[dense[0]]) if len(dense) else None
        distances.append(dict(cloud=name,l_deg=lon,b_deg=lat,published_pc=published,
                              raw_first_pc=raw_first,ellipsoid_first_pc=first,
                              within_15pc=first is not None and abs(first-published)<=15,
                              cite='Zucker2020 Table A.1, arXiv:2001.00591'))
    # Directions fixed before inspecting either map: Fibonacci20, z=(i+.5)*2/20-1.
    refs = []
    h = h5py.File(leike, 'r')['mean']
    widths = np.maximum(0., np.minimum(bounds[1:],150.) - np.maximum(bounds[:-1],0.))
    for i in range(20):
        z = 1.-2*(i+.5)/20
        phi = i*math.pi*(3.-math.sqrt(5.))
        v = (math.sqrt(1-z*z)*math.cos(phi),math.sqrt(1-z*z)*math.sin(phi),z)
        pix = hp.vec2pix(256,*v,nest=True)
        eden = (float(inner[pix]) + float(np.dot(mean[:,pix],widths))) * 2.8 / RV
        # Integrate the actual piecewise-constant 1pc Leike voxels, exact ray/grid cuts.
        events = sorted(set([0.,150.] + [k/x for x in v if abs(x)>1e-15
                                        for k in range(-150,151) if 0 < k/x < 150.]))
        tau = sum(float(h[tuple(math.floor(x*(a+b)/2)+o for x,o in zip(v,(370,370,270)))])*(b-a)
                  for a,b in zip(events,events[1:]))
        le = tau * (2.5/math.log(10)) / (.789*RV)
        # The game envelope uses maximum nH in overlaps, never a sum of boxes.
        cuts = [(c,*chord) for c in data['clumps'] if (chord := ellipse_chord(c,v,150.))]
        breaks = sorted(set([0.,150.]+[q for _,a,b in cuts for q in (a,b)]))
        column = sum((b-a)*max([.0039]+[c['n_h_cm3'] for c,s,e in cuts if s < (a+b)/2 < e])
                     for a,b in zip(breaks,breaks[1:]))*PC_CM/NH_EBV
        refs.append(dict(i=i,direction=v,edenhofer_ebv=eden,leike_ebv=le,
                         dense_envelope_hot_background_ebv=column,raw_ratio=eden/le,
                         envelope_ratio=column/le,raw_factor2=.5<=eden/le<=2,
                         envelope_factor2=.5<=column/le<=2))
    return dict(crop_samples=len(checks),cloud_distances=distances,columns=refs,
                column_conversion='Edenhofer A_V=2.8 E_ZGR23 (§7.1); Leike tau_G/pc (Zenodo3993082 README), A_G/A_V=.789 (WangChen2019 Table3); both R_V=3.1',
                raw_factor2_count=sum(x['raw_factor2'] for x in refs),
                envelope_factor2_count=sum(x['envelope_factor2'] for x in refs))


def main():
    p = argparse.ArgumentParser()
    p.add_argument('--sources', nargs=3, metavar=('FITS','LEIKE_H5','CROP_PREFIX'))
    p.add_argument('--write-report', type=Path)
    args = p.parse_args()
    data = json.loads((ROOT/'data/ism/dense.json').read_text())
    report = geometry(data)
    if args.sources:
        report['raw_validation'] = raw_checks(data, *args.sources)
    text = json.dumps(report, indent=2)+'\n'
    print(text)
    if args.write_report:
        args.write_report.write_text(text)


if __name__ == '__main__':
    main()
