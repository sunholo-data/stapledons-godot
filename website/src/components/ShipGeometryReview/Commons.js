import React, {useEffect, useState} from 'react';
import useBaseUrl from '@docusaurus/useBaseUrl';
import styles from './styles.module.css';
const refs='https://storage.googleapis.com/stapledons-voyage-assets/refs/ship_commons_v2';
const views=[['planted_terrace','Planted terrace'],['interior_reading','Pavilion reading area'],['courtyard','Courtyard'],['arrival','Lift arrival'],['bridge_overlook','Bridge overlook · floor and rail block most of the Commons'],['reverse_to_bridge','Looking back toward the bridge'],['pavilion_back','Pavilion reverse angle']];
export default function CommonsReview(){
 const [view,setView]=useState(views[0][0]);
 useEffect(()=>{import('@google/model-viewer').catch(()=>{});},[]);
 const model=useBaseUrl('/models/ship-commons-v1/full_assembly.glb?revision=2');
 return <section className={styles.review} aria-label="Current Commons architectural model">
  <model-viewer src={model} poster={`${refs}/external_diagnostic.png`} alt="Measured seven-tier ship with a Commons pavilion and courtyard beside the bridge lift" camera-controls="" touch-action="pan-y" camera-orbit="35deg 70deg 340m" camera-target="0m 0m 0m" field-of-view="45deg" min-camera-orbit="auto auto 5m" max-camera-orbit="auto auto 650m" class={styles.viewer}/>
  <p className={styles.hint}>Drag to orbit · Scroll or pinch to zoom. Select a player view below.</p>
  <div className={styles.downloads}><a href={`${refs}/stapledon_ship_commons_v2.blend`}>Editable Blender master</a><a href={`${refs}/full_assembly.glb`}>Complete visual assembly GLB</a><a href={`${refs}/manifest.json`}>Dimensions, materials and modular kit</a></div>
  <div className={styles.controls}><label>Player view <select value={view} onChange={event=>setView(event.target.value)}>{views.map(([id,label])=><option key={id} value={id}>{label}</option>)}</select></label></div>
  <figure className={styles.capture}><a href={`${refs}/${view}.png`}><img src={`${refs}/${view}.png`} loading="lazy" alt={views.find(([id])=>id===view)[1]}/></a><figcaption>{views.find(([id])=>id===view)[1]} · Commons revision 2</figcaption></figure>
  <details><summary>Commons dimensions and assets</summary><p>Pavilion: 14 × 12 m, roof approximately 8.1 m. Court: 22 × 30 m. Scale figures: 1.7 m. The kit fits inside the 95 m envelope and uses one painted atlas, separate collision and walking data, and simpler distant geometry.</p></details>
 </section>;
}
