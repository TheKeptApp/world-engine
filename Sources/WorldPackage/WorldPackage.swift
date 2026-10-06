import CryptoKit
import Foundation
import ImageIO
import UniformTypeIdentifiers
import simd
import WorldGen
import WorldGeo
import WorldMap
import WorldMesh

/// Writes the platform-neutral world package (engine-choice review §4): a versioned manifest,
/// per-chunk LOD meshes (.glb with explicit custom channels), per-chunk scene recipes, prototype
/// meshes plus instance tables, palettes, material semantics, environment and source profiles.
///
/// The Swift generator stays the one decision owner: renderers load these files as they are and
/// never re-derive roofs, colors or placements. Layout:
///
///     world.json                    manifest: versions, source, frame, chunk index, file hashes
///     chunks/<id>/lod0.glb, lod1.glb  static + water meshes (lod1: simple buildings, no curbs)
///     chunks/<id>/scene.json        feature identities, source vs generated choices, vertex ranges
///     prototypes/<kind>-<variant>-lod<n>.glb
///     instances.json                placed props (position, yaw, scale, cell)
///     clutter-tufts.bin             edge-tuft candidates (float32 x, z, yaw, scale)
///     boundary.glb                  soft world boundary ground
///     collision.json                building hulls for camera collision
///     palettes.json, materials.json, environment.json, sky-<state>.png, profiles/*.json
///     LICENSE-DATA.md               licence notice: ODbL data files, every source, how to get the data
public enum WorldPackage {
    public static let schema = "worldengine.package/1"

    public struct Options: Sendable {
        public var recipe: WorldRecipe
        /// Named light states to include (fixture name → moment). The first is the default.
        public var lightStates: [(name: String, date: Date)]
        /// Generator version string recorded in world.json (e.g. the git commit).
        public var generatorVersion: String

        public init(recipe: WorldRecipe, lightStates: [(name: String, date: Date)], generatorVersion: String = "dev") {
            self.recipe = recipe
            self.lightStates = lightStates
            self.generatorVersion = generatorVersion
        }
    }

    public struct Summary: Sendable {
        public var files = 0
        public var bytes = 0
        public var chunks = 0
        public var instances = 0
        public var triangles = [0, 0]
        public var tufts = 0
    }

