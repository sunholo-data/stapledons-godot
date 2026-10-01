import subprocess,pathlib,hashlib,json
root=pathlib.Path('/Users/voightkampff/dev/sunholo-data/.stapledon-wt-iter7'); p=root/'sim/tools/catalogue.ail'; orig=p.read_bytes(); src=orig.decode(); A='/Users/voightkampff/dev/sunholo-data/.stapledon-wt-iter4/runtime/bin/ailang'
mutants=[
('finite','v == v && v >=','true || v == v && v >=','transformVm'),
('optional','s == "" || finite(s)','true','transformVm'),
('blank-id','trim(id) == ""','false','transformVm'),
('wd-validation','(wd != "0" && wd != "1")','false','transformVm'),
('x-validation','!finite(x)','false','transformVm'),
('y-validation','!finite(y)','false','transformVm'),
('z-validation','!finite(z)','false','transformVm'),
('ties','then 1 else 0\npure func choose','then 1 else -1\npure func choose','selectionVm'),
('field-count','_ => Err("expected seven fields")','_ => Ok(a)','transformVm'),
('blank-row','then Err("blank CSV row")','then Ok(a)','transformVm'),
('header','header != "id,x,y,z,G,BPRP,wd"','false','transformVm'),
('trailing-line','withoutTrailingBlank(lines))','lines)','transformVm'),
('error-propagation','Err(e) => Err(e),\n  Ok(a)','Err(e) => Ok({rows: [],input: 1,wd: 0,missing: 0}),\n  Ok(a)','transformVm'),
('number','Some(v) => v, None => 0.0','Some(v) => 0.0, None => 0.0','transformVm'),
('temperature','else if white then bbTeffFromBpRp(colour) else teffFromBpRp(colour)','else teffFromBpRp(colour)','transformVm'),
('magnitude','else if white then bbVFromG(number(g),colour) else vFromG(number(g),colour)','else vFromG(number(g),colour)','transformVm'),
('missing-temperature','teff: if missing then 0.0','teff: if missing then 1.0','transformVm'),
('missing-magnitude','v: if missing then 99.0','v: if missing then 0.0','transformVm'),
('wd-bit','flags: (if white then 1 else 0)','flags: 0','transformVm'),
('approx-bit','(if white then 4 else 0)','0','transformVm'),
('clamp-bit','then 0 else 16','then 0 else 0','transformVm'),
('input-counter','input: a.input+1','input: a.input','selectionVm'),
('wd-counter','wd: a.wd+(if wd == "1" then 1 else 0)','wd: a.wd','selectionVm'),
('missing-counter','missing: a.missing+(if g == "" || c == "" then 1 else 0)','missing: a.missing','selectionVm'),
('source-order','rows: reverseRows(a.rows),input','rows: a.rows,input','selectionVm'),
('distance-y','r.x*r.x+r.y*r.y+r.z*r.z','r.x*r.x+r.z*r.z','selectionVm'),
('distance-z','r.x*r.x+r.y*r.y+r.z*r.z','r.x*r.x+r.y*r.y','selectionVm'),
('sort','sortBy(nearer,rows)','rows','selectionVm'),
('quota','a.count >= limit','a.count > limit','selectionVm'),
('skip','r.flags == 2 || r.flags == 3','false','selectionVm'),
('excluded','excluded: a.excluded+1','excluded: a.excluded','selectionVm'),
('medium-order','{rows: reverseRows(a.rows),excluded','{rows: a.rows,excluded','selectionVm'),
('tier-limit','selectMedium(rows,50000)','selectMedium(rows,1)','selectionVm')]
results=[]
try:
 for name,old,new,entry in mutants:
  assert src.count(old)==1,(name,src.count(old)); mutated=src.replace(old,new);p.write_text(mutated);mh=hashlib.sha256(p.read_bytes()).hexdigest();assert p.read_text()==mutated
  build=subprocess.run([A,'check','--package','sim'],cwd=root,capture_output=True,text=True,timeout=30)
  run=subprocess.run([A,'run','--quiet','--bytecode','--strict-bytecode','--package-dir','sim','--entry',entry,'--args-json','0','sim/tools/catalogue_test.ail'],cwd=root,capture_output=True,text=True,timeout=30)
  want='transform-ok' if entry=='transformVm' else 'selection-ok';killed=build.returncode==0 and run.returncode==0 and run.stdout.strip()!=want
  results.append(dict(name=name,entry=entry,landed_sha256=mh,build_rc=build.returncode,run_rc=run.returncode,output=run.stdout.strip(),killed=killed,stderr=run.stderr[-500:]));print(name,killed,flush=True)
  p.write_bytes(orig);assert p.read_bytes()==orig
finally:
 p.write_bytes(orig)
 (root/'.ailang/state/evidence/iter7/mutations.json').write_text(json.dumps(dict(original_sha256=hashlib.sha256(orig).hexdigest(),restored_sha256=hashlib.sha256(p.read_bytes()).hexdigest(),results=results),indent=2)+'\n')
assert all(r['killed'] for r in results),[r['name'] for r in results if not r['killed']]
