# Changelog

Versions tracked from `git log`, the domain README.md, and the registry
manifest (`lxs.yml`). The manifest's `release:` list is empty and no git tags
exist, so only versions explicitly recorded are listed; 1.0.1 has no record.

## 1.0.2 (next release)
- feat: per-user COD meeting location (`codLocation`) on profiles
- chore: add `category: Identity` to the LXS manifest

## 1.0.1
- No notes on record (registry `release:` list is empty; no git tags).

## 1.0.0
- initial release
- Port the profile domain from `lms-backend` Java (`UserController` /
  `UserService` + `SchoolController` / `InterestController` / `SkillController`)
  to Rust/axum
- Add per-source-IP rate limiting across all routes
- Switch to structured JSON logs and add request-correlation ids
  (`x-request-id` propagation to auth)
- Add integration test suite
- Add `bootstrap()` to the lib crate for single-binary composition and
  register sub-routes before the catch-all `:user_id` for merge compatibility
- Add LXS manifest (`profile@1.0.0`)
