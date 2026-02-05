
# Project Gapping — Developer Guide

This document is a high-signal overview of the codebase intended for maintainers and contributors. It helps you open any file in `lib/` and understand what each class/function/block is doing, why it exists, and how it connects to the rest of the app.

## Tech stack & constraints

- Flutter
- Firebase: Auth + Firestore
- Riverpod for dependency injection + state
- go_router for navigation
- MVVM + repository boundary (UI never calls Firestore directly)
- Correctness-sensitive mutations (bidding/voting) use client-side Firestore transactions plus rules as guard rails

---

## 0) App overview

Project Gapping is a Motorcycle Ownership Hub with three core tabs:

1) **Bikes**: browse a seeded bike directory, open bike details, and participate via comments and voting.
2) **Shop**: create bid-only listings, place bids, buy out listings, and see winners.
3) **Profile**: view your account info, edit your public display name, and see your listings + bids.

Architecture:
- The app boots in `main.dart`, initializes Firebase, and runs `App` inside a Riverpod `ProviderScope`.
- `App` builds the router-based shell, provides the global snackbar messenger, and installs the dark OLED theme.
- Every feature uses MVVM: screens read state from Riverpod ViewModels, and ViewModels call **repository interfaces** (contracts) that are implemented by Firestore repositories.
- Firestore reads use either snapshots (for live updates like comments + display names) or one-shot gets (for detail fetches). Mutations use transactions where correctness matters (voting and bidding).

---

## 1) Mental model: “Who calls whom”

Use this call-stack lens when explaining any code path:

`Screen Widget` → reads/watches → `ViewModel (Notifier)` → calls → `Repository interface` → implemented by → `Firestore*Repository` → uses → `FirebaseFirestore/FirebaseAuth`

Cross-cutting utilities:
- `Validators` provide input validation logic.
- `AppSnackbar` is the standard error/success surface.
- `AppScaffold`/`LoadingView`/`EmptyStateView`/`ErrorStateView` keep UI consistent.

---

## 2) Data model cheat sheet (what exists in Firestore)

Collections (see `FirestorePaths`):
- `motorcycles`: seeded directory data (bikes)
- `comments`: per-bike comments; each comment has a `votes` subcollection
- `listings`: shop listings; includes bid state + closure fields
- `bids`: bid history docs (written during bid transaction)
- `users`: minimal private user doc (created on profile load)
- `public_users`: public identity surface: `displayName` for UID → name resolution

Where correctness lives:
- **Voting**: transaction creates immutable vote doc (`comments/{id}/votes/{uid}`) and increments counters.
- **Bidding**: transaction checks listing state and updates listing + writes a bid history doc.

---

## 3) Core patterns & conventions

### Riverpod basics (used everywhere)

- `Provider<T>`: returns a singleton-ish dependency (e.g., `FirebaseAuth.instance`).
- `StreamProvider<T>`: exposes a stream as an `AsyncValue<T>` (auto rebuild on new values).
- `NotifierProvider` / `AutoDisposeNotifier`: ViewModel with mutable `state`.
- `family`: provider parameterization (e.g., `displayNameByUidProvider(uid)` or `bikeDetailViewModelProvider(bikeId)`).
- `autoDispose`: provider is disposed when no longer listened to (helps avoid leaks).

Common calls:
- `ref.watch(provider)`: subscribes; widget/VM rebuilds when provider emits.
- `ref.read(provider)`: get once; no rebuild.
- `ref.listen(provider, ...)`: side effects (snackbar on mutation error).
- `ref.invalidate(provider)`: force refresh (used when profile should refetch after bid).

### AsyncValue (guard pattern)

- `AsyncValue.guard(() async { ... })` catches exceptions and returns `AsyncError` instead of throwing.
- ViewModels typically do:
	1) set `state` to loading
	2) run guarded async
	3) assign `state` to data/error

### go_router

- `GoRouter.redirect`: used as the auth gate.
- `refreshListenable`: router listens to auth state changes.
- `StatefulShellRoute.indexedStack`: keeps tab branch navigation stacks alive.

### Firestore & transactions

- Reads: `.get()` for one-shot, `.snapshots()` for realtime.
- Writes: `.set()` / `.update()`.
- Transactions: `runTransaction((tx) async { ... })` ensures read-modify-write consistency.
- `FirebaseException` handling: we wrap into `StateError` so UI can show a clean message.

---

## 4) Key app flows (with file chain)

### A) App startup + routing

