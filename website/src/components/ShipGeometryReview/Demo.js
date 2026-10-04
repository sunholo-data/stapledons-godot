import React, {useEffect} from 'react';
import useBaseUrl from '@docusaurus/useBaseUrl';
import styles from './styles.module.css';
const refs='https://storage.googleapis.com/stapledons-voyage-assets/refs/ship_demo_v1';
export default function ShipDemoReview() {
 useEffect(()=>{import('@google/model-viewer').catch(()=>{});},[]);
 const model=useBaseUrl('/models/ship-demo-v1/ship.glb');
 return <section className={styles.review} aria-label="Playable geometry demo reference">
  <model-viewer src={model} poster={`${refs}/overview_blender.png`} alt="Seven-tier ship with real floor openings and a lift between bridge and the first lower tier" camera-controls="" touch-action="pan-y" camera-orbit="35deg 70deg 340m" camera-target="0m 0m 0m" field-of-view="45deg" min-camera-orbit="auto auto 5m" max-camera-orbit="auto auto 650m" loading="eager" class={styles.viewer}/>
  <p>Drag to orbit and zoom. This demo model adds the lift shaft and actual floor openings to the chosen seven-tier dimensions.</p>
  <div className={styles.downloads}><a href={`${refs}/ship_geometry_demo_v1.blend`}>Demo Blender master</a><a href={`${refs}/ship.glb`}>Game GLB</a><a href={`${refs}/manifest.json`}>Dimensions and asset manifest</a></div>
  <div className={styles.models}>{[['overlook','Bridge overlook — next tier beneath the rails'],['lift_midway','Lift midway — same observer moves through the shaft'],['lower_landing','First lower tier — bounded landing'],['overview','Whole ship — external inspection camera']].map(([id,caption])=><figure key={id} className={styles.capture}><a href={`${refs}/${id}.png`}><img loading="lazy" src={`${refs}/${id}.png`} alt={caption}/></a><figcaption>{caption}</figcaption></figure>)}</div>
 </section>;
}
