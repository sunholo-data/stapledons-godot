import React, {useState} from 'react';
import styles from './styles.module.css';
const base='https://storage.googleapis.com/stapledons-voyage-assets/refs';
const views=[
 ['solar_departure_v1/earth_start.png',"Earth departure"],
 ['solar_departure_v1/jupiter_arrival.png',"Jupiter stop"],
 ['solar_departure_v1/saturn_arrival.png',"Saturn and its rings"],
 ['solar_departure_v1/alpha_centauri_cruising.png',"Outbound toward Alpha Centauri"],
 ['solar_departure_v1/map_second_departure.png',"Navigation from the current ship"],

 ['ship_lighting_v1/bridge_inward_moody.png','Lighting study · bridge inward'],
 ['ship_lighting_v1/bridge_inward_baseline.png','Lighting study · same view before'],
 ['ship_lighting_v1/bridge_outward_moody.png','Lighting study · bridge outlook'],
 ['ship_lighting_v1/commons_arcade_moody.png','Lighting study · Commons shade'],
 ['ship_unified_v1/native/captain_default.png','Bridge · standing captain eye'],
 ['ship_unified_v1/native/captain_inward.png','Bridge · looking inward'],
 ['ship_unified_v1/native/captain_overlook.png','Bridge · overlook toward lower tiers'],
 ['ship_unified_v1/native/third_person_3m.png','Bridge · optional third-person pullback'],
 ['ship_identification_v1/bridge_identify.png','Known-star inspection · Alpha Centauri card'],
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
