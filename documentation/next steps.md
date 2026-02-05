# Next Steps — Sprint Checklist (Project Gapping)

Source of truth: [ssot.md](ssot.md)

Goal: a day-by-day, checkbox-driven build plan that includes **what to create**, **where it lives**, and **what it does**.

---

## DAY 0 — Freeze spec + seed dataset (2–3 hours)

### Product/spec lock
- [x] Confirm final enums:
  - [x] `bikeCategory`: Sport, Naked, Scooter, Adventure, Cruiser, Offroad
  - [x] `brandKey` + `brandLabel` canonical lists (see SSOT)
  - [x] `displacementBucket`: `0_150`, `151_250`, `251_400`, `401_650`, `651_plus`
- [x] Confirm marketplace is **bid-only** (no fixed-price-only mode)
- [x] Confirm listing duration presets: 1h, 6h, 24h, 3d

### Seed data
- [x] Prepare a JSON seed pack (target: 40 bikes, 10 listings)
  - [x] Bikes cover all categories + buckets + multiple brands
  - [x] Listings cover multiple categories/buckets, mixed close times
- [x] Decide import method:
  - [ ] Firestore console manual add (slow)
  - [x] Firestore import (JSON) / scripted seeding (preferred)
- [x] Ensure service account key is gitignored (do not commit)

Repo reality (current):
- [x] Seed pack lives at `lib/seeding/seed_pack.json`
- [x] Seeder script lives at `lib/seeding/seeder.py` (Python + firebase_admin)

### Planned Firestore indexes (write down now)
- [x] Motorcycles:
  - [x] `(brandKey, category, displacementBucket, titleLower asc)`
  - [x] `(brandKey, category, displacementBucket, dateCreatedMillis desc)`
  - [x] `(brandKey, category, displacementBucket, releaseYear desc)`
- [x] Listings:
  - [x] `(isClosed, brandKey, category, displacementBucket, dateCreatedMillis desc)`
  - [x] `(isClosed, closingTimeMillis asc)`

---

## DAY 1 — Flutter skeleton (routing + auth gate + UI primitives)

### Dependencies (pubspec)
- [x] Add packages:
  - [x] `flutter_riverpod`
  - [x] `go_router`
  - [x] `firebase_core`
  - [x] `firebase_auth`
  - [x] `cloud_firestore`
  - [x] `shadcn_ui`

### Create folders (target structure)
- [x] Create `lib/app/` (app shell concerns)
- [x] Create `lib/core/` (reusable UI + utils + validation)
- [x] Create `lib/domain/` (pure models + enums)
- [x] Create `lib/data/` (repo interfaces + Firestore implementations)
- [x] Create `lib/features/` (feature modules)
  - [x] `lib/features/auth/`
  - [x] `lib/features/bikes/`
  - [x] `lib/features/shop/`
  - [x] `lib/features/profile/`

### Files to create (and responsibilities)
- [x] `lib/app/app.dart`
  - Responsibility: top-level `MaterialApp.router` and theme hookup.
- [x] `lib/app/router.dart`
  - Responsibility: go_router routes + auth redirect logic.
- [x] `lib/app/theme.dart`
  - Responsibility: shadcn_ui-based theme tokens, typography, colors.
- [x] `lib/di/providers.dart`
  - Responsibility: global Riverpod providers (Firebase instances, auth state, router refresh, router provider).
- [x] `lib/core/ui/app_scaffold.dart`
  - Responsibility: consistent scaffold wrapper used by all screens.
- [x] `lib/core/ui/loading_view.dart`
  - Responsibility: standard loading state.
- [x] `lib/core/ui/empty_state_view.dart`
  - Responsibility: standard empty list state.
- [x] `lib/core/ui/error_state_view.dart`
  - Responsibility: standard failure UI with retry.
- [x] `lib/core/ui/app_snackbar.dart`
  - Responsibility: consistent mutation feedback (errors/success).
- [x] Update `lib/main.dart`
  - Responsibility: initialize app entrypoint and run `App()`.

### Routes to wire (no feature logic yet)
- [x] Public:
  - [x] `/login`
  - [x] `/register`
- [x] Protected:
  - [x] `/home` (tab shell)
  - [x] `/bikes`
  - [x] `/bike/:id`
  - [x] `/shop`
  - [x] `/listing/:id`
  - [x] `/listing/create`
  - [x] `/profile`