    /// Generates the world and writes the package into `out` (replacing what was there).
    @discardableResult
    public static func export(areaDirectory: URL, to out: URL, options: Options) throws -> Summary {
        let build = try WorldBuild.generate(areaDirectory: areaDirectory, recipe: options.recipe)
        let reduced = try build.reducedDetail()
        let palette = reduced.palette
        // LOD1 continues LOD0's palette, so every LOD0 slot keeps its number.
        precondition(Array(palette.colors.prefix(build.scene.palette.colors.count)) == build.scene.palette.colors)

        var files: [String: Data] = [:]
        var summary = Summary()
        let frame = build.manifest.frame

        // Feature identities and the generator's choices.
        var kinds: [String: String] = [:]
        var sourceTags: [String: [String: String]] = [:]
        let keptTags = ["building", "building:levels", "roof:shape", "roof:levels", "height", "min_height", "building:colour",
                        "roof:colour", "building:material", "highway", "surface", "width", "lanes", "leisure", "landuse", "natural"]
        func keep(_ tags: Tags) -> [String: String] { tags.filter { keptTags.contains($0.key) } }
        for b in build.features.buildings { kinds[b.ref.description] = "building"; sourceTags[b.ref.description] = keep(b.tags) }
        for r in build.features.roads { kinds[r.ref.description] = "road"; sourceTags[r.ref.description] = keep(r.tags) }
        for p in build.features.paths { kinds[p.ref.description] = p.isCrossing ? "crossing" : "path"; sourceTags[p.ref.description] = keep(p.tags) }
        for s in build.features.sidewalks { kinds[s.ref.description] = "sidewalk"; sourceTags[s.ref.description] = keep(s.tags) }
        for a in build.features.areas { kinds[a.ref.description] = a.kind.rawValue; sourceTags[a.ref.description] = keep(a.tags) }
        var decisions: [String: [String: Any]] = [:]
        for g in build.scene.buildings {
            var d: [String: Any] = [
                "role": g.role.rawValue, "footprintClass": g.footprintClass.rawValue, "roofShape": g.roofShape.rawValue,
                "roofShapeFrom": sourceTags[g.ref.description]?["roof:shape"] != nil ? "osm" : "profile",
                "floors": g.floors, "floorsFrom": g.floorsFromOSM ? "osm" : "profile",
                "colorSet": g.colorSet, "colors": g.colors, "hasPorch": g.hasPorch,
                "eaveHeight": round(g.eaveHeight, 3), "topHeight": round(g.topHeight, 3),
            ]
            if let t = g.houseType { d["houseType"] = t }
            if let f = g.family { d["family"] = f }
            if let p = g.profileID { d["profile"] = p }
            if let p = g.porchStyle { d["porchStyle"] = p }
            if let k = g.entryKit { d["entryKit"] = k }
            if g.roofMasses > 0 { d["roofMasses"] = g.roofMasses }
            if g.crossGable { d["crossGable"] = true }
            if g.dormers > 0 { d["dormers"] = g.dormers }
            if let f = g.roofFallback { d["roofFallback"] = f }
            // Inferred facade elements (not in the mapped footprint), flagged for review.
            if !g.inferredBays.isEmpty { d["inferredFacade"] = g.inferredBays.map { _ in "bay" } }
            if let e = g.frontEdge { d["frontEdge"] = e }
            if let e = g.garageDoorEdge { d["garageDoorEdge"] = e; d["garageDoorFacesAlley"] = g.garageDoorFacesAlley }
            decisions[g.ref.description] = d
        }
        func kind(_ feature: String) -> String {
            if let k = kinds[feature] { return k }
            let parts = feature.split(separator: ":")
            return parts.first == "gen" && parts.count > 1 ? "generated-\(parts[1])" : "unknown"
        }

        // Chunks.
        var chunkIndex: [[String: Any]] = []
        for (c0, c1) in zip(build.scene.chunks, reduced.chunks) {
            precondition(c0.id == c1.id)
            let center = (c0.rect.min + c0.rect.max) / 2
            let origin = SIMD3<Float>(Float(center.x), 0, Float(-center.y))
            var featureIDs: [String] = []
            var index: [String: Int] = [:]
            for f in c0.staticFeatures + c0.waterFeatures + c1.staticFeatures + c1.waterFeatures where index[f.feature] == nil {
                index[f.feature] = featureIDs.count
                featureIDs.append(f.feature)
            }
            let base = "chunks/\(c0.id)"
            files["\(base)/lod0.glb"] = try chunkGLB(c0, origin: origin, featureIndex: index, name: "chunk \(c0.id) lod0")
            files["\(base)/lod1.glb"] = try chunkGLB(c1, origin: origin, featureIndex: index, name: "chunk \(c0.id) lod1")
            func ranges(_ list: [FeatureRange], _ id: String) -> [[Int]] { list.filter { $0.feature == id }.map { [$0.start, $0.count] } }
            let features: [[String: Any]] = featureIDs.enumerated().map { i, id in
                var f: [String: Any] = ["index": i, "id": id, "kind": kind(id),
                                        "lod0": ["static": ranges(c0.staticFeatures, id), "water": ranges(c0.waterFeatures, id)],
                                        "lod1": ["static": ranges(c1.staticFeatures, id), "water": ranges(c1.waterFeatures, id)]]
                if let t = sourceTags[id], !t.isEmpty { f["source"] = t }
                if let d = decisions[id] { f["generated"] = d }
                return f
            }
            let tris = [c0.staticMesh.triangleCount + c0.waterMesh.triangleCount, c1.staticMesh.triangleCount + c1.waterMesh.triangleCount]
            files["\(base)/scene.json"] = try json([
                "schema": 1, "chunk": c0.id, "index": [c0.index.x, c0.index.y], "detail": c0.detail.rawValue,
                "rect": [c0.rect.min.x, c0.rect.min.y, c0.rect.max.x, c0.rect.max.y].map { round($0, 3) },
                "origin": [Double(origin.x), 0, Double(origin.z)], "features": features,
                "vertices": [c0.staticMesh.vertexCount + c0.waterMesh.vertexCount, c1.staticMesh.vertexCount + c1.waterMesh.vertexCount],
                "triangles": tris,
            ] as [String: Any], pretty: false)
            var bounds: [[Double]] = []
            if let b = union(c0.staticMesh.bounds, c0.waterMesh.bounds) { bounds = [b.min, b.max].map { [Double($0.x), Double($0.y), Double($0.z)] } }
            chunkIndex.append(["id": c0.id, "index": [c0.index.x, c0.index.y], "detail": c0.detail.rawValue,
                               "origin": [Double(origin.x), 0, Double(origin.z)], "bounds": bounds,
                               "lods": ["\(base)/lod0.glb", "\(base)/lod1.glb"], "scene": "\(base)/scene.json", "triangles": tris])
            summary.triangles[0] += tris[0]
            summary.triangles[1] += tris[1]
        }
        summary.chunks = chunkIndex.count

        // Boundary ground.
        do {
            let b = GLBBuilder()
            let mat = b.material(name: "worldStatic", roughness: 0.95)
            let prim = primitive(b, build.scene.boundaryGround, origin: .zero, features: nil, material: mat)
            _ = b.node(name: "boundary", mesh: b.mesh(name: "boundary", primitives: [prim]))
            files["boundary.glb"] = try b.encoded()
        }

        // Prototypes (same palette slots as the chunks).
        var prototypes: [[String: Any]] = []
        for kind in PropKind.allCases {
            for v in 0..<(PropLibrary.variants[kind] ?? 1) {
                var lods: [String] = [], tris: [Int] = []
                for lod in 0..<PropLibrary.lodCount(kind) {
                    let mesh = PropLibrary.mesh(kind, variant: v, lod: lod, palette: palette)
                    let b = GLBBuilder()
                    let mat = b.material(name: kind.isFoliage ? "worldFoliage" : "worldProp", roughness: kind.isFoliage ? 0.95 : 0.75)
                    let name = "\(kind.rawValue)-\(v)-lod\(lod)"
                    _ = b.node(name: name, mesh: b.mesh(name: name, primitives: [primitive(b, mesh, origin: .zero, features: nil, material: mat)]))
                    files["prototypes/\(name).glb"] = try b.encoded()
                    lods.append("prototypes/\(name).glb")
                    tris.append(mesh.triangleCount)
                }
                prototypes.append(["kind": kind.rawValue, "variant": v, "lods": lods, "triangles": tris,
                                   "material": kind.isFoliage ? "worldFoliage" : "worldProp", "isTree": kind.isTree])
            }
        }

        // Instances.
        let instances: [[String: Any]] = build.scene.instances.map { i in
            let c = PropLibrary.cell(x: i.x, y: i.y)
            return ["id": i.source, "kind": i.kind.rawValue, "variant": i.variant,
                    "position": [round(i.x, 4), round(i.height, 4), round(-i.y, 4)],
                    "yaw": round(i.yaw, 6), "scale": round(i.scale, 6), "cell": [c.x, c.y]]
        }
        summary.instances = instances.count
        files["instances.json"] = try json([
            "schema": 1, "count": instances.count,
            "transform": "matrix = translate(position) × rotateY(yaw, right-handed about +Y) × uniform scale",
            "instances": instances,
        ] as [String: Any], pretty: false)

        // Edge-tuft candidates (renderers keep the nearest 200 within 25 m, see world.json runtime).
        let tufts = build.scene.clutter.allTuftPlacements()
        var tuftFloats: [Float] = []
        tuftFloats.reserveCapacity(tufts.count * 4)
        for t in tufts { tuftFloats += [Float(t.x), Float(-t.y), Float(t.z), Float(t.w)] }
        files["clutter-tufts.bin"] = tuftFloats.withUnsafeBufferPointer { Data(buffer: $0) }
        summary.tufts = tufts.count

        // Camera collision proxies: building hulls (scene x, z) and heights.
        files["collision.json"] = try json([
            "schema": 1, "kind": "convex building hulls; scene x, z pairs counter-clockwise seen from above; walls from y = 0 to height",
            "hulls": build.scene.occluders.map { o -> [String: Any] in
                ["points": o.hull.map { [round($0.x, 3), round(-$0.y, 3)] }, "height": round(o.height, 3)]
            },
        ] as [String: Any], pretty: false)

        // Palettes.
        let seasonal = try StyleLibrary.seasonalPalette()
        var namesBySlot: [Int: [String]] = [:]
        for (name, slot) in palette.namedSlots { namesBySlot[slot, default: []].append(name) }
        let slots: [[String: Any]] = palette.colors.enumerated().map { i, c in
            var s: [String: Any] = ["slot": i, "srgb": Palette.hex(c)]
            if let n = namesBySlot[i] { s["names"] = n.sorted() }
            return s
        }
        var seasonalSlots: [String: Any] = [:]
        for (i, key) in SeasonalPalette.order.enumerated() { seasonalSlots[key] = ["slot": i, "srgb": seasonal.surfaces[key] ?? []] }
        files["palettes.json"] = try json([
            "schema": 1, "colorSpace": "sRGB hex; convert to linear light before lighting",
            "season": build.season, "seasons": seasonal.seasons,
            "slots": slots, "seasonalSlotCount": SeasonalPalette.order.count, "seasonalSlots": seasonalSlots,
        ] as [String: Any])

        // Materials (shared meaning; each renderer implements it).
        files["materials.json"] = try json(MaterialSpec.document)

        // Environment: light states for the requested moments, sky images, weather, time tables.
        let tables = try StyleLibrary.lighting()
        var states: [String: Any] = [:]
        for (name, date) in options.lightStates {
            let light = LightingModel.state(at: date, location: build.manifest.center, tables: tables)
            let season = options.recipe.season ?? build.profile.seasons.season(at: date, longitude: build.manifest.center.longitude)
            files["sky-\(name).png"] = try png(SkyImage.render(light, width: 1024, height: 512, convention: .threeJS), width: 1024, height: 512)
            states[name] = ["date": iso(date), "season": season, "light": try jsonObject(light), "sky": "sky-\(name).png"]
        }
        files["environment.json"] = try json([
            "schema": 1,
            "location": ["latitude": build.manifest.center.latitude, "longitude": build.manifest.center.longitude, "timezone": "America/Denver"],
            "defaultState": options.lightStates.first?.name ?? "",
            "states": states,
            "skyConvention": "equirectangular RGBA8 sRGB, row 0 = zenith; direction = (cos(lat)·cos(lon), sin(lat), cos(lat)·sin(lon)), lon = 2π·u − π",
            "weather": ["state": "clear", "wetness": 0, "snow": 0, "wind": 0.35],
            "fogPolicy": ["street": "time-of-day key fogStart/fogEnd",
                          "aerial": "start = max(keyStart, \(FogPolicy.startPerHeight) × camera height), end = max(keyEnd, \(FogPolicy.endPerHeight) × camera height)"],
            "timeOfDay": try jsonObject(tables),
            "experience": try build.experience.map { try jsonObject($0) } ?? NSNull(),
        ] as [String: Any])

        // Source profiles and shared tables, verbatim (provenance).
        let profileID = build.profile.id
        var profileFiles: [String] = []
        for name in [profileID, "regions", "seasonal-palette", "base-palette", "time-of-day", "weather", "display"] {
            files["profiles/\(name).json"] = try StyleLibrary.data(name)
            profileFiles.append("profiles/\(name).json")
        }

        // Licence notice and credits (decisions 6a, 6b, 6f): the data files are an ODbL Derivative
        // Database of OpenStreetMap; every manifest source is named with its licence.
        let catalog = try CreditsCatalog.bundled()
        let credits = catalog.merged(sources: build.manifest.sources, surface: .package)
        files[dataNoticeFile] = Data(dataNotice(manifest: build.manifest, credits: credits, catalog: catalog,
                                                generatorVersion: options.generatorVersion).utf8)

        // Manifest.
        var hashes: [String: Any] = [:]
        for (path, data) in files {
            hashes[path] = ["sha256": SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined(), "bytes": data.count]
        }
        let b = build.features.bounds
        let world: [String: Any] = [
            "schema": schema,
            "generator": ["name": "WorldEngine WorldGen", "version": options.generatorVersion],
            "area": ["id": build.manifest.id, "name": build.manifest.name, "widthMeters": build.manifest.widthMeters,
                     "heightMeters": build.manifest.heightMeters],
            "sources": build.manifest.sources.map { s -> [String: Any] in
                var d: [String: Any] = ["format": s.format, "license": s.license, "attribution": s.attribution, "layers": s.layers]
                if let u = catalog.licenseURL(for: s.license) { d["licenseURL"] = u }
                if let t = s.dataTimestamp { d["dataTimestamp"] = t }
                if let h = s.sha256 { d["sha256"] = h }
                return d
            },
            "attribution": "© OpenStreetMap contributors",
            "dataLicense": [
                "license": dataLicense, "licenseURL": catalog.licenseURL(for: dataLicense).map { $0 as Any } ?? NSNull(), "notice": dataNoticeFile,
                "derivativeDatabase": derivativeDatabaseFiles.map(\.pattern),
                "separatelyLicensed": separatelyLicensedFiles.map(\.pattern),
                "offer": offerURL(catalog).map { ["status": "published", "url": $0] as [String: Any] } ?? ["status": "pending"],
            ] as [String: Any],
            "credits": try jsonObject(credits),
            "frame": [
                "type": "local tangent plane (ENU) on WGS84, exact",
                "origin": ["latitude": frame.origin.latitude, "longitude": frame.origin.longitude, "height": 0],
                "units": "meters", "axes": ["x": "east", "y": "up", "z": "south (north is −Z)"],
                "vertical": "flat terrain; y = 0 is ground (no terrain payload in this version)",
                "meshVertices": "float32, relative to each chunk node's translation (its origin)",
            ],
            "recipe": [
                "profile": profileID, "profileVersion": build.profile.version, "season": build.season,
                "date": iso(options.recipe.date),
                "focus": [round(build.focus.min.x, 3), round(build.focus.min.y, 3), round(build.focus.max.x, 3), round(build.focus.max.y, 3)],
            ] as [String: Any],
            "bounds": ["min": [b.min.x, 0, -b.max.y].map { round($0, 3) }, "max": [b.max.x, 40, -b.min.y].map { round($0, 3) }],
            "chunkSize": 200,
            "chunks": chunkIndex,
            "boundary": "boundary.glb",
            "prototypes": prototypes,
            "instances": "instances.json",
            "collision": "collision.json",
            "clutter": ["tufts": ["file": "clutter-tufts.bin", "count": tufts.count, "layout": "float32 × 4 per tuft: x, z, yaw, scale",
                                  "prototype": "tuft", "rule": "keep the nearest \(ClutterField.maxClusters) within \(Int(ClutterField.radius)) m of the camera's look target (refresh when it moves > 3 m); scale × (1 − smoothstep(20, 30, distance to camera))"]],
            "palettes": "palettes.json", "materials": "materials.json", "environment": "environment.json",
            "profiles": profileFiles,
            "runtime": [
                "lodDistances": PropLibrary.lodDistances, "lodRebucketMeters": PropLibrary.lodRebucketMeters,
                "instanceCellMeters": PropLibrary.cellMeters,
                "chunkLOD": "lod0 everywhere (renderers may use lod1 beyond 400 m; both renderers in this version use lod0)",
            ] as [String: Any],
            "capabilities": [
                "required": ["glTF 2.0 binary", "uint32 indices", "custom vertex attributes _PAINT, _EXTRA (float32 VEC4), _FEATURE (uint16/uint32)",
                             "palette lookup by slot", "materials.json semantics"],
                "fallback": "A renderer that cannot read the custom attributes must reject the package rather than draw it with the fallback materials.",
            ],
            "files": hashes,
        ]
        files["world.json"] = try json(world)

        // Write.
        let fm = FileManager.default
        if fm.fileExists(atPath: out.path) { try fm.removeItem(at: out) }
        for (path, data) in files {
            let url = out.appendingPathComponent(path)
            try fm.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try data.write(to: url)
            summary.bytes += data.count
        }
        summary.files = files.count
        return summary
    }

