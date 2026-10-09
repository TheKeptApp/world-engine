// Test-only removal of the bounded opt-in plumbing; legacy bytes must remain exact.
export function stripPaletteB(source){return source.replace(/ \/\/ PALETTE_B_BEGIN\n[\s\S]*? \/\/ PALETTE_B_END\n/g,'').replace('paletteB?paletteB.lawnNode(palette,e.y,p.y,colour,flag(4)):','').replace('paletteB:paletteB?.report??null,','');}
