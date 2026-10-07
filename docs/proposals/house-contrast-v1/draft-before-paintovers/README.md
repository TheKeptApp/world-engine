# House contrast paint-over v1

Prepared: 2026-10-07. **Partial delivery: source renders were not attached to the received message.** No paint-overs have been generated; exact camera/composition matching and phone-size review remain pending.

- `paintover-values.json`: authored sRGB appearance targets, linear luminance and wall-normalized brightness for four house types.
- `minimum-detail.md`: one-page ranked detail guide, with qualitative cost estimates and review criteria.

The palette is a design target, not a measurement or a shader implementation. Existing lighting and trees remain locked. No engine files or git operations were used.

## Pending paint-over prompt

Use case: precise-object-edit. Edit each provided WorldEngine Lakeview render individually. Keep its camera, full-frame composition, house footprints and existing lighting unchanged. Keep trees, vegetation, street, sky and all non-house pixels as close to source as possible. Change only house appearance and source-supported facade detail. Retain rich stylized 3D rendering. Strengthen dark soffits, coherent eave shadow bands, light trim against dark daytime glass, porch-roof underside/contact lines, projecting bay returns and broad cornice reveals. Preserve three-flat three-storey opening rhythm, two-flat two-storey rhythm, cottage narrow gable and bungalow broad low roof as applicable to each source. Separate brick and siding values. Avoid tiny brick textures, fine ornament, global outlines, relighting or changes to camera. Add no logos, real house numbers or people. Preserve required existing attribution outside the houses. Use supplied values as appearance guidance, with source lighting governing the final image.

Planned tool: built-in imagegen. No image-generation call has been made without the source renders.