    // MARK: - Meshes

    static func chunkGLB(_ c: GeneratedChunk, origin: SIMD3<Float>, featureIndex: [String: Int], name: String) throws -> Data {
        let b = GLBBuilder()
        let staticMaterial = b.material(name: "worldStatic", roughness: 0.88)
        let waterMaterial = b.material(name: "worldWater", baseColor: [0.32, 0.45, 0.52, 1], roughness: 0.45)
        var prims: [[String: Any]] = []
        for (mesh, ranges, material) in [(c.staticMesh, c.staticFeatures, staticMaterial), (c.waterMesh, c.waterFeatures, waterMaterial)] where !mesh.isEmpty {
            var ids = [UInt32](repeating: UInt32(UInt16.max), count: mesh.vertexCount)
            for r in ranges {
                let i = UInt32(featureIndex[r.feature]!)
                for v in r.start..<(r.start + r.count) { ids[v] = i }
            }
            prims.append(primitive(b, mesh, origin: origin, features: ids, material: material))
        }
        _ = b.node(name: name, mesh: b.mesh(name: name, primitives: prims), translation: [Double(origin.x), 0, Double(origin.z)])
        return try b.encoded()
    }

    static func primitive(_ b: GLBBuilder, _ mesh: MeshBuffers, origin: SIMD3<Float>, features: [UInt32]?, material: Int) -> [String: Any] {
        var pos = [Float](), nrm = [Float](), paint = [Float](), extra = [Float]()
        pos.reserveCapacity(mesh.vertexCount * 3); nrm.reserveCapacity(mesh.vertexCount * 3)
        paint.reserveCapacity(mesh.vertexCount * 4); extra.reserveCapacity(mesh.vertexCount * 4)
        for p in mesh.positions { let r = p - origin; pos.append(r.x); pos.append(r.y); pos.append(r.z) }
        for n in mesh.normals { nrm.append(n.x); nrm.append(n.y); nrm.append(n.z) }
        for v in mesh.paints { paint.append(v.x); paint.append(v.y); paint.append(v.z); paint.append(v.w) }
        for v in mesh.extras { extra.append(v.x); extra.append(v.y); extra.append(v.z); extra.append(v.w) }
        var attributes = ["POSITION": b.floats(pos, components: 3, minMax: true), "NORMAL": b.floats(nrm, components: 3),
                          "_PAINT": b.floats(paint, components: 4), "_EXTRA": b.floats(extra, components: 4)]
        if let features { attributes["_FEATURE"] = b.uints(features) }
        return b.primitive(attributes: attributes, indices: b.indices(mesh.indices), material: material)
    }