### UI shell / navigation
- [x] `lib/app/home_shell.dart`
  - Responsibility: bottom nav tabs: Bikes / Shop / Profile
  - Contains: nested navigation target for each tab

---

## DAY 1–2 — Firebase init (Android-only)

### Firebase project setup
- [x] Create Firebase project
- [x] Register Android app (package name must match)
- [x] Add `google-services.json` into `android/app/`
- [x] Enable Email/Password in Auth
- [x] Enable Firestore

### FlutterFire integration
- [x] Decide integration approach:
  - [x] FlutterFire CLI (recommended)
  - [x] Manual `firebase_options.dart` creation (fallback)

### Smoke tests
- [x] App launches and shows login screen
- [x] Auth state changes refresh router

---

## DAY 2 — Domain + data layer (models + repositories + validation)

### Domain files
- [x] `lib/domain/enums.dart`
  - Responsibility: canonical enums + mapping helpers:
    - brandKey/brandLabel mapping
    - displacementBucket labels
- [x] `lib/domain/models/bike.dart`
  - Responsibility: `Bike` model + Firestore serialization.
- [x] `lib/domain/models/bike_comment.dart`
  - Responsibility: `BikeComment` + serialization.
- [x] `lib/domain/models/shop_listing.dart`
  - Responsibility: `ShopListing` + serialization.
- [x] `lib/domain/models/bid.dart`
  - Responsibility: `Bid` + serialization.
- [x] `lib/domain/models/app_user.dart`
  - Responsibility: minimal user profile representation.

### Core utils
- [x] `lib/core/utils/time.dart`
  - Responsibility: `nowMillis()`, preset duration → `closingTimeMillis`.
- [x] `lib/core/validation/validators.dart`
  - Responsibility: shared form + business validators:
    - email/password
    - comment title/body
    - listing create constraints
    - bid amount constraints (client-side pre-check)

### Repository interfaces
- [x] `lib/data/repositories/auth_repository.dart`
  - Responsibility: auth API contract.
- [x] `lib/data/repositories/bike_repository.dart`
  - Responsibility: bike queries.
- [x] `lib/data/repositories/comment_repository.dart`
  - Responsibility: comment list/add/vote.
- [x] `lib/data/repositories/listing_repository.dart`
  - Responsibility: listing list/get/create/close.
- [x] `lib/data/repositories/bid_repository.dart`
  - Responsibility: bid placement via repository boundary (implementation defined in Day 6 track).
- [x] `lib/data/repositories/user_repository.dart`
  - Responsibility: profile read + my lists.

### Firestore implementations
- [x] `lib/data/firestore/firestore_paths.dart`
  - Responsibility: collection names/constants.
- [x] `lib/data/firestore/firestore_auth_repository.dart`
- [x] `lib/data/firestore/firestore_bike_repository.dart`
- [x] `lib/data/firestore/firestore_comment_repository.dart`
- [x] `lib/data/firestore/firestore_listing_repository.dart`
- [x] `lib/data/firestore/firestore_bid_repository.dart`
- [x] `lib/data/firestore/firestore_user_repository.dart`

### Providers
- [x] Wire Riverpod providers for:
  - [x] FirebaseAuth/FirebaseFirestore singletons
  - [x] Each repository
  - [x] auth state stream provider

### Deliverable
- [x] Repository calls can read seeded bikes/listings (tested via simple screen or debug prints)

---

## DAY 3 — Bikes module (directory + detail + comments + votes)

### ViewModels
- [x] `lib/features/bikes/bike_directory_view_model.dart`
  - Responsibility: filter/sort state + list fetch state (loading/data/error).
- [x] `lib/features/bikes/bike_detail_view_model.dart`
  - Responsibility: single bike fetch + comments stream + actions (add comment, vote).

### Screens
- [x] `lib/features/bikes/bike_directory_screen.dart`
  - Responsibility: UI for filters + sort + list.
  - Must show: empty state, error state, retry.
- [x] `lib/features/bikes/bike_detail_screen.dart`
  - Responsibility: bike specs + SEA notes + comments list.
- [x] `lib/features/bikes/add_comment_sheet.dart` (or screen)
  - Responsibility: comment form + validation + submit.

