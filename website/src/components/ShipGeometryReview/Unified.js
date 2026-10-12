import React, {useState} from 'react';
import styles from './styles.module.css';
const base='https://storage.googleapis.com/stapledons-voyage-assets/refs';
const views=[
 ['solar_departure_v3/acen-a_arrival.png',"Alpha Centauri A · 1 AU"],
 ['solar_departure_v3/jupiter_approach_80s.png',"Jupiter · gradual braking approach"],
 ['solar_departure_v3/earth_start.png',"Earth · close side view"],
 ['solar_departure_v3/sun_arrival.png',"Sun · three solar radii"],
 ['solar_departure_v3/jupiter_arrival.png',"Jupiter · close side view"],
 ['solar_departure_v3/callisto_arrival.png',"Callisto · clearance stop"],
 ['solar_departure_v3/saturn_arrival.png',"Saturn · close rings"],
 ['ship_grounded_v2/grounded_contact.png',"Bridge · restored floor and captain contact"],
 ['solar_departure_v3/CNS5_3627_braking.png',"Outbound toward Alpha Centauri"],
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
  <p className={styles.hint}>Paint follows the 3D surfaces. These are game views. The editable models preserve measured dimensions; concept paintings remain style references.</p>
  <details><summary>Current painted Blender models</summary><p><a href={`${base}/ship_grounded_v2/stapledon_unified_ship_grounded_v2.blend`}>Full ship Blender master</a> · <a href={`${base}/ship_grounded_v2/stapledon_bridge_mesh_grounded_v2.blend`}>Bridge Blender master</a> · <a href={`${base}/ship_grounded_v2/full_assembly.glb`}>Full ship GLB</a> · <a href={`${base}/ship_grounded_v2/asset-pins.json`}>Asset pins</a></p></details>
 </section>;
}