    static func union(_ a: (min: SIMD3<Float>, max: SIMD3<Float>)?, _ b: (min: SIMD3<Float>, max: SIMD3<Float>)?) -> (min: SIMD3<Float>, max: SIMD3<Float>)? {
        switch (a, b) {
        case let (x?, y?): (simd_min(x.min, y.min), simd_max(x.max, y.max))
        case let (x?, nil): x
        case let (nil, y?): y
        default: nil
        }
    }

    // MARK: - Licence notice (decisions 6a, 6f; docs/data-licensing.md)

    /// The licence notice written into every package.
    public static let dataNoticeFile = "LICENSE-DATA.md"
    /// The package's data files are a Derivative Database of OpenStreetMap (decision 6a).
    public static let dataLicense = "ODbL-1.0"

    public struct FileClass: Sendable {
        public var pattern: String
        public var meaning: String
    }

    /// Files that form the Derivative Database (licensed under `dataLicense`).
    public static let derivativeDatabaseFiles: [FileClass] = [
        .init(pattern: "world.json", meaning: "manifest: sources, exact geographic frame, chunk index"),
        .init(pattern: "chunks/*/scene.json", meaning: "feature tables keyed by OSM identity, with OSM tags and the generated choices"),
        .init(pattern: "chunks/*/lod0.glb", meaning: "chunk geometry derived from the map data"),
        .init(pattern: "chunks/*/lod1.glb", meaning: "reduced chunk geometry derived from the map data"),
        .init(pattern: "instances.json", meaning: "placed props (positions derived from the map data)"),
        .init(pattern: "clutter-tufts.bin", meaning: "edge-tuft candidates (positions derived from the map data)"),
        .init(pattern: "collision.json", meaning: "building hulls"),
        .init(pattern: "environment.json", meaning: "location and experience defaults derived from the map data (its lighting tables are WorldEngine content)"),
    ]

