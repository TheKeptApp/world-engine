#!/usr/bin/env python3
"""Explicit build-only native crown adapter; shipping World.swift is never modified."""
from pathlib import Path
import argparse
ROOT=Path(__file__).resolve().parents[1]
def generate(source):
    def replace(old,new):
        nonlocal source
        if source.count(old)!=1: raise ValueError('native adapter anchor changed: '+old[:70])
        source=source.replace(old,new)
    replace('public final class World {','public final class World {\n    public var crownBudget = CrownBudgetRuntime()')
    replace('        if let last = lodCenter, simd_distance(last, camera)', '        if !crownBudget.adapter.enabled, let last = lodCenter, simd_distance(last, camera)')
    replace('        for g in lodGroups {\n            let slots = g.batches.count', '        var crownCandidates: [CrownRuntimeAdapter.Candidate] = []\n        var crownRequests: [CrownMeshRequest] = []\n        var crownLocations: [(group: Int, instance: Int)] = []\n        for (groupIndex, g) in lodGroups.enumerated() {\n            let slots = g.batches.count')
    needle='                buckets[g.batches[slot]].append(slot >= 3 ? inst.transform * g.fits[slot] : inst.transform)'
    extra='''
                if crownBudget.adapter.enabled, inst.species == "ulmus_americana", stats.season != 3 {
                    let levels: [CrownLODAllocator.Level: Int] = [.near: (cutAwayActive && d < cut ? 0 : 1), .middle: 2, .far: 3, .skyline: 4]
                    var native: [CrownLODAllocator.Level: Int] = [:], batchSlots: [CrownLODAllocator.Level: Int] = [:]
                    for (level, target) in levels where target < slots {
                        let batch = g.batches[target]
                        native[level] = lodBatches[batch].triangles; batchSlots[level] = batch
                    }
                    let height = (crownBudget.referenceCrownHeight?(inst.source) ?? .nan) * inst.scale
                    let centre = SIMD3(g.spheres[k].x, g.spheres[k].y, g.spheres[k].z)
                    let depth = Double(simd_dot(centre - camera, forward))
                    let pixels = depth > 0 ? height * crownBudget.drawableHeight / (2 * depth * Double(tan(vHalf))) : 0
                    crownCandidates.append(.init(sourceID: inst.source, species: inst.species, bare: false,
                        distance: Double(d), projectedPixels: pixels, skylineEligible: d >= edges.last!, legacySlot: slot, costs: [:]))
                    crownRequests.append(.init(sourceID: inst.source, nativeTriangles: native, batchSlots: batchSlots))
                    crownLocations.append((groupIndex, k))
                }
'''
    replace(needle,needle+extra)
    replace('        for b in lodBatches.indices {\n            let batch = lodBatches[b], ts = buckets[b]', '''        if crownBudget.adapter.enabled {
            do {
                if let selected = try crownBudget.allocate(crownCandidates, requests: crownRequests) {
                    // Rebuild exactly the existing eligibility set; only explicit elms change slots.
                    var replacements: [Int: [Int: Int]] = [:]
                    for (index, candidate) in crownCandidates.enumerated() {
                        if let slot = selected[candidate.sourceID] { replacements[crownLocations[index].group, default: [:]][crownLocations[index].instance] = slot }
                    }
                    var candidateBuckets = [[simd_float4x4]](repeating: [], count: lodBatches.count)
                    for (groupIndex, g) in lodGroups.enumerated() {
                        for (k, inst) in g.instances.enumerated() {
                            let d = simd_distance(SIMD3(Float(inst.x), Float(inst.height), Float(-inst.y)), camera)
                            if foliageViewCulling, d >= cut, !visible(g.spheres[k]) { continue }
                            var slot = cutAwayActive && d < cut ? 0 : 1
                            if slot == 1 { for e in edges where d >= e { slot += 1 } }
                            slot = replacements[groupIndex]?[k] ?? min(slot, g.batches.count - 1)
                            guard slot < g.batches.count else { throw CrownLODAllocator.Failure.invalidInput }
                            candidateBuckets[g.batches[slot]].append(slot >= 3 ? inst.transform * g.fits[slot] : inst.transform)
                        }
                    }
                    buckets = candidateBuckets
                }
            } catch {
                // Preserve all legacy instances, but explicitly reject this experimental candidate.
                print("CROWN_ADAPTER_FAILED error=\\(error)")
            }
        }
        for b in lodBatches.indices {
            let batch = lodBatches[b], ts = buckets[b]''')
    return source
if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('output',type=Path);a=p.parse_args()
    a.output.write_text(generate((ROOT/'Sources/WorldEngine/World.swift').read_text()))
