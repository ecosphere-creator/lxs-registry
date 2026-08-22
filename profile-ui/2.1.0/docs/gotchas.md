# profile-ui gotchas

- Profile settings pages need both gateway cookie validation (`eco_token`) and
  the local Auth UI session (`eco_session`) for browser API calls. A page may
  pass the gateway but redirect to sign-in if a user cleared local storage.
- Use the canonical `/api/profile/users/<id>` prefix. Do not hard-code
  `/api/users` in an estate because it collides with other domains.
- Avatar upload needs the Profile `STORAGE_BASE_URL` composition. The UI does
  client-side resizing but Profile still enforces its own byte limits.
- Password change uses Auth's legacy query parameters
  (`currentPassword`, `newPassword`) and requires the current password; lost
  passwords use Auth UI's public forgot/reset pages instead.