    /// Files that are WorldEngine's own content, not covered by the ODbL.
    public static let separatelyLicensedFiles: [FileClass] = [
        .init(pattern: "palettes.json", meaning: "colour palettes"),
        .init(pattern: "materials.json", meaning: "material semantics and shader constants"),
        .init(pattern: "profiles/*.json", meaning: "regional style profiles and shared tables"),
        .init(pattern: "prototypes/*.glb", meaning: "prototype meshes (trees, bushes, props)"),
        .init(pattern: "boundary.glb", meaning: "boundary ground"),
        .init(pattern: "sky-*.png", meaning: "sky images"),
    ]

    /// Which class a package path belongs to: the ODbL data, separately licensed content, or the
    /// notice itself (nil = unclassified, which the package tests reject).
    public static func licenseClass(of path: String) -> String? {
        func match(_ p: String) -> Bool { fnmatch(p, path, FNM_PATHNAME) == 0 }
        if path == dataNoticeFile { return "notice" }
        if derivativeDatabaseFiles.contains(where: { match($0.pattern) }) { return dataLicense }
        if separatelyLicensedFiles.contains(where: { match($0.pattern) }) { return "separate" }
        return nil
    }

    static func offerURL(_ catalog: CreditsCatalog) -> String? {
        catalog.credits.first { $0.kind == .dataOffer && !$0.isPlaceholder }?.url
    }

