import React, {useState} from 'react';
import useBaseUrl from '@docusaurus/useBaseUrl';
import styles from './styles.module.css';
const choices=[['concept','Approved architectural direction'],['plan','Floor-plan proposal'],['finish','Bridge-style finish study']];
export default function CommonsPlanning(){
 const [view,setView]=useState('concept');
 const urls={concept:'https://storage.googleapis.com/stapledons-voyage-assets/refs/ship_tier_concepts_v1/commons.jpg',plan:useBaseUrl('/img/ship-review/commons-plan-proposal-v1.svg'),finish:useBaseUrl('/img/ship-review/commons-bridge-style-v1.png')};
 const captions={concept:'Approved Level 1 direction: sweeping terraces, open arcades, planting and civic life. The measured ship geometry remains authoritative.',plan:'Draft for layout agreement. The teal rectangle is the current small prototype; curved arcade zones and open plaza are proposed. No replacement architecture is built yet.',finish:'AI paintover of the current test pavilion using the painted bridge as reference. Finish only: this is not the approved architecture, an in-game update or a reusable UV texture.'};
 return <section className={styles.review} aria-label="Commons concept and floor plan review"><div className={styles.controls}>{choices.map(([id,label])=><button type="button" key={id} aria-pressed={view===id} onClick={()=>setView(id)}>{label}</button>)}</div><figure className={styles.capture}><a href={urls[view]}><img src={urls[view]} alt={captions[view]}/></a><figcaption>{captions[view]}</figcaption></figure></section>;
}
