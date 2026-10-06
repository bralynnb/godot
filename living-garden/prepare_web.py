"""Run after Godot's Web export: compress the WASM for static hosting."""
from pathlib import Path
import gzip
p=Path(__file__).parent/'web'
w=p/'index.wasm'
if w.exists():
 (p/'index.wasm.gz').write_bytes(gzip.compress(w.read_bytes(),compresslevel=9,mtime=0))
 w.unlink()
f=p/'index.html'
s=f.read_text()
loader='''<script>
// Serve a small compressed engine asset, then stream-decompress locally.
const originalFetch = window.fetch.bind(window);
window.fetch = async (resource, options) => {
 const url = typeof resource === 'string' ? resource : resource.url;
 if (url && /index\\.wasm(?:\\?|$)/.test(url)) {
  const response = await originalFetch(url.replace('index.wasm','index.wasm.gz'),options);
  if (!response.ok) throw new Error('Engine download failed: '+response.status);
  return new Response(response.body.pipeThrough(new DecompressionStream('gzip')), {
   headers: {'Content-Type':'application/wasm'}
  });
 }
 return originalFetch(resource,options);
};
</script>'''
if 'const originalFetch' not in s: s=s.replace('<script src="index.js"></script>',loader+'\n<script src="index.js"></script>')
s=s.replace('</head>','<style>html,body{width:100%;height:100%;margin:0;overflow:hidden}#canvas{width:100vw;height:100dvh;display:block}</style></head>')
f.write_text(s)
