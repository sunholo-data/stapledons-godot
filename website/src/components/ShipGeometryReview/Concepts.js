import React, {useState} from 'react';
import styles from './styles.module.css';
import concepts from './tierConcepts.json';
const refs='https://storage.googleapis.com/stapledons-voyage-assets/refs/ship_tier_concepts_v1';
const briefs={
 bridge:['Decision balcony','Preserve the existing bridge and thin needle; explore consoles, seating and finish. Root every frond in the measured rim. The painted spire width and sky are illustrative.'],
 commons:['Shared civic terraces','Civic hall, market, dining, conversation courts and guest rooms. Start with one pavilion beside the demo lift. A 10 m roof requires a radius of at most 67.35 m; the outer promenade stays low. The small bridge covers only the central portion.'],
 homes:['Courtyard neighbourhoods','Two- and three-storey homes, clinic and school around shaded public lanes. Start with one dwelling/courtyard kit. A 10 m roof must fit within radius 85.21 m. Keep private rooms enclosed and shared paths open.'],
 garden:['Remembrance and ecology','A 15–20 m canopy, shallow ponds, quiet paths and small pavilions. Test one 20 m tree with its whole crown inside radius 91.08 m. The next slab underside is +31 m, giving 24 m clearance over this floor. Include artificial cultivation lighting.'],
 workshops:['Making, learning and neighbourhood life','Public workshops, academy rooms and modest homes beneath the real upper slab. Block one workshop frontage and pedestrian route first; use human-sized equipment within the grand volume.'],
 farms:['Cultivation and environmental systems','Separate staple beds, rack crops, algae tanks and water processing. Reserve lit crop shelves, access galleries, service aisles and maintenance clearance. Crop area, power and heat budgets remain to be designed.'],
 engineering:['Repair and stewardship','Internal robot cradles, reclamation and replaceable plant. Begin with one service bay and external generator interfaces. No external spacecraft dock or boundary-crossing passage; the lower bowl equipment layout remains open.'],
};
export default function TierConcepts(){
 const [index,setIndex]=useState(1);
 const d=concepts[index];
 const top=d.z+d.concept_height_m;
 const roofRadius=Math.min(d.r,Math.sqrt(95*95-Math.max(d.z*d.z,top*top)));
 return <section className={styles.review} aria-label="Seven tier concept proposals">
  <div className={styles.controls} role="group" aria-label="Choose a tier">{concepts.map((c,i)=><button type="button" key={c.id} aria-pressed={i===index} onClick={()=>setIndex(i)}>{i===0?'Bridge':`Level ${i}`}</button>)}</div>
  <h3>{d.title}</h3>
  <figure className={styles.capture}><a href={`${refs}/${d.id}.png`}><img key={d.id} src={`${refs}/${d.id}.jpg`} alt={`${d.title}: proposed hand-painted architectural concept`}/></a><figcaption>Proposed style and zoning · AI-generated · geometry and illustrative sky are not measurement or physics evidence. <a href={`${refs}/${d.id}.png`}>Full-resolution image</a></figcaption></figure>
  <div className={styles.models}>
   <article className={styles.card}><h4>{briefs[d.id][0]}</h4><p>{briefs[d.id][1]}</p><dl><dt>Measured floor</dt><dd>Z {d.z>0?'+':''}{d.z} m · diameter {(d.r*2).toFixed(2)} m</dd><dt>Ideal gross disc area</dt><dd>{Math.round(d.area_m2).toLocaleString('en-US')} m²; usable area not yet surveyed</dd><dt>First height study</dt><dd>{d.concept_height_m} m above floor; building/crown extent checked in Blender</dd></dl></article>
   <figure className={styles.card}>
    <svg viewBox="-112 -112 224 224" role="img" aria-label={`Measured ship section highlighting ${d.title} and a ${d.concept_height_m} metre height study`} style={{width:'100%',maxHeight:340}}>
     <circle r="100" fill="none" stroke="#888" strokeWidth="1"/>
     <circle r="95" fill="none" stroke="#477d86" strokeDasharray="2 3" strokeWidth="1"/>
     {concepts.map(c=><line key={c.id} x1={-c.r} x2={c.r} y1={-c.z} y2={-c.z} stroke={c.id===d.id?'#387783':'#bbb'} strokeWidth={c.id===d.id?2.5:1}/>) }
     <rect x={-roofRadius} y={-top} width={2*roofRadius} height={d.concept_height_m} fill="#d3a850" fillOpacity=".22" stroke="#a97728" strokeWidth=".7"/>
     <line x1="0" x2="0" y1="-98" y2="88" stroke="#a79e8b" strokeWidth="1"/>
    </svg>
    <figcaption>Measured section: grey boundary = 100 m; dashed inner circle = 95 m; teal = selected floor; amber = proposed height study. This spans a geometric envelope, not a proposed solid building across the deck. The existing needle remains a 98 m exception.</figcaption>
   </figure>
  </div>
  <p><a href={`${refs}/README.md`}>Complete art and Blender brief</a> · <a href={`${refs}/prompts.json`}>Exact generation prompts</a></p>
 </section>;
}