1) `lib/main.dart` initializes Firebase and runs the app.
2) `lib/app/app.dart` builds `ShadApp.router` using the router from `goRouterProvider`.
3) `lib/di/providers.dart` provides the `goRouterProvider`, with refresh driven by auth stream.
4) `lib/app/router.dart` redirects:
	 - logged out + protected route ⇒ `/login`
	 - logged in + auth route ⇒ `/bikes`
5) `lib/app/home_shell.dart` provides bottom tabs.

### B) Auth

- UI screens: `login_screen.dart`, `register_screen.dart`
- Uses: `Validators.email/password/confirmPassword/displayName`
- Calls: `AuthRepository` (`FirestoreAuthRepository`)
- On register: best-effort write to `public_users/{uid}` via `UserRepository.setPublicDisplayName`

### C) Bikes directory → detail → comments

- Directory:
	- `bike_directory_screen.dart` shows filter/search/sort
	- `bike_directory_view_model.dart` fetches a broad slice (`repo.listBikes(limit: 500)`) and filters locally
- Detail:
	- `bike_detail_view_model.dart` fetches bike once and exposes comment mutation actions
	- Comments stream comes from `bikeCommentsProvider` → `CommentRepository.watchCommentsForBike`
- Add comment:
	- bottom sheet validates, then calls `BikeDetailViewModel.addComment`
- Voting:
	- uses Firestore transaction in `FirestoreCommentRepository._vote`

### D) Shop: create listing → list → detail → bid/buyout/close/auto-close

- Create:
	- `create_listing_screen.dart` selects bike + fills form
	- `create_listing_view_model.dart` denormalizes bike fields into listing doc
- Directory:
	- `shop_directory_view_model.dart` fetches open + closed slices and filters locally
	- `shop_directory_screen.dart` renders cards, uses `displayNameByUidProvider` for winners
- Detail:
	- `listing_detail_view_model.dart` reads listing, auto-closes expired best-effort, and performs actions
	- `listing_detail_screen.dart` validates bid amount, shows seller controls, uses display name resolver
- Bid correctness:
	- `FirestoreBidRepository.placeBid` transaction enforces: not owner, not closed, not expired, amount > currentBid or >= startingBid
- Buyout correctness:
	- `FirestoreListingRepository.buyoutListing` transaction enforces: not owner, not closed, not expired, buyout still available

### E) Profile: identity + my lists

- `profile_view_model.dart`:
	- watches auth stream (auto rebuild on sign-in/out)
	- ensures `users/{uid}` doc exists
	- ensures `public_users/{uid}` exists (best-effort)
	- reads `myListings`, `myBids`, and `displayName`
- `profile_screen.dart`:
	- edit display name dialog → `ProfileViewModel.updateDisplayName`
	- sign out

Identity reactivity (important UX behavior):
- `displayNameByUidProvider` is a **StreamProvider.family** that watches `public_users/{uid}`.
- Screens showing comment author / winner / seller labels update immediately after a displayName change.

---

## 5) File-by-file guide (how to orient quickly)

Tip: when you open a file you’re unfamiliar with, start with:
1) “This file is responsible for…”
2) “It’s used by …”
3) “The key types/functions are …”
4) “Flow: …”

### lib/main.dart

- Symbols: `main()`
- What it does:
	- Ensures Flutter binding
	- Initializes Firebase with platform options
	- Runs the app wrapped in `ProviderScope` (Riverpod root)
- Relationships:
	- Calls `App` from `lib/app/app.dart`
	- Depends on `lib/firebase_options.dart`

### lib/firebase_options.dart

- Symbols: `DefaultFirebaseOptions.currentPlatform` (generated)
- What it does:
	- Holds Firebase app configuration per platform
- Relationships:
	- Called by `Firebase.initializeApp` in `main.dart`

- Note:
	- It’s generated; you typically don’t hand-edit it.

---

## App folder

### lib/app/app.dart

- Symbols: `App extends ConsumerWidget`, `build()`
- What it does:
	- Watches `goRouterProvider` and feeds its router into `ShadApp.router`
	- Installs global `ScaffoldMessenger` using `AppSnackbar.messengerKey`
	- Applies OLED dark theme (Material + Shad)
- Relationships:
	- Reads router from `lib/di/providers.dart`
	- Uses theme from `lib/app/theme.dart`
	- Uses snackbar key from `lib/core/ui/app_snackbar.dart`

### lib/app/router.dart

