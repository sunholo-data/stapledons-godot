import React from 'react';
import tiers from './tiers.json';
const base='https://storage.googleapis.com/stapledons-voyage-assets/refs/ship_dimensions_v2';
export default function ShipGeometryReview(){
 return <details>
  <summary>Measured geometry reference</summary>
  <p>Coordinates are metres, with Blender +Z up/forward. Lower tiers are 25 m apart, with 1 m slabs. Roofs and tree crowns must also fit the 95 m inner envelope at their actual heights. The existing needle is the retained exception.</p>
  <table><thead><tr><th>Level</th><th>Floor Z (m)</th><th>Radius (m)</th></tr></thead><tbody><tr><td>Bridge</td><td>82.0</td><td>22.00</td></tr>{tiers.deck_schedule.map(d=><tr key={d.level}><td>{d.level}</td><td>{d.top_z_m.toFixed(1)}</td><td>{d.radius_m.toFixed(2)}</td></tr>)}</tbody></table>
  <p><a href={`${base}/tiers/elevation.png`}>Measured elevation</a> · <a href={`${base}/tiers/measurements.json`}>Geometry and sightline audit</a></p>
 </details>;
}
