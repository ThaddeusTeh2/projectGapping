# Repo Scan — Project Gapping (2026-02-05)

Purpose: fast re-orientation for future agents. Focus: entrypoints, architecture, Firestore model/rules, and known mismatches.

## App entrypoints

- App start: [lib/main.dart](../lib/main.dart)
  - Initializes Firebase via `Firebase.initializeApp()` using [lib/firebase_options.dart](../lib/firebase_options.dart).
  - Logs the Firebase project/app IDs (debugPrint).
  - Runs `ProviderScope(child: App())`.

- App root widget: [lib/app/app.dart](../lib/app/app.dart)
  - Uses `ShadApp.router` (shadcn_ui) with `ThemeMode.dark`.
  - Global snackbar host: `AppSnackbar.messengerKey`.

- Router: [lib/app/router.dart](../lib/app/router.dart)
  - `GoRouter` auth redirect:
    - unauthenticated -> `/login`
    - authenticated -> `/bikes` (redirect away from `/login` + `/register`)
  - `StatefulShellRoute.indexedStack` tabs: Bikes / Shop / Profile.

- Home shell (tabs): [lib/app/home_shell.dart](../lib/app/home_shell.dart)

- DI/providers: [lib/di/providers.dart](../lib/di/providers.dart)
  - `firebaseAuthProvider`, `firebaseFirestoreProvider`
  - Repository providers: Auth/Bikes/Comments/Listings/Bids/Users
  - `authStateChangesProvider` + `GoRouterRefreshStream` for router refresh
  - Public display name stream: `displayNameByUidProvider` (backs seller/leader/winner labels)

## Dependencies (notable)

- State/nav: `flutter_riverpod`, `go_router`
- Firebase: `firebase_core`, `firebase_auth`, `cloud_firestore`
- UI: `shadcn_ui`

See [pubspec.yaml](../pubspec.yaml).

## Data model (collections)

Centralized names: [lib/data/firestore/firestore_paths.dart](../lib/data/firestore/firestore_paths.dart)

- `motorcycles` (public read)
- `listings` (public read)
- `bids` (public read; authenticated create)
- `comments` (+ `comments/{commentId}/votes/{userId}`)
- `users` (private; owner-only)
- `public_users` (public read display-name surface)

Key listing model: [lib/domain/models/shop_listing.dart](../lib/domain/models/shop_listing.dart)
- `toFirestore()` omits nullable fields when unset (some rules rely on “absent, not null”).

Bid model: [lib/domain/models/bid.dart](../lib/domain/models/bid.dart)
- NOTE: file comment claims bids are Cloud-Function-created, but the client currently writes `bids/*` directly (see repository section).

Canonical enums/brands: [lib/domain/enums.dart](../lib/domain/enums.dart)

## Repository layer (MVVM boundary)

- Bikes: [lib/data/firestore/firestore_bike_repository.dart](../lib/data/firestore/firestore_bike_repository.dart)
  - Fetch is intentionally broad (`limit(...)`) and sorting/filtering is local (avoid composite index explosion).

- Listings: [lib/data/firestore/firestore_listing_repository.dart](../lib/data/firestore/firestore_listing_repository.dart)
  - `listListings(...)` uses stable query shape: `where(isClosed).orderBy(dateCreatedMillis desc).limit(...)`.
  - Additional filters (brand/category/bucket) are applied locally.
  - Implements:
    - `buyoutListing()` via Firestore transaction
    - `autoCloseExpiredListing()` via Firestore transaction (deterministic `closedAtMillis = closingTimeMillis`)
    - `closeListing()` via direct update (sends `closingBid` only when non-null)

- Bidding: [lib/data/firestore/firestore_bid_repository.dart](../lib/data/firestore/firestore_bid_repository.dart)
  - Uses a Firestore transaction that:
    - updates the listing bid state (`currentBid`, `hasBid`, `currentBidderId`)
    - writes a bid-history record to `bids/{bidId}`
  - Enforces basic invariants client-side (not owner, not closed, before `closingTimeMillis`, amount > current / >= starting).

