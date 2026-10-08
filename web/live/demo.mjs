import {getSkyState} from './sky-state.mjs';
const slider=document.getElementById('minute');
const weatherSelect=document.getElementById('weather');
function render() {
  const minute=Number(slider.value);
  // Public map reference, fixture day in MDT (UTC-06), not a personal location.
  const result=getSkyState({lat:39.7494,lon:-105.0445,
    time:Date.parse('2026-06-21T00:00:00-06:00')+minute*60000,
    region:'front-range',weatherState:weatherSelect.value});
  document.getElementById('clock').textContent=String(Math.floor(minute/60)).padStart(2,'0')+':'+String(minute%60).padStart(2,'0')+' MDT';
  document.getElementById('summary').textContent=`${result.label.toUpperCase()} · ${result.phase} · Sun ${result.sun.elevationDeg.toFixed(2)}° elevation, ${result.sun.azimuthDeg.toFixed(2)}° azimuth`;
  document.getElementById('swatch').style.backgroundColor=result.airlight.hex;
  document.getElementById('state').textContent=JSON.stringify(result,null,2);
}
slider.addEventListener('input',render);
weatherSelect.addEventListener('change',render);
render();
