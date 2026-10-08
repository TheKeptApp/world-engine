// Exact SplitMix64/FNV1a arithmetic from Sources/WorldGeo/StableRandom.swift.
const u64=x=>BigInt.asUintN(64,x);
const mix=x=>{let z=u64(x);z=u64((z^(z>>30n))*0xBF58476D1CE4E5B9n);z=u64((z^(z>>27n))*0x94D049BB133111EBn);return z^(z>>31n);};
export function stableRandom(salt,part=0){let h=0xCBF29CE484222325n;for(const b of new TextEncoder().encode(salt))h=u64((h^BigInt(b))*0x100000001B3n);let state=mix(h^BigInt(part));return ()=>{state=u64(state+0x9E3779B97F4A7C15n);return Number(mix(state)>>11n)/9007199254740992;};}
