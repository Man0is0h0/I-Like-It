# Implementation Plan: 7 Client Changes

## Overview
7 targeted changes spanning UI fixes, new features, and one new screen.
No DB schema changes required — all columns already exist in local SQLite and Supabase.

---

## Architecture Decisions

- **Change 3 (search→folder nav):** Pass `folderId` + `linkId` from search result. Navigate to `LinkScreen`, pass `highlightLinkId`. `LinkScreen` uses `ScrollController` + `AnimationController` to scroll to and flash the item.
- **Change 6 (profile):** New `ProfileScreen`. Data read from `UserSessionManager` (already has email, userId). Mobile + username fetched from Supabase `public.users` or local prefs. Save pushes update to Supabase.
- **Change 7 (thumbnail border):** Root cause — `clipBehavior: Clip.antiAlias` on a `Container` that also owns the `border` decoration clips the border stroke itself at corners. Fix: outer container holds border only (no clip), inner `ClipRRect` holds the image.

---

## Task List

### Phase 1: Quick Wins (independent, low risk)

- [ ] **Task 1** — Rename predefined folder "Movies/Music" → "Movies"
- [ ] **Task 2** — Fix thumbnail border corner clip bug
- [ ] **Task 3** — Generic title blank + hint on share save dialog

### Checkpoint A
- [ ] Hot reload, visual check on 3 fixes

### Phase 2: Search Improvements

- [ ] **Task 4** — Search by notes (already in DB query — verify + confirm in UI)
- [ ] **Task 5** — Search result tap → navigate to folder + highlight link

### Checkpoint B
- [ ] Test search flow end-to-end on device

### Phase 3: Country Code + Profile Screen

- [ ] **Task 6** — Add country code picker to signup + edit flows
- [ ] **Task 7** — Build Profile Screen

### Checkpoint C
- [ ] Full regression: signup, search, profile, save Instagram reel

---

## Risks

| Risk | Impact | Mitigation |
|---|---|---|
| Rename "Movies/Music" — existing users already have old name | Low | Add one-time migration at app start: check if folder name exists, rename locally + sync |
| Search→folder highlight — `LinkScreen` uses `SliverList`, scroll-to-index needs `ScrollController` | Medium | Use `Scrollable.ensureVisible` with a `GlobalKey` on the highlighted item |
| Country code — existing users stored number without code | Low | Treat stored numbers as-is; only new edits require country code |
| Profile save → Supabase `public.users` RLS may block update | Medium | Already have policy "Users can update own profile" — test with RLS on |

---

## Open Questions (need confirmation before coding)

1. **Change 1 — existing users:** Rename "Movies/Music" for existing users automatically, or leave old accounts as-is?
2. **Change 3 — search tap behavior:** Should tapping a FOLDER result also stay the same (open `LinkScreen`)? Only LINK results change to navigate-to-folder?
3. **Change 6 — profile avatar:** Show a generated avatar (initials) or leave it as the icon already in the app header?
4. **Change 6 — save scope:** Save username + mobile to Supabase only, or also update local SQLite/prefs?
