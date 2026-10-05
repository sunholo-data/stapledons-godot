import React, {useState} from 'react';
import styles from './styles.module.css';
const base='https://storage.googleapis.com/stapledons-voyage-assets/refs';
const views=[
 ['ship_unified_v1/native/captain_default.png','Bridge · standing captain eye'],
 ['ship_unified_v1/native/captain_inward.png','Bridge · looking inward'],
 ['ship_unified_v1/native/captain_overlook.png','Bridge · overlook toward lower tiers'],
 ['ship_unified_v1/native/third_person_3m.png','Bridge · optional third-person pullback'],
 ['ship_identification_v1/native_900_card.png','Known-star inspection · factual card'],
 ['ship_identification_v1/live_boosting.png','Committed journey · acceleration'],
 ['ship_identification_v1/live_braking.png','Committed journey · braking'],
];
export default function UnifiedReview(){
 const [selected,setSelected]=useState(0);
 const [path,label]=views[selected];
 return <section className={styles.review} aria-label="Unified painted ship review">
  <div className={styles.controls}><label>Review view <select value={selected} onChange={e=>setSelected(Number(e.target.value))}>{views.map(([,name],i)=><option key={name} value={i}>{name}</option>)}</select></label></div>
  <figure className={styles.capture}><a href={`${base}/${path}`}><img src={`${base}/${path}`} alt={label} loading="lazy"/></a><figcaption>{label} · native game capture</figcaption></figure>
  <p className={styles.hint}>Paint follows the 3D surfaces. These are game views; the orbitable model above is a construction diagnostic.</p>
 </section>;
}