    /// `LICENSE-DATA.md`: what is ODbL, every manifest source with its licence and attribution,
    /// how to obtain the data, what is licensed separately, and the package credits.
    static func dataNotice(manifest: AreaManifest, credits: [Credit], catalog: CreditsCatalog, generatorVersion: String) -> String {
        let odbl = catalog.licenses[dataLicense]
        let odblURL = odbl?.url ?? "https://opendatacommons.org/licenses/odbl/1-0/"
        var s = "# Data licence notice\n\n"
        s += "World package for \"\(manifest.name)\" (`\(manifest.id)`), generated by WorldEngine (generator version `\(generatorVersion)`).\n\n"

        s += "## Licence\n\n"
        s += "The data files listed below form a Derivative Database of OpenStreetMap. They are licensed under the "
        s += "\(odbl?.name ?? "Open Database License 1.0") (ODbL 1.0):\n\(odblURL)\n\n"
        s += "Map data © OpenStreetMap contributors, available under the Open Database License: https://www.openstreetmap.org/copyright\n\n"
        s += "Data files covered by the ODbL:\n\n"
        for f in derivativeDatabaseFiles { s += "- `\(f.pattern)`: \(f.meaning)\n" }

        s += "\n## Sources\n\nEvery source this package was built from, with its licence and attribution:\n\n"
        for src in manifest.sources {
            let info = catalog.licenses[src.license]
            let licence = info.map { "\(src.license) (\($0.name)" + ($0.url.map { ", \($0)" } ?? ", licence URL not on record") + ")" }
                ?? "\(src.license) (licence URL not on record)"
            s += "- **\(src.attribution)**. Licence: \(licence). Format `\(src.format)`, layers \(src.layers.joined(separator: ", "))"
            if let t = src.dataTimestamp { s += ", data timestamp \(t)" }
            if let h = src.sha256 { s += ", source SHA-256 `\(h)`" }
            s += "."
            if src.license != dataLicense { s += " Data from this source is also subject to its own licence." }
            s += "\n"
        }
        if manifest.sources.isEmpty { s += "- (the area manifest lists no sources)\n" }

        s += "\n## How to obtain the data\n\n"
        s += "- **This package.** The data files listed above are included here in machine-readable form (JSON and glTF binary). "
        s += "You may extract, use and share them under the ODbL.\n"
        if let url = offerURL(catalog) {
            s += "- **Public download.** The same data files are offered free of charge at \(url)\n"
        } else {
            s += "- **Public download.** Not yet published. A free download of the same data files will be offered before any public release.\n"
        }
        s += "- **Source data.** OpenStreetMap data is available from https://www.openstreetmap.org/ (full database: https://planet.openstreetmap.org/). "
        s += "The sources above record the data timestamp and hash of the exact extract used.\n"

        s += "\n## Separately licensed content\n\n"
        s += "These files are WorldEngine's own content. They are not part of the Derivative Database, are not licensed under the ODbL, "
        s += "and are licensed separately by the package's publisher:\n\n"
        for f in separatelyLicensedFiles { s += "- `\(f.pattern)`: \(f.meaning)\n" }
        let star = catalog.credits.first { $0.kind == .skyData }
        s += "\nStar data: this package contains no star catalog. Where an app or renderer adds one, it carries its own licence"
        s += star.map { ": \($0.text)" + ($0.license.map { " (\($0))" } ?? "") + ".\n" } ?? ".\n"

        s += "\n## Credits\n\n"
        for c in credits {
            s += "- \(c.text)"
            if let l = c.license { s += " (\(l))" }
            if let u = c.url { s += ": \(u)" }
            if c.isPlaceholder { s += " [pending]" }
            s += "\n"
        }
        return s
    }

    // MARK: - Encoding helpers

    static func json(_ object: Any, pretty: Bool = true) throws -> Data {
        var options: JSONSerialization.WritingOptions = [.sortedKeys, .withoutEscapingSlashes]
        if pretty { options.insert(.prettyPrinted) }
        return try JSONSerialization.data(withJSONObject: object, options: options)
    }

    static func jsonObject<T: Encodable>(_ value: T) throws -> Any {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return try JSONSerialization.jsonObject(with: encoder.encode(value))
    }

    static func round(_ v: Double, _ places: Int) -> Double {
        let p = pow(10.0, Double(places))
        return (v * p).rounded() / p
    }

    static func iso(_ d: Date) -> String {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f.string(from: d)
    }

    static func png(_ rgba: [UInt8], width: Int, height: Int) throws -> Data {
        let provider = CGDataProvider(data: Data(rgba) as CFData)!
        let image = CGImage(width: width, height: height, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: width * 4,
                            space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue),
                            provider: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent)!
        let out = NSMutableData()
        let dest = CGImageDestinationCreateWithData(out, UTType.png.identifier as CFString, 1, nil)!
        CGImageDestinationAddImage(dest, image, nil)
        CGImageDestinationFinalize(dest)
        return out as Data
    }
}
