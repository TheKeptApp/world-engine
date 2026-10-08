// Produces a standalone file:// demo: inline ES modules, zero network requests.
import {readFileSync,writeFileSync} from 'node:fs';
const here = name => new URL(name, import.meta.url);
const read = name => readFileSync(here(name),'utf8');
const flatten = name => read(name).replace(/^import .*;\n/gm,'').replace(/\bexport /g,'');
const script = read('pack-data.mjs').replace('export default','const pack =')+'\n'+
  ['astronomy.mjs','visibility.mjs','sky-state.mjs','demo.mjs'].map(flatten).join('\n');
if (script.includes('</script')) throw new Error('Unsafe inline script terminator');
const template=read('demo-template.html');
writeFileSync(here('index.html'),template.replace('<!-- INLINE_MODULE -->','<script type="module">\n'+script+'\n</script>'));
