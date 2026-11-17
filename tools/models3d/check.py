import trimesh, glob, os
rows=[]
for p in sorted(glob.glob("out/*.glb")):
    s=trimesh.load(p); m=s.to_mesh() if hasattr(s,'to_mesh') else s
    b=m.bounds
    rows.append((os.path.basename(p), len(m.faces), b[0], b[1]))
print(f"{'model':34s}{'tris':>6s}  {'minY':>6s} {'cX':>6s} {'cZ':>6s}  size(W,H,D)")
bad=0
for n,f,lo,hi in rows:
    cx=(lo[0]+hi[0])/2; cz=(lo[2]+hi[2])/2
    sz=hi-lo
    flag=""
    if abs(lo[1])>0.02: flag+=" Y!"
    if abs(cx)>0.25: flag+=" X!"
    if f>15000: flag+=" POLY!"
    if flag: bad+=1
    print(f"{n:34s}{f:6d}  {lo[1]:6.2f} {cx:6.2f} {cz:6.2f}  {sz[0]:5.1f},{sz[1]:5.1f},{sz[2]:5.1f}{flag}")
print("issues:",bad)
