import React, {useState} from 'react';
import styles from './styles.module.css';
const refs='https://storage.googleapis.com/stapledons-voyage-assets/refs/ship_demo_brightness_v1';
export default function JourneyReview(){
 const [state,setState]=useState('cruise');
 const [brightness,setBrightness]=useState(1);
 const [view,setView]=useState('forward');
 const [skyOnly,setSkyOnly]=useState(false);
 const name=`${state}_${view}_b${brightness}${skyOnly?'_sky_only':''}`;
 return <section className={styles.review} aria-label="Simulation sky from inside the ship">
  <div className={styles.controls} role="group" aria-label="Sky snapshot">{[['rest','At rest'],['cruise','Mid-journey · 0.99c']].map(([id,label])=><button key={id} type="button" aria-pressed={state===id} onClick={()=>setState(id)}>{label}</button>)}</div>
  <div className={styles.controls} role="group" aria-label="Look direction">{[['forward','Forward / up'],['side','Side'],['aft','Aft / down']].map(([id,label])=><button key={id} type="button" aria-pressed={view===id} onClick={()=>setView(id)}>{label}</button>)}</div>
  <div className={styles.controls} role="group" aria-label="Sky exposure">{[[0,'Calibrated baseline'],[1,'2× exposure trial'],[2,'4× exposure trial'],[4,'16× exposure trial'],[6,'64× exposure trial']].map(([id,label])=><button key={id} type="button" aria-pressed={brightness===id} onClick={()=>setBrightness(id)}>{label}</button>)}</div>
  <div className={styles.controls}><button type="button" aria-pressed={skyOnly} onClick={()=>setSkyOnly(!skyOnly)}>{skyOnly?'Show opaque ship':'Hide ship · sky-only diagnostic'}</button></div>
  <figure className={styles.capture}><a href={`${refs}/${name}.png`}><img src={`${refs}/${name}.png`} alt={`${state==='cruise'?'0.99c cruise':'At rest'}, looking ${view} from the bridge${skyOnly?', with the ship hidden for sky inspection':''}`}/></a><figcaption>Captain eye at +83.7 m; 78° vertical field of view. Camera turns; travel direction stays fixed. {brightness===0?'Calibrated baseline.':`${2**brightness}× exposure is a display aid; physical inputs are unchanged.`} {skyOnly?'Diagnostic: ship deliberately hidden.':'Opaque geometry correctly masks the sky.'} Forward/aft presets avoid the camera pole by 0.5°.</figcaption></figure>
  <p>Frozen AILANG snapshots of the same Sol → Alpha Centauri heading: departure and halfway cruise. Star positions use the simulation's observer position; speed and gamma come from the simulation. This is a repeatable sky review, not the active voyage or a planet flyby.</p>
  <p><a href={`${refs}/manifest.json`}>Camera and simulation audit</a> · <a href={`https://storage.googleapis.com/stapledons-voyage-assets/refs/ship_demo_journey_v1/optics_audit.json`}>81-case GPU projection check</a></p>
 </section>;
}
