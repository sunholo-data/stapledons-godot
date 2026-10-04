import React, {useEffect} from 'react';
import useBaseUrl from '@docusaurus/useBaseUrl';
import styles from './styles.module.css';
const refs='https://storage.googleapis.com/stapledons-voyage-assets/refs/ship_commons_v2';
export default function CommonsReview(){
 useEffect(()=>{import('@google/model-viewer').catch(()=>{});},[]);
 const model=useBaseUrl('/models/ship-commons-v1/full_assembly.glb');
 return <section className={styles.review} aria-label="First Commons architectural model">
  <model-viewer src={model} poster={`${refs}/external_diagnostic.png`} alt="Measured seven-tier ship with a Commons pavilion and courtyard beside the bridge lift" camera-controls="" touch-action="pan-y" camera-orbit="35deg 70deg 340m" camera-target="0m 0m 0m" field-of-view="45deg" min-camera-orbit="auto auto 5m" max-camera-orbit="auto auto 650m" class={styles.viewer}/>
  <p>Whole-ship assembly inspection; exterior orbit is diagnostic. The interior captures below establish actual player sightlines. This expanded area adds a planted terrace, canopy and reading furniture. It remains a reusable painted-material proof, not final dressing of the whole ship.</p>
  <div className={styles.downloads}><a href={`${refs}/stapledon_ship_commons_v2.blend`}>Editable Blender master</a><a href={`${refs}/full_assembly.glb`}>Complete visual assembly GLB</a><a href={`${refs}/manifest.json`}>Dimensions, materials and modular kit</a></div>
  <div className={styles.models}>{[['bridge_overlook','Bridge overlook: floor and rail block most of the nearby Commons'],['arrival','Commons lift arrival: a real guarded connection'],['courtyard','Courtyard: approximately 8 m pavilion, human-scale doors'],['pavilion_inside','Inside the pavilion: opaque roof and walls'],['reverse_to_bridge','Looking back up: actual bridge underside'],['pavilion_back','Reverse angle: painted surfaces continue around the building'],['planted_terrace','Planted terrace: canopy, seating and open circulation'],['interior_reading','Inside the pavilion: reusable reading and seating modules']].map(([name,caption])=><figure key={name} className={styles.capture}><a href={`${refs}/${name}.png`}><img src={`${refs}/${name}.png`} loading="lazy" alt={caption}/></a><figcaption>{caption}</figcaption></figure>)}</div>
  <p>The pavilion is 14 × 12 m, with an approximately 8.1 m roof. The bounded court is 22 × 30 m. All new geometry fits inside the 95 m architectural envelope; this first area is well inward of the boundary. Scale figures are 1.7 m references, not new crew characters.</p>
  <p>The detailed kit uses one embedded brush atlas and opaque material. A simpler distant representation keeps the major roof, walls, ribs and rail silhouettes. Gameplay collision and walking data remain separate from decorative geometry.</p>
 </section>;
}
