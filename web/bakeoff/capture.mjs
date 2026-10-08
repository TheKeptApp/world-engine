// Keep bounded shader-diagnosis retries in one lock session. Each attempt is a fresh browser.
import {spawn} from 'node:child_process';
import {fileURLToPath} from 'node:url';
const entry=fileURLToPath(new URL('./capture-once.mjs',import.meta.url));
for(let attempt=1;attempt<=4;attempt++){
 const code=await new Promise((resolve,reject)=>{const child=spawn(process.execPath,[entry],{stdio:'inherit',env:process.env});child.on('error',reject);child.on('exit',code=>resolve(code??1));});
 if(code===0)process.exit(0);
 if(attempt===4)process.exit(code);
 console.error(`Capture attempt ${attempt} failed; retrying fresh in 15 seconds (maximum four attempts).`);
 await new Promise(resolve=>setTimeout(resolve,15000));
}