- Symbols: `class AppRouter`, `AppRouter(...)` constructor, `final GoRouter router`
- What it does:
	- Defines all app routes and a redirect auth gate
	- Uses `StatefulShellRoute.indexedStack` so tab branches keep their state
- Key blocks:
	- `redirect`: blocks protected routes when logged out; prevents returning to login/register when already logged in
	- `branches`: bikes branch + shop branch + profile branch
- Relationships:
	- Screens in `lib/features/**`
	- Uses `HomeShell` for tab scaffolding

### lib/app/home_shell.dart

- Symbols: `class HomeShell`, `_onTap()`, `build()`
- What it does:
	- Hosts router navigation shell + bottom nav
	- `goBranch()` switches tabs and optionally resets tab to its root

### lib/app/theme.dart

- Symbols: `class AppTheme`, constants, `shadOledDark()`, `materialOledDark()`, `light()`
- What it does:
	- Creates an OLED-friendly dark palette
	- Forces mono typography (JetBrains Mono + fallback)
	- Aligns Material widgets and shadcn_ui widgets stylistically

---

## DI folder

### lib/di/providers.dart

- Symbols:
	- Providers: `firebaseAuthProvider`, `firebaseFirestoreProvider`, `*RepositoryProvider`, `authStateChangesProvider`, `displayNameByUidProvider`, `goRouterProvider`, `routerRefreshListenableProvider`
	- Class: `GoRouterRefreshStream extends ChangeNotifier`
- What it does:
	- Creates Firebase singleton providers
	- Binds repository interfaces to Firestore implementations
	- Gives go_router a `Listenable` that triggers redirect re-evaluation when auth changes
	- Exposes a reactive displayName stream provider per UID
- Key blocks:
	- `displayNameByUidProvider`: `StreamProvider.autoDispose.family<String?, String>` mapping UID → realtime public displayName
	- `GoRouterRefreshStream`: subscribes to a stream and calls `notifyListeners()` so router re-runs `redirect`

---

## Core folder

### lib/core/ui/app_scaffold.dart

- Symbols: `AppScaffold extends StatelessWidget`, `build()`
- What it does:
	- Standardizes scaffold padding + optional app bar

### lib/core/ui/app_snackbar.dart

- Symbols: `AppSnackbar` + `messengerKey`, `showError()`, `showSuccess()`
- What it does:
	- A consistent feedback surface
	- Uses a global messenger key so bottom sheets / nested navigators can still show snackbars

### lib/core/ui/loading_view.dart

- Symbols: `LoadingView`, `build()`
- What it does:
	- Standard loading UI with optional message

### lib/core/ui/empty_state_view.dart

- Symbols: `EmptyStateView`, `build()`
- What it does:
	- Standard empty state UI

### lib/core/ui/error_state_view.dart

- Symbols: `ErrorStateView`, `build()`
- What it does:
	- Standard error UI + retry callback

### lib/core/utils/time.dart

- Symbols: `ListingDurationPreset` enum, `nowMillis()`, `closingTimeMillisFromPreset()`
- What it does:
	- Converts UI preset duration → epoch millis used in Firestore listing docs

### lib/core/validation/validators.dart

- Symbols: class `Validators` + its static methods
- What it does:
	- Central validation rules for forms so logic is consistent across screens

---

## Domain folder

### lib/domain/enums.dart

- Symbols: `BikeCategory`, `DisplacementBucket`, `Brand`, `CanonicalBrands`
- What it does:
	- Canonical taxonomy used by filters + display
	- Parsing helpers keep Firestore strings compatible with enums

### lib/domain/models/bike.dart

- Symbols: `Bike`, `toFirestore()`, `Bike.fromFirestore()`, `copyWith()`, helpers `_readString/_readInt`
- What it does:
	- Strongly typed representation of `motorcycles` docs
	- Defensive parsing throws if Firestore shape is wrong

### lib/domain/models/bike_comment.dart

- Symbols: `BikeComment`, `toFirestore()`, `BikeComment.fromFirestore()`, helpers
- What it does:
	- Typed comment model; handles optional tags and default counters

### lib/domain/models/shop_listing.dart

- Symbols: `ShopListing`, `toFirestore()`, `ShopListing.fromFirestore()`, helpers
- What it does:
	- Typed listing model
	- `toFirestore()` omits null fields so rules can require “absent not null” on create

### lib/domain/models/bid.dart

- Symbols: `Bid`, `toFirestore()`, `Bid.fromFirestore()`, helpers
- What it does:
	- Typed bid history doc model