### Firestore query behaviors
- [x] Bikes list fetches a broader slice and filters/sorts locally (demo-scale) to avoid composite-index combinatorics
- [x] Comments query is scoped by `bikeId` (sorted locally)
- [x] Comment voting is de-duped per user via vote docs + transaction + rules (`comments/{commentId}/votes/{userId}`)
- [x] Composite indexes are no longer required for Bikes/Shop/Profile list filtering (local filter/sort); keep index planning for Day 6 / future scale

### Deliverable
- [x] Browse bikes → open bike → add comment → vote increments counters

---

## DAY 4 — Profile module + community polish

### ViewModel
- [x] `lib/features/profile/profile_view_model.dart`
  - Responsibility: reads auth user, my listings, my bids; exposes loading/data/error.

### Screen
- [x] `lib/features/profile/profile_screen.dart`
  - Responsibility: sign out + my listings + my bids + empty states.

### Architecture addition (post-Day 3 refactor)
- [x] List screens fetch broader slices from Firestore and filter/sort locally to avoid composite-index combinatorics (demo-scale approach)
- [x] Repositories remain the only Firebase SDK boundary; UI still does not call Firestore directly

### Error/UX polish
- [ ] Standardize error messages:
  - [ ] auth required
  - [ ] permission denied
  - [ ] offline/network
- [ ] Ensure all list screens show:
  - [x] loading
  - [x] empty
  - [x] error + retry

---

## DAY 5 — Shop module (listings + listing detail + create listing + bid UI)

### ViewModels
- [x] `lib/features/shop/shop_directory_view_model.dart`
  - Responsibility: listing filters + fetch state.
- [x] `lib/features/shop/listing_detail_view_model.dart`
  - Responsibility: listing fetch + place bid action + close listing action.
- [x] `lib/features/shop/create_listing_view_model.dart`
  - Responsibility: form state, validation, publish listing.

### Screens
- [x] `lib/features/shop/shop_directory_screen.dart`
  - Responsibility: filter UI + listing cards + empty/error states.
- [x] `lib/features/shop/listing_detail_screen.dart`
  - Responsibility: listing info + bid form + seller controls.
- [x] `lib/features/shop/create_listing_screen.dart`
  - Responsibility: select bike + form fields + duration presets.

### Listing denormalization (must do)
- [x] On listing creation, write these fields on listing doc:
  - [x] `brandKey`, `brandLabel`, `category`, `displacementBucket`, `bikeTitle`

### Deliverable
- [x] Create listing → show in shop list → open detail
- [x] Bid UI + client-side validation wired (calls `BidRepository`)
- [x] Seller “close listing early” UI + repository update payload implemented (may still be denied by remote rules depending on your deployed rule constraints)
- [x] Place bid end-to-end (Spark-plan pivot: Firestore transaction updating listing bid fields)
- [x] Buyout flow closes listing + sets winner/closingBid
- [x] Best-effort client-side auto-close for expired listings (transactional)

Notes:
- Spark-plan enforcement is implemented via Firestore transactions:
  - `FirestoreBidRepository` writes bid history to `bids/{id}` and updates `listings/{id}` bid fields.
  - `FirestoreListingRepository` implements buyout + auto-close (writing `closingBid` + `winnerUserId` when applicable).
- `firestore.rules` is partially strict (seller close/buyout/autoclose, comment vote constraints). The bidder-only “restrict updates to only bid fields” block is currently commented out and should be finished.
- Client listing serialization omits unset nullable fields (e.g. `currentBid`, `closedAtMillis`, `closingBid`) because some rules require fields to be absent (not null) in certain states.


---

## DAY 6 — Security rules + Spark-plan bidding pivot (Firestore-only)

Pivot: We are choosing the Spark-plan track described in SSOT Addendum (2026-01-23). Cloud Functions are not used.

### Firestore Security Rules
- [x] Create `firestore.rules`
  - Responsibility: enforce ownership + constrain listing mutations + allow bid doc creation.
- [x] Create `firestore.indexes.json` (optional but recommended)
  - Responsibility: track composite indexes for repeatable setup.

Minimum rules checklist (Spark-plan track):
- [x] Allow authenticated create to `bids/*` with required fields (`listingId`, `bidderId`, `amount`, `dateCreatedMillis`)
- [x] Restrict bidder updates to `listings/{listingId}` to bid fields only (`hasBid`, `currentBid`, `currentBidderId`) as guard rails (no strict “must be higher” comparisons in rules)
- [x] Keep seller-only control for closing (`isClosed`, `closedAtMillis`, `closingBid`, `winnerUserId`) with bid/no-bid paths
- [x] Allow create listing only if `request.auth.uid == sellerId`
- [x] Allow create comments only if authenticated
- [x] Enforce one vote per user per comment via `comments/{commentId}/votes/{userId}`

