import React, {useEffect, useState} from 'react';
import styles from './styles.module.css';
import useBaseUrl from '@docusaurus/useBaseUrl';
import tiers from './tiers.json';
import dense from './dense.json';
const base='https://storage.googleapis.com/stapledons-voyage-assets/refs/ship_dimensions_v2';
const variants=[{id:'tiers', title:'A · Seven tiers — preferred', description:'25 m between deck surfaces. Six lower tiers beneath the bridge.', data:tiers}, {id:'dense', title:'B · Twenty decks — comparison', description:'8.5 m between deck surfaces. Nineteen lower decks beneath the bridge.', data:dense}];
export default function ShipGeometryReview() {
 const modelBase=useBaseUrl('/models/ship-dimensions-v2');
 const [position,setPosition]=useState('rim');
 const [tilt,setTilt]=useState(45);
 const [viewerError,setViewerError]=useState(false);
 useEffect(()=>{import('@google/model-viewer').catch(()=>setViewerError(true));},[]);
 return <section className={styles.review} aria-label="Measured ship alternatives">
  <p className={styles.note}>Revision 2 · Seven-tier direction preferred by Mark · Lower floors follow a 95 m inner sphere, leaving at least 5 m boundary clearance. The clearance remains a review proposal.</p>
  <div className={styles.models}>{variants.map(v=><article key={v.id} className={styles.card}>
   <h3>{v.title}</h3><p>{v.description}</p>
   <model-viewer src={`${modelBase}/ship_dimensions_${v.id}_v2.glb`} poster={`${base}/${v.id}/overview.png`} alt={`${v.title} inside a 200 metre diameter sphere, with the actual bridge at the top`} camera-controls="" touch-action="pan-y" camera-orbit="35deg 70deg 340m" camera-target="0m 0m 0m" field-of-view="45deg" min-camera-orbit="auto auto 5m" max-camera-orbit="auto auto 650m" shadow-intensity="0" exposure="1" loading="eager" class={styles.viewer} />
   <p className={styles.hint}>{viewerError?'Interactive viewer unavailable; open the renders or download the model below.':'Drag to rotate · Scroll or pinch to zoom · Shift-drag to pan'}</p>
   <div className={styles.downloads}><a href={`${base}/ship_dimensions_${v.id}_v2.blend`}>Download Blender</a><a href={`${base}/ship_dimensions_${v.id}_v2.glb`}>Download GLB</a><a href={`${base}/${v.id}/elevation.png`}>Measured elevation</a></div>
   <details><summary>Deck heights and radii in metres</summary><table><thead><tr><th>Level</th><th>Top Z</th><th>Radius</th></tr></thead><tbody><tr><td>Bridge</td><td>82.0</td><td>22.0</td></tr>{v.data.deck_schedule.map(d=><tr key={d.level}><td>{d.level}</td><td>{d.top_z_m.toFixed(1)}</td><td>{d.radius_m.toFixed(2)}</td></tr>)}</tbody></table></details>
  </article>)}</div>
  <h3>Check proportions without foreshortening</h3>
  <p>Both elevations below use the same straight-on orthographic camera. The old lower decks were uniformly 55% of the sphere’s cross-section; their middle decks were not assigned a smaller percentage. The three-quarter projection changes the apparent gaps. The revised floors instead follow an inner spherical envelope.</p>
  <div className={styles.models}><figure className={styles.capture}><a href="https://storage.googleapis.com/stapledons-voyage-assets/refs/ship_dimensions_v1/tiers/elevation.png"><img loading="lazy" src="https://storage.googleapis.com/stapledons-voyage-assets/refs/ship_dimensions_v1/tiers/elevation.png" alt="Previous seven-tier model, straight-on elevation, showing the 55 percent radius rule"/></a><figcaption>Previous · 55% of available horizontal radius at every lower level.</figcaption></figure><figure className={styles.capture}><a href={`${base}/tiers/elevation.png`}><img loading="lazy" src={`${base}/tiers/elevation.png`} alt="Revised seven-tier model, straight-on elevation, with floors following the sphere closely"/></a><figcaption>Revised · at least 5 m clearance to the bubble. The actual bridge remains a smaller platform.</figcaption></figure></div>
  <h3>Look down from the bridge</h3>
  <p>These are fixed perspective renders of the entire model, using the same eye positions and 78° vertical field of view. The free-orbit viewer above is for inspecting the overall shape.</p>
  <div className={styles.controls}><label>Eye position <select value={position} onChange={e=>setPosition(e.target.value)}><option value="rim">Near rim · 0.7 m inside edge</option><option value="interior">Interior · 4.11 m inside edge</option></select></label><label>Downward tilt <select value={tilt} onChange={e=>setTilt(Number(e.target.value))}>{[15,30,45,60].map(t=><option key={t} value={t}>{t}° below horizontal</option>)}</select></label></div>
  <div className={styles.models}>{variants.map(v=>{
   const hit=v.data.views.find(x=>x.view===`${position}_${tilt}`);
   return <figure key={v.id} className={styles.capture}><a href={`${base}/${v.id}/${position}_${tilt}.png`}><img loading="lazy" src={`${base}/${v.id}/${position}_${tilt}.png`} alt={`${v.title}: outward view, ${position} position, tilted ${tilt} degrees below horizontal`}/></a><figcaption><strong>{v.title} · {tilt}° down</strong><br/>Centre ray: {hit.first_hit ? `${hit.first_hit}, ${hit.distance_m.toFixed(1)} m away.`:'clears the modeled ship geometry.'} The whole image can contain surfaces away from its centre.</figcaption></figure>;
  })}</div>
  <details><summary>Camera coordinates and verification</summary><p>Blender coordinates: +Z up/forward, sphere centre (0, 0, 0). Interior eye (16, −8, 83.7) m; rim eye (19.0513, −9.52565, 83.7) m. Both look outward along the same radial bearing. Eye height is 1.7 m above the bridge. Circle guides are hidden in these captures and do not occlude sightlines.</p><p>All physical mesh vertices are inside the 100 m radius sphere. Maximum radius: 98.00 m at the actual needle. The bridge mesh extends to Z 78.30 m at its ramp/underside and Z 98.00 m at its tip; the 44 m dimension describes its main circular deck.</p><p><a href={`${base}/tiers/measurements.json`}>A measurements and centre-ray audit</a> · <a href={`${base}/dense/measurements.json`}>B measurements and centre-ray audit</a></p></details>
 </section>;
}
