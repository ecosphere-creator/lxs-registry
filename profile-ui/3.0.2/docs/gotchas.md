# profile-ui gotchas

- Profile settings pages are protected by the gateway `eco_token` cookie. The
  UI uses `eco_session` when available and rebuilds it from that cookie when
  browser storage was cleared, so a valid SSR/Gateway session must never be
  redirected to sign-in merely because local storage is empty.
- Use the canonical `/api/profile/users/<id>` prefix. Do not hard-code
  `/api/users` in an estate because it collides with other domains.
- Avatar upload needs the Profile `STORAGE_BASE_URL` composition. The UI does
  client-side resizing but Profile still enforces its own byte limits.
- Password change uses Auth's legacy query parameters
  (`currentPassword`, `newPassword`) and requires the current password; lost
  passwords use Auth UI's public forgot/reset pages instead.
