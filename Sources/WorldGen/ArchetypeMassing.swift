import Foundation
import simd
import WorldGeo
import WorldMap
import WorldMesh

/// One volume of a split-level house generated from part of the mapped footprint.
struct SplitPart {
    var choice: HouseChoice
    var floors: Int
    /// The entry (door, landing, porch) sits on this part.
    var entry: Bool
    /// A ground-floor garage door on this part's front.
    var garage: Bool
}

extension BuildingGenerator {
    /// Split-level massing (house-archetypes-v1 `buildingPartsProposal`, e.g. denver-05-split): the mapped footprint
    /// is cut across its frontage into a two-storey main block (with the lower garage) and a one-storey wing (with the
    /// entry), each with its own roof; together they cover exactly the mapped footprint (never resized). Only simple
    /// rectangular footprints without a height tag and with no or matching levels are split; nil otherwise.
    func splitLevel(_ b: Building, shape: FootprintAnalysis, archetype a: HouseArchetype, choice: HouseChoice,
                    palette: inout Palette, lod: BuildingLOD) -> GeneratedBuilding? {
        let t = Self.archetypeTuning
        let ring = b.footprint.outer
        guard a.parts.count >= 2, b.footprint.holes.isEmpty, shape.roofRects.count == 1, shape.rectangularity >= t.splitMinRectangularity,
              b.height.source != .heightTag, (b.levels.map { Int($0.rounded()) } ?? a.parts[0].fullFloors) == a.parts[0].fullFloors,
              b.roofShape == nil || b.roofShape == "gabled",
              let front = context.frontEdge(of: ring) else { return nil }
        let (_, dir, _, _) = Self.edge(ring, front)
        let along = ring.map { simd_dot($0, dir) }
        let lo = along.min()!, hi = along.max()!
        guard hi - lo >= 9 else { return nil }
        var r = b.ref.random("split-side")
        let mainFirst = r.chance(0.5)
        let cut = mainFirst ? lo + (hi - lo) * t.splitMainShare : hi - (hi - lo) * t.splitMainShare
        let origin = dir * cut
        guard let mainRing = RingMath.clean(clipHalfPlane(ring, origin: origin, normal: mainFirst ? -dir : dir)),
              let wingRing = RingMath.clean(clipHalfPlane(ring, origin: origin, normal: mainFirst ? dir : -dir)),
              abs(RingMath.signedArea(mainRing)) >= 20, abs(RingMath.signedArea(wingRing)) >= 20 else { return nil }
        var mainB = b, wingB = b
        mainB.footprint = Polygon2D(outer: mainRing)
        wingB.footprint = Polygon2D(outer: wingRing)
        let gm = generate(mainB, palette: &palette, lod: lod,
                          part: SplitPart(choice: choice, floors: a.parts[0].fullFloors, entry: false, garage: true))
        let gw = generate(wingB, palette: &palette, lod: lod,
                          part: SplitPart(choice: choice, floors: a.parts[1].fullFloors, entry: true, garage: false))
        var g = gm
        g.footprintClass = shape.kind
        g.mesh.append(gw.mesh)
        g.frontEdge = front
        g.entry = gw.entry
        g.hasPorch = gw.hasPorch
        g.porchStyle = gw.porchStyle
        g.porchOutline = gw.porchOutline
        g.entryKit = gw.entryKit
        g.bushSpots += gw.bushSpots
        g.topHeight = max(gm.topHeight, gw.topHeight)
        g.roofMasses += gw.roofMasses
        g.dormers += gw.dormers
        g.hasChimney = gm.hasChimney || gw.hasChimney
        g.optionalRoofTriangles += gw.optionalRoofTriangles
        g.inferredBays += gw.inferredBays
        g.floorsFromOSM = b.levels != nil
        g.splitLevel = true
        return g
    }

    /// Far tier (house-archetypes-v1: 6–20 px keeps porch, bay and entry voids): the porch as a dark void under a
    /// slab roof, or a dark entry recess, from the same seeded porch decision the near and mid openings make.
    func addFarEntryVoid(_ c: BuildContext, _ g: GeneratedBuilding, contrast: LookSpec.HouseContrast.HouseType?,
                         palette: inout Palette, into m: inout MeshBuffers) {
        guard c.entry, let e = g.frontEdge, let type = c.type else { return }
        let (p, dir, n, len) = Self.edge(c.ring, e)
        let facade = c.grammar.facade ?? HouseFamilyGrammar.Facade()
        var r = c.b.ref.random("door")
        var doorAt = r.pick(type.door) { _ in 1 }
        if facade.symmetric == true { doorAt = 0.5 }
        let doorS = min(len - 0.7, max(0.7, len * doorAt))
        let style = facade.porchStyle ?? type.porch.style
        let wants = r.chance(facade.porchLikelihood ?? type.porch.likelihood) && len >= 3.5 && facade.storefront != true
        let shade = contrast.map { Paint(slot: palette.slot(hex: $0.porchShadow)) }
            ?? Paint(slot: c.wall.slot, shade: Float(Self.archetypeTuning.farPorchShade))
        if wants, style == "covered" {
            let fr = c.grammar.details?.porch?.frontage ?? type.porch.frontage
            let width = min(len - 0.4, max(2.4, len * (fr[0] + fr[fr.count - 1]) / 2))
            let s0 = max(0.2, min(len - 0.2 - width, doorS - width / 2))
            let depth = c.grammar.details?.porch?.depth?.first ?? type.porch.depth[0]
            let roofZ = c.F + 2.45
            m.paint = shade
            m.addWallQuad(origin: p, dir: dir, normal: n, s0: s0, s1: s0 + width, z0: c.F, z1: roofZ, offset: 0.06)
            Roofs.slab(OrientedRect(center: p + dir * (s0 + width / 2) + n * (depth / 2), u: dir, halfLength: width / 2, halfWidth: depth / 2),
                       z: roofZ, thickness: 0.15, overhang: 0, paint: c.roof, into: &m)
        } else {
            m.paint = shade
            m.addWallQuad(origin: p, dir: dir, normal: n, s0: doorS - 0.6, s1: doorS + 0.6, z0: c.F, z1: c.F + 2.2, offset: 0.06)
        }
    }
}