- Comments + votes: [lib/data/firestore/firestore_comment_repository.dart](../lib/data/firestore/firestore_comment_repository.dart)
  - `watchCommentsForBike()` streams by `bikeId` then sorts locally by `dateCreatedMillis`.
  - Voting uses transaction:
    - create `comments/{commentId}/votes/{userId}`
    - increment either `upvoteCount` or `downvoteCount`

- Users/profile: [lib/data/firestore/firestore_user_repository.dart](../lib/data/firestore/firestore_user_repository.dart)
  - `ensureUserDoc()` upserts minimal user doc.
  - `ensurePublicUserDoc()`/`setPublicDisplayName()` manage `public_users/{uid}`.
  - `listMyListings()` queries `listings` by `sellerId`.
  - `listMyBids()` queries `bids` by `bidderId`.

## ViewModels/screens (high-signal)

- Listing detail auto-close + bidding/buyout/close:
  - VM: [lib/features/shop/listing_detail_view_model.dart](../lib/features/shop/listing_detail_view_model.dart)
    - Best-effort `autoCloseExpiredListing()` when viewing an expired open listing.
    - After bid/buyout/close, invalidates Profile VM so “My bids/listings” refresh.
  - UI: [lib/features/shop/listing_detail_screen.dart](../lib/features/shop/listing_detail_screen.dart)
    - Normalizes `StateError` messages by stripping `Bad state: ` prefix.

- Shop directory local filtering/sorting:
  - VM: [lib/features/shop/shop_directory_view_model.dart](../lib/features/shop/shop_directory_view_model.dart)
  - Fetches open/closed listings with `limit: 500` each to enable local filtering.

- Listing creation denormalizes required fields:
  - VM: [lib/features/shop/create_listing_view_model.dart](../lib/features/shop/create_listing_view_model.dart)

- Profile:
  - VM: [lib/features/profile/profile_view_model.dart](../lib/features/profile/profile_view_model.dart)
  - Ensures `users/{uid}` exists and best-effort ensures `public_users/{uid}`.

## Firestore rules + indexes

Rules file: [firestore.rules](../firestore.rules)

- Repo rules are deployable and currently cover:
  - `motorcycles`: public read
  - `listings`: public read + create/update flows (seller close, buyout, auto-close, bid-bump)
  - `bids`: public read + authenticated create, immutable thereafter
  - `public_users`: public read + owner-only upsert of `{displayName, updatedAtMillis}` with length constraints
  - `comments` + `votes`: public read, signed-in create; voting is “one vote doc then +1 counter”
  - `users`: owner-only read/write

Indexes file: [firestore.indexes.json](../firestore.indexes.json)
- Listings composite indexes:
  - `(isClosed asc, dateCreatedMillis desc)`
  - `(isClosed asc, closingTimeMillis asc)`

## Seeding

- Seed pack: [lib/seeding/seed_pack.json](../lib/seeding/seed_pack.json)
  - Contains a `meta` block (generated time + note about shifting `closingTimeMillis` if importing much later).
- Seeder script: [lib/seeding/seeder.py](../lib/seeding/seeder.py)
  - Uses `firebase_admin` service account JSON (default path: `lib/seeding/serviceAccountKey.json`).
  - Supports `--dry-run`, `--batch-size`, and `--no-merge`.

## Known mismatches / risk notes

- Listing bid-bump rules are permissive: they do **not** currently enforce “bid must increase” or “bid must be before closing time”. The client enforces this, but a malicious client could bypass.
- Seller listing updates are “equality constrained” but not exhaustively key-locked (e.g., some fields like `dateCreatedMillis`/`listingComments` are not explicitly frozen in rules).
- Bid domain model comment is stale: [lib/domain/models/bid.dart](../lib/domain/models/bid.dart) says bids are Cloud Function-created, but the app writes them in [lib/data/firestore/firestore_bid_repository.dart](../lib/data/firestore/firestore_bid_repository.dart).
- Comments create rule is broad (`allow create: if isSignedIn()`), so comment schema validation is largely app-side.
- Demo-scale tradeoff: Shop VM fetches up to 500 open + 500 closed listings to enable local filtering.