- Note:
	- Header comment mentions functions; current implementation writes bids client-side in a transaction.

### lib/domain/models/app_user.dart

- Symbols: `AppUser`, `toFirestore()`, `AppUser.fromFirestore()`
- What it does:
	- Minimal private user doc

### lib/domain/models/public_user.dart

- Symbols: `PublicUser`, `toFirestore()`, `PublicUser.fromFirestore()`
- What it does:
	- Public identity surface: displayName + timestamp

---

## Data folder (contracts + Firestore implementations)

### Repository interfaces (what ViewModels depend on)

- lib/data/repositories/auth_repository.dart — `AuthRepository`
- lib/data/repositories/bike_repository.dart — `BikeRepository` + `BikeSort`
- lib/data/repositories/comment_repository.dart — `CommentRepository`
- lib/data/repositories/listing_repository.dart — `ListingRepository`
- lib/data/repositories/bid_repository.dart — `BidRepository`
- lib/data/repositories/user_repository.dart — `UserRepository`

When defending interfaces: explain “this isolates Firebase SDK usage; lets us swap implementations and makes ViewModels testable.”

### lib/data/firestore/firestore_paths.dart

- Symbols: `FirestorePaths` constants
- What it does:
	- Prevents stringly-typed collection names across repo

### lib/data/firestore/firestore_auth_repository.dart

- Symbols: `FirestoreAuthRepository implements AuthRepository`
- What it does:
	- Wraps FirebaseAuth methods behind the interface

### lib/data/firestore/firestore_bike_repository.dart

- Symbols: `FirestoreBikeRepository implements BikeRepository`
- What it does:
	- Bikes list: fetches a broad slice, leaving filter/sort to ViewModel
	- Bikes detail: `.doc(id).get()`

### lib/data/firestore/firestore_comment_repository.dart

- Symbols: `FirestoreCommentRepository implements CommentRepository`, `_vote()`
- What it does:
	- `watchCommentsForBike`: server filter by `bikeId`, local sort by timestamp
	- `addComment`: writes new comment doc
	- `_vote`: transaction enforces one-vote-per-user (vote doc existence check)
- Key blocks:
	- `FieldValue.increment(1)` updates counters atomically
	- FirebaseException → StateError makes UI messages readable

### lib/data/firestore/firestore_listing_repository.dart

- Symbols: `FirestoreListingRepository implements ListingRepository`, `buyoutListing()`, `autoCloseExpiredListing()` + parsing helpers
- What it does:
	- Stable query shape: `where(isClosed).orderBy(dateCreatedMillis desc)`
	- Create listing: writes listing doc
	- Close listing: seller flow
	- Buyout listing: transaction enforces invariants
	- Auto-close: best-effort transaction closes expired listings

### lib/data/firestore/firestore_bid_repository.dart

- Symbols: `FirestoreBidRepository implements BidRepository`, `placeBid()` + parsing helpers
- What it does:
	- Transaction reads listing, validates invariants, then:
		- updates listing bid fields
		- creates a bid history doc
- Key invariants:
	- user must be signed in
	- cannot bid on own listing
	- listing open + not expired
	- amount increases strictly vs currentBid or >= startingBid

### lib/data/firestore/firestore_user_repository.dart

- Symbols: `FirestoreUserRepository implements UserRepository` + methods
- What it does:
	- Ensures `users/{uid}` minimal doc exists
	- Provides UID → displayName reads and **realtime watcher**
	- Profile queries for “my listings” and “my bids”

---

## Features folder (screens + ViewModels)

### Auth

#### lib/features/auth/login_screen.dart

- Symbols: `LoginScreen`, `_LoginScreenState`, `_submit()`
- What it does:
	- Form validation, loading state, calls `authRepo.signIn`, navigates to `/bikes`
	- Error handling via AppSnackbar

#### lib/features/auth/register_screen.dart

- Symbols: `RegisterScreen`, `_RegisterScreenState`, `_submit()`
- What it does:
	- Creates account via auth repo
	- Best-effort writes public displayName
	- Navigates to `/bikes`

### Bikes

#### lib/features/bikes/bike_directory_view_model.dart

- Symbols: `BikeDirectoryState`, `bikeDirectoryViewModelProvider`, `BikeDirectoryViewModel` and its setters
- What it does:
	- Fetch broad slice once and filters/sorts locally
	- Stores `_all` as the source list and pushes filtered list into `state.bikes`