Note: Firestore rules cannot fully enforce auction invariants without a trusted server, so we will treat rules as “guard rails” and keep the transaction logic in the repository.

### Client implementation (transactional bidding)
- [x] Rewrite `lib/data/firestore/firestore_bid_repository.dart`:
  - Responsibility: implement `placeBid()` using Firestore `runTransaction`
  - Reads listing → validates open/not expired/higher bid → updates listing (`currentBid`, `hasBid`, `currentBidderId`)
- [x] Ensure `BidRepository.placeBid()` surfaces meaningful errors (permission denied, outbid, expired, closed)
- [x] Remove `cloud_functions` dependency from `pubspec.yaml`
- [x] Update DI wiring in `lib/di/providers.dart` (remove Functions wiring; use Firestore repo)

### Deliverable
- [x] Place bid works end-to-end on Spark plan (transactional listing updates)
- [x] Clear user-visible errors for: expired listing, closed listing, low bid, permission denied
- [x] Tighten Firestore rules without breaking bidding

---

## DAY 7 — Final polish + demo readiness

### UX checklist (must visibly demonstrate)
- [ ] Validation errors show inline for:
  - [x] login/register
  - [x] add comment
  - [x] create listing
  - [x] place bid
- [ ] Auth-required feedback:
  - [x] posting comment
  - [x] creating listing
  - [x] bidding
- [ ] Permission denied feedback:
  - [x] closing listing (non-owner)
- [ ] Network failure UI:
  - [x] list fetch failure shows error + retry
  - [x] mutation failure shows error message from server
- [ ] Empty states for:
  - [x] bikes list
  - [x] comments list
  - [x] listings list
  - [x] profile lists

### Demo script (2–3 minutes)
- [x] Register user A → browse bikes → open bike → add comment → vote
- [x] Create listing as user A (preset duration)
- [x] Sign out → login user B → place bid
- [x] Show server-side rejection by attempting a low bid
- [x] Wait/trigger close behavior → show listing closed + closingBid
- [x] Profile shows my listings / my bids

### Cleanup
- [ ] Remove debug prints and dead code
- [ ] Ensure consistent copy for error/empty messages
- [ ] Verify the app cold starts correctly (auth guard doesn’t flicker)

---

## POST–DAY 7 — What actually shipped (tracked via commits)

This section exists because the project continued evolving after Day 6/7.

### UI + theme + snackbar reliability
- [x] shadcn migration polish across remaining screens (forms/buttons/cards)
- [x] OLED/high-contrast outlines for cards/inputs + mono typography (JetBrains Mono)
- [x] Standardize dividers using `ShadSeparator.horizontal`
- [x] Root snackbar reliability (global messenger wiring) so mutation errors always surface

### Shop correctness & UX
- [x] Buyout transaction (sets bid state + closes instantly; persists `winnerUserId`/`closingBid`)
- [x] Best-effort auto-close for expired listings + hide expired items from the "open" section
- [x] Persist bid history docs to `bids/*` so Profile “My Bids” is populated
- [x] Refresh Profile after bid/buyout/close by invalidating profile provider
- [x] Hide Seller Controls on closed listings

### Directory search + controls
- [x] Bikes + Shop local multi-field search with cached results (typing doesn’t refetch)
- [x] Compact accordion controls for Filters/Sort + one-tap Clear resets query + filters
- [x] Create Listing bike selection: searchable bottom-sheet picker (combobox-style)
- [x] Listing Detail readability: section cards + divider-separated label/value blocks
- [x] Denormalize optional `bikeReleaseYear` onto listings + enforce immutability in rules

### Comments voting (one vote per user)
- [x] Vote docs at `comments/{commentId}/votes/{userId}` + transaction-based counter increment
- [x] Tightened rules to prevent repeat votes and constrain counter increments

### Identity (public display names)
- [x] Add `public_users/{uid}` rules and data layer support for `displayName`
- [x] Register/Profile UX to set/edit displayName
- [x] Render displayName across comments/listings/shop (fallback to short UID)
- [x] Make displayName updates reactive (stream provider backed by Firestore snapshots)

### App assets
- [x] Updated `pubspec.yaml` + assets folder for splash image
- [x] Added/used `flutter_native_splash`
