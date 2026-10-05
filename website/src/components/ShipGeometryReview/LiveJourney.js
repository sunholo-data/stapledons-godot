import React, {useState} from 'react';
import styles from './styles.module.css';
const refs='https://storage.googleapis.com/stapledons-voyage-assets/refs/ship_demo_live_v1';
const views=[['boosting_080','Accelerating · early'],['boosting_300','Accelerating · late'],['cruising_200','Cruising'],['braking_080','Braking · early'],['braking_300','Braking · late'],['at_rest_001','Arrived · rest']];
export default function LiveJourneyReview(){
 const [view,setView]=useState(views[0][0]);
 const label=views.find(([id])=>id===view)[1];
 return <section className={styles.review} aria-label="One committed journey from aboard ship">
  <div className={styles.controls}><label>Journey stage <select value={view} onChange={event=>setView(event.target.value)}>{views.map(([id,title])=><option key={id} value={id}>{title}</option>)}</select></label></div>
  <figure className={styles.capture}><a href={`${refs}/${view}.png`}><img src={`${refs}/${view}.png`} loading="lazy" alt={`${label}: forward sky from the captain's standing bridge position`}/></a><figcaption>{label} · One selected, committed AILANG voyage. Actual velocity and clocks drive the sky; the ship keeps its heading while braking. Captures use the 4× display exposure.</figcaption></figure>
  <div className={styles.downloads}><a href={`${refs}/navigation.png`}>Navigation window</a><a href={`${refs}/manifest.json`}>Sequential simulation states and camera audit</a></div>
 </section>;
}