#### lib/features/bikes/bike_directory_screen.dart

- Symbols: `BikeDirectoryScreen`, `_BikeDirectoryScreenState`, picker helpers, `_BikeFilterMenuAction`
- What it does:
	- UI controls for filter/sort/search
	- Renders list; navigates to `/bike/:id`

#### lib/features/bikes/bike_detail_view_model.dart

- Symbols: `BikeDetailState`, `bikeCommentsProvider`, `bikeDetailViewModelProvider`, `BikeDetailViewModel`
- What it does:
	- One-shot fetch bike
	- Exposes add comment + vote actions
	- Uses `_requireUid` to enforce auth-required actions

#### lib/features/bikes/bike_detail_screen.dart

- Symbols: `BikeDetailScreen`, `_UserLabel`, `_kvText`
- What it does:
	- Renders bike details + SEA notes + comment list
	- Shows add comment bottom sheet
	- Upvote/downvote calls into ViewModel
	- `_UserLabel` uses `displayNameByUidProvider` (reactive)

#### lib/features/bikes/add_comment_sheet.dart

- Symbols: `AddCommentSheet`, `_AddCommentSheetState`, `_submit()`
- What it does:
	- Form validation and submission through BikeDetailViewModel
	- Shows success/error snackbars

### Shop

#### lib/features/shop/shop_directory_view_model.dart

- Symbols: `ShopDirectoryState`, `ShopSort`, provider, `ShopDirectoryViewModel`
- What it does:
	- Fetches open + closed listings
	- Filters locally (including “hide expired open listings”)
	- Sorts open by newest or closingSoon; closed by close time

#### lib/features/shop/shop_directory_screen.dart

- Symbols: `ShopDirectoryScreen`, `_ListingCard`, filter menu
- What it does:
	- Search/filter/sort UI
	- Renders open + closed listing sections
	- FAB navigates to `/listing/create`
	- `_ListingCard` uses `displayNameByUidProvider` for winner labels

#### lib/features/shop/listing_detail_view_model.dart

- Symbols: `ListingDetailState`, provider, `ListingDetailViewModel`
- What it does:
	- Fetches listing
	- Best-effort auto-close expired listing once per VM lifecycle
	- `placeBid`, `closeListingEarly`, `buyoutListing`
	- Invalidates profile VM after actions so profile tab refreshes

#### lib/features/shop/listing_detail_screen.dart

- Symbols: `ListingDetailScreen`, `_SectionCard`, `_BidSection`, `_BidSectionState`, `_kv`, `_displayNameOrShort`
- What it does:
	- UI composition for listing detail
	- Bid form uses Validators and calls VM
	- Seller-only control shown conditionally
	- People section uses reactive display names

#### lib/features/shop/create_listing_view_model.dart

- Symbols: `CreateListingState`, provider, `CreateListingViewModel`
- What it does:
	- Loads bikes for picker
	- Tracks selected bike
	- `publishListing`: denormalizes bike into `ShopListing` and calls listing repository

#### lib/features/shop/create_listing_screen.dart

- Symbols: `CreateListingScreen`, modal bike picker, `_SelectedBikeCard`, `_DurationPicker`
- What it does:
	- Bike picker bottom sheet with local search
	- Listing form with duration preset
	- On success navigates to the new listing detail

### Profile

#### lib/features/profile/profile_view_model.dart

- Symbols: `ProfileData`, provider, `ProfileViewModel`, `updateDisplayName()`
- What it does:
	- Auth-reactive profile fetch
	- Ensures both `users` and `public_users` docs exist (best-effort)
	- Loads my listings/bids + displayName

#### lib/features/profile/profile_screen.dart

- Symbols: `ProfileScreen`, `_MyListingsSection`, `_MyBidsSection`, `_friendlyErrorMessage`
- What it does:
	- Shows displayName/email/uid
	- Edit display name dialog uses Validators + calls VM
	- Shows lists and navigates to listing detail
	- Friendly error mapping for common Firestore/auth failures

---

## 6) FAQ & design rationale

1) “Why Riverpod, and why repositories?”
	 - Riverpod gives declarative dependency injection and reactive state.
	 - Repository interfaces isolate Firebase SDK usage and keep UI pure.

2) “Why do you fetch broad slices and filter locally?”
	 - Tradeoff to avoid composite index combinatorics and keep queries stable. Where necessary, the code uses a stable query shape with indexes and does the remaining filtering/sorting locally.

