"""Run after Godot Web export. Compress WASM below static asset size limit."""
from pathlib import Path
import gzip,re
root=Path(__file__).parent/'dist'
p=root/'index.wasm'
if p.exists():
 (root/'index.wasm.gz').write_bytes(gzip.compress(p.read_bytes(),compresslevel=9,mtime=0))
 p.unlink()
p=root/'index.html'
s=p.read_text()
loader='''<script>
const nativeFetch = window.fetch.bind(window);
window.fetch = async function(input, options) {
 const url = new URL(typeof input === 'string' ? input : input.url, location.href);
 if (url.origin === location.origin && url.pathname.endsWith('/index.wasm')) {
  if (!('DecompressionStream' in window)) throw new Error('Please open this room in a current Chrome, Edge, Firefox or Safari browser.');
  const compressed = await nativeFetch(new URL('index.wasm.gz', url), options);
  if (!compressed.ok) throw new Error('The room engine could not load. Please reload.');
  return new Response(compressed.body.pipeThrough(new DecompressionStream('gzip')), {headers: {'Content-Type':'application/wasm'}});
 }
 return nativeFetch(input, options);
};
</script>'''
s=s.replace('<script src="index.js"></script>',loader+'\n<script src="index.js"></script>')
s=s.replace('show-image--true','show-image--false')
s=s.replace('background-color: black','background-color: #211c19').replace('background-color: #242424','background-color: #211c19')
s=s.replace('<progress id="status-progress">','<div style="font:20px Georgia;letter-spacing:.3em;color:#dfba85;margin-bottom:24px">F I R E S I D E</div><progress id="status-progress">')
s=re.sub(r'<link id="-gd-engine-icon"[^>]+>', '<link rel="icon" href="favicon.svg" type="image/svg+xml">', s)
p.write_text(s)
(root/'favicon.svg').write_text('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 40 40"><rect width="40" height="40" rx="8" fill="#34261e"/><path d="M11 32V13h18v19M8 12h24" fill="none" stroke="#ba6937" stroke-width="5"/><path d="M20 30c-10-3-2-10-2-14 6 5 10 10 2 14" fill="#ffc65d"/></svg>')
print('Prepared compressed Godot Web build:',(root/'index.wasm.gz').stat().st_size,'bytes')
