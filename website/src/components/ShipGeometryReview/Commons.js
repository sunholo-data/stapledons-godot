import React, {useEffect, useState} from 'react';
import useBaseUrl from '@docusaurus/useBaseUrl';
import styles from './styles.module.css';
const refs='https://storage.googleapis.com/stapledons-voyage-assets/refs/ship_commons_v3';
const unified='https://storage.googleapis.com/stapledons-voyage-assets/refs/ship_grounded_v2';
const views=[['courtyard','Plaza toward the new arcade'],['arcade_inside','Inside the open arcade'],['arcade_along','Along the curved arcade'],['planted_plaza','Planted civic plaza'],['arrival','Lift arrival'],['bridge_overlook','Bridge overlook · floor and rail occlude the centre view'],['reverse_to_bridge','Looking back toward the bridge']];
export default function CommonsReview(){
 const [view,setView]=useState(views[0][0]);
 const [focus,setFocus]=useState(false);
 useEffect(()=>{import('@google/model-viewer').catch(()=>{});},[]);
 const model=useBaseUrl('/models/ship-commons-v1/full_assembly.glb?revision=5');
 return <section className={styles.review} aria-label="Current Commons architectural model">
  <div className={styles.controls}><button type="button" aria-pressed={!focus} onClick={()=>setFocus(false)}>Whole ship</button><button type="button" aria-pressed={focus} onClick={()=>setFocus(true)}>Inspect Commons</button></div>
  <model-viewer src={model} poster={`${refs}/external_diagnostic.png`} alt="Measured seven-tier ship with an open curved Commons arcade, civic plaza and walking connection from the bridge lift" camera-controls="" touch-action="pan-y" camera-orbit={focus?'115deg 70deg 52m':'35deg 70deg 340m'} camera-target={focus?'47m 59m -5m':'0m 0m 0m'} field-of-view="45deg" min-camera-orbit="auto auto 5m" max-camera-orbit="auto auto 650m" class={styles.viewer}/>
  <p className={styles.hint}>Drag to orbit · Scroll or pinch to zoom. Model orbit is diagnostic; screenshots below use physical player positions.</p>
  <div className={styles.downloads}><a href={`${unified}/stapledon_unified_ship_grounded_v2.blend`}>Editable painted Blender master</a><a href={`${unified}/full_assembly.glb`}>Current visual assembly GLB</a><a href={`${refs}/manifest.json`}>Commons dimensions and modular kit</a></div>
  <div className={styles.controls}><label>Player view <select value={view} onChange={event=>setView(event.target.value)}>{views.map(([id,label])=><option key={id} value={id}>{label}</option>)}</select></label></div>
  <figure className={styles.capture}><a href={`${refs}/${view}.png`}><img src={`${refs}/${view}.png`} loading="lazy" alt={views.find(([id])=>id===view)[1]}/></a><figcaption>{views.find(([id])=>id===view)[1]} · Commons revision 3</figcaption></figure>
  <details><summary>Commons dimensions and assets</summary><p>The first arcade occupies radii 43–55 m in the approved outer building band, linked to the 22 × 30 m plaza by a guarded walk. Scale figures are 1.7 m. Geometry is checked against the 95 m inner envelope. Painted modules, separate collision and walking data, and simpler distant geometry derive from the same Blender master.</p></details>
 </section>;
}
