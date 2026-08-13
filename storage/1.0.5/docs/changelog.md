# Changelog

Version history for `storage`. The next release is **1.0.5**; the currently
published LXS is **1.0.4** (registry `lxs.yml` version field). Release
boundaries below are approximated from the git log since the registry
`release:` list is empty.

## 1.0.5 (next release)

- Fix thumbnail deletion on object delete: derive the `-thumb.webp` key from
  the object key by stripping the extension (previously the derived key was
  wrong) and delete using the S3 **bucket**, not the key as the bucket
  (`455513d`, `b87c450`).
- Fix thumbnail generation for RGBA images: encode thumbnails to RGB8 before
  JPEG encoding (`69fea78`).
- Add `category: Media` to the LXS manifest (`ca71c72`).

## 1.0.4 (current)

- Video upload timeout hardening: `ffmpeg` runs with `-preset veryfast` + all
  cores (`-threads 0`) and a **300s** cap; timed-out child processes are
  killed and temp files cleaned. Error messages are English
  (`408 Video processing timed out...`) (`23ab1d9`).
- Use the `storage_backend` lib crate (renamed) in the binary (`281406d`).

## 1.0.3

- Rename the domain and crate `photos` → `storage`/`storage-backend`; rename
  the LXS manifest name to `storage` (the domain stays "photos") (`2b8f8e4`,
  `0c02f12`).
- Add the LXS manifest (`photos@1.0.0`) and ignore the build-artifact map
  (`63fed5c`).

## 1.0.2

- Add a lib crate with `bootstrap()` so the service can be composed as a
  single binary via the eco `storage_backend` crate (`ae4ec07`).

## 1.0.1

- Downscale images even when the WebP re-encode is larger than the original
  (the resize was being skipped) (`70d3b6a`).
- Return **404** (not 502) for missing storage objects so thumbnail `onerror`
  fallbacks and caches behave correctly (`58db364`).
- Downscale images + generate WebP thumbnails on upload; add the ffmpeg
  timeout to prevent hung video uploads; delete the `-thumb.webp` sibling on
  object delete (`5a57fa4`).
- Document the `PUBLIC_MAX_VIDEO_MB` frontend pairing (`c40764a`).
- Keep the transcoded temp file alive until the S3 `PutObject` completes
  (`6e79e1d`).

## 1.0.0 — initial release as reusable LXS

- ffmpeg-compressed video uploads + Range streaming (`6e3c8bd`).
- Make upload limits configurable via env; image cap to 10 MB (`b156cb2`).
- Serve images inline so email clients render them (`fad8474`).
- Image cap to 5 MB with a clear rejection message (`2fa1c5f`); raise the
  multipart body limit from the 2 MB default (`f49ac3f`).
- Preserve original filenames on downloads (`adcbbe7`).
- Turn the photos domain into reusable S3 storage (`cbe76d4`).
- Prototype: presigned upload + file serving endpoints (`47ecf34`); initial
  commit of the photos domain backend (Rust) (`4183c53`).
