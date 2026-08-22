# profile-ui api

GET /profile (and `/profile-edit`) — SSR settings page that loads the Auth
session, updates name and bio through `PROFILE_API_BASE` (`/api/profile` by
default), uploads an avatar through Profile + Storage, and changes the signed
in user's password through `AUTH_API_BASE` (`/auth-api` by default).