3) “How do you stop double-voting?”
	 - Transaction checks for existing `votes/{uid}` doc; if exists, it aborts; otherwise it writes vote + increments counters.

4) “How does bidding stay correct without Cloud Functions?”
	 - Firestore transaction enforces invariants in-app for honest clients (not closed, not expired, amount monotonic).
	 - Rules are guard rails but can’t fully enforce auction correctness against a modified client on the Spark plan.

5) “Why do display names update live everywhere?”
	 - `displayNameByUidProvider` is stream-based and watches `public_users/{uid}` snapshots; any widget watching it rebuilds.

6) “Why `Future.microtask(_fetch)` in ViewModels?”
	 - Avoids doing async work directly inside `build()`; schedules after initial build so state is set predictably.

---

## 7) Suggested code tour (10–15 min)

1) Start at `lib/main.dart`: show Firebase init + ProviderScope.
2) Jump to `lib/app/router.dart`: explain auth redirect + tab shell routing.
3) Open `lib/di/providers.dart`: point out where Firebase + repos are wired.

4) Walk Bikes:
	 - Directory: show local filter strategy in VM.
	 - Detail: show comments stream provider and vote transaction in repo.

5) Walk Shop:
	 - Create listing: show denormalization.
	 - Place bid: show bid validation + transaction invariants.
	 - Mention auto-close.

6) Walk Profile:
	 - Edit displayName.
	 - Mention why comment/user labels update live.

7) Close with constraints: client-side transaction correctness vs server-enforced guarantees.

---

## 8) Security notes

- Never commit or share secrets (service account keys, API keys, etc.). Treat `lib/seeding/serviceAccountKey.json` as sensitive material.

---

## 9) Feature status & roadmap

This section summarizes what’s implemented today, what’s partial, and what’s currently out of scope.

### Implemented

- Motorcycle directory (model-centric): Bikes tab directory + seeded dataset.
- Structured specs per model: bike detail shows model fields (brand/displacement/category/year, etc).
- Model-linked discussion/comments: comments are scoped to a specific bike.
- Upvote/downvote system: per-comment vote transaction prevents double-voting.
- Marketplace listings linked to models: listing creation denormalizes bike fields into the listing.
- Bid validation: enforced in Firestore transactions (monotonic bid rules, expiry, closed checks, owner checks).
- Seller controls: seller can close a listing; listing detail gates controls by owner UID.
- Account-based permissions: auth-gated routes + Firestore rules + UID checks in transactions.
- Error handling + UX states: validators, snackbars, loading/empty/error views are used widely.

### Partially implemented

- “Automatic closing logic”:
	- Implemented as **best-effort auto-close on read** (when someone opens the listing detail and it’s expired), plus manual close by seller.
	- Not implemented as a scheduled backend job (because no Cloud Functions scheduler in current build).

- “Fixed-price or bid-based listings”:
	- Current implementation is **bid-first**, with an optional **buyout price** (acts like a fixed-price shortcut).
	- There is no dedicated “fixed-price listing type” with no bidding.

- “Tags such as maintenance/reliability/modifications”:
	- The concept exists in the product space, but the current UI does not provide a first-class tagging workflow (it’s not a primary feature surface).

### Not implemented / changed scope

- Cloud Functions backend logic:
	- Some designs call for Cloud Functions for validation/auto-close/notifications.
	- Current build does **not** use Cloud Functions; it uses **client-side Firestore transactions** + rules as guard rails.
	- Rationale: Spark-plan constraints + correctness demonstrated via transactions; scheduled automation can be added later if needed.

- Profile “discussion participation history”:
	- Profile currently shows **my listings** and **my bids**.
	- It does not show “my comments / threads participated in” as a dedicated section.

- “Seller accepts bid” (explicit accept action):
	- Current flow is “close listing” (winner = current highest bid). There isn’t a separate accept-one-bid UI.

- Offline-friendly (true offline mode):
	- The app has offline-friendly **UI states** (loading/empty/error) and Firestore caching may help, but there is no explicit offline-first feature set (queueing, sync status indicators).

### If you want to close the biggest gaps quickly (highest ROI)

- Add “My comments” to Profile (query comments by authorId).
- Add explicit listing type: `fixedPrice` vs `auction` (or keep auction + buyout but update docs and UI labels).
- Add simple comment “tags” UX (chip picker + store tags on comment).
- Decide on Cloud Functions: either implement minimal Functions later, or double down on the transaction-based approach and document the security model clearly.

