# Project Gapping — SSOT (Single Source of Truth)

Purpose: One document that locks scope, architecture, data model, routes, and screen content/wireframes for fast implementation and consistent context across models.

---

_plan_

## 0) Snapshot
**Product:** Motorcycle Ownership Hub (Flutter + Firebase)

**Core lifecycle:** discovery → ownership/community → buy/sell → profile/history.

**Hard boundaries (do not build):**
- No payments
- No delivery
- No dispute resolution
- No chat
- No AI
- No image upload
- Mobile only (Android demo target)

**UX direction:** text-only listings (“terminal vibes”), but with chips/badges for clarity.

**Timeline:** 1 week.

## 1) Locked tech decisions
- Flutter (Material 3)
- State + DI: Riverpod
- Navigation: go_router
- UI kit: shadcn_ui
- Typography: JetBrains Mono (app-wide mono)
- Splash: flutter_native_splash
- Backend: Firebase Auth (email/password), Cloud Firestore
- Bidding enforcement (Spark plan): Firestore client-side transaction (repository boundary) + Firestore Security Rules as guard rails
- Voting: counters + per-user immutable vote docs (one vote per user)
- Data seeding: one-time JSON import

## 2) Non-negotiable grading requirements (must demonstrate)
- Form validation: price, bid, comment, auth
- Auth-required actions: post comment, create listing, place bid
- Network failure handling: clear error UI + retry
- Empty states: bikes list, comments list, listings list, profile lists
- Permission-denied feedback: seller-only listing controls

## 3) Domain taxonomy (canonical)
### bikeCategory
- Sport
- Naked
- Scooter
- Adventure
- Cruiser
- Offroad

### listingClass
- Reuse bikeCategory

### brand
Store both:
- brandKey (lowercase + underscores)
- brandLabel (display)

Canonical brandKey list:
- kawasaki
- honda
- yamaha
- suzuki
- bmw
- aprilia
- cfmoto
- ducati
- harley_davidson
- ktm
- triumph
- vespa

Canonical brandLabel list:
- Kawasaki
- Honda
- Yamaha
- Suzuki
- BMW
- Aprilia
- CFMOTO
- Ducati
- Harley Davidson
- KTM
- Triumph
- Vespa

### displacement buckets
Use `displacementBucket`:
- 0_150  (0–150cc)
- 151_250
- 251_400
- 401_650
- 651_plus

## 4) Screens + routes
### Public
- /login
- /register

### Protected (auth gated)
- /home (shell)
- /bikes
- /bike/:id
- /shop
- /listing/:id
- /profile
- /listing/create

## 5) Architecture rules
- MVVM + repository pattern
- UI widgets never call Firestore directly
- ViewModels expose state: loading/data/error + actions
- Repositories isolate Firebase SDK usage

Footnote (2026-01-21): For demo-scale data, list screens fetch a broader slice from Firestore and apply filtering/sorting on-device to avoid composite-index combinatorics. Tradeoff is higher reads and weaker scalability; if/when data grows, switch to fixed query presets (limited query shapes) and/or add a search layer (Algolia/Meilisearch) and keep Firestore as the source of truth.

Suggested folder structure (implementation target):
- lib/
  - app/ (router, theme, app shell)
  - core/ (ui primitives, validators, utils)
  - features/
    - auth/
    - bikes/
    - shop/
    - profile/
  - data/ (repositories, firestore adapters)
  - domain/ (models)

## 6) Firestore data model (read-optimized)

### 6.1 motorcycles/{modelId}
Required fields:
- brandKey: string
- brandLabel: string
- category: string
- displacementBucket: string
- displacementCc: int
- title: string
- titleLower: string
- desc: string
- releaseYear: int
- dateCreatedMillis: int
SEA notes (strings):
- seaPricingNote
- seaFuelNote
- seaPartsNote

### 6.2 comments/{commentId}
- bikeId: string
- userId: string
- commentTitle: string
- comment: string
- tags: array<string> (optional)
- upvoteCount: int
- downvoteCount: int
- dateCreatedMillis: int

#### 6.2.1 comments/{commentId}/votes/{userId}
Immutable per-user vote doc used to enforce “one vote per user”.
- userId: string (== document id)
- direction: string ("up" | "down")
- dateCreatedMillis: int

### 6.3 listings/{listingId} (bid-only)
- bikeId: string
- sellerId: string
Denormalized for fast filtering:
- brandKey: string
- brandLabel: string
- category: string
- displacementBucket: string
- bikeTitle: string
- bikeReleaseYear: int? (optional)
Bid state:
- hasBid: bool
- startingBid: double
- currentBid: double? (nullable before first bid)
- currentBidderId: string? (nullable before first bid)
Pricing:
- buyOutPrice: double
Timing:
- dateCreatedMillis: int
- closingTimeMillis: int
Closure:
- isClosed: bool
- closedAtMillis: int?
- closingBid: double?
- winnerUserId: string?
Text:
- listingComments: string

### 6.4 bids/{bidId}
- listingId: string
- bidderId: string
- amount: double
- dateCreatedMillis: int

### 6.5 users/{userId} (minimal)
- userDateCreatedMillis: int

### 6.6 public_users/{userId}
Public, read-only-to-others identity surface for UID → displayName resolution.
- displayName: string
- updatedAtMillis: int

## 7) Queries + indexes (plan in advance)
### Motorcycles (directory)
Filters: brandKey, category, displacementBucket
Sort options:
- titleLower asc
- dateCreatedMillis desc
- releaseYear desc

Composite indexes:
- (brandKey, category, displacementBucket, titleLower asc)
- (brandKey, category, displacementBucket, dateCreatedMillis desc)
- (brandKey, category, displacementBucket, releaseYear desc)

### Listings (shop)
Filters: isClosed=false (default)
Sort: dateCreatedMillis desc

Note (current implementation): additional filters (brand/category/cc bucket/search query) are applied locally on-device after fetching a broader slice. This avoids composite-index combinatorics at demo scale.

Composite indexes:
- (isClosed, dateCreatedMillis desc)
- (isClosed, closingTimeMillis asc) for scheduled closing scans

## 8) Spark-plan correctness (Firestore-only)

### Transactional bidding (client)
Implementation lives behind the repository boundary and uses a Firestore transaction.

Transaction requirements (enforced in-app):
- listing exists
- listing isClosed == false
- nowMillis < closingTimeMillis
- if currentBid exists: amount > currentBid
- else: amount >= startingBid

Writes:
- create bids/{bidId}
- update listings/{listingId}: currentBid = amount, hasBid = true, currentBidderId = request.auth.uid

Additional shop flows (Spark-plan, client transactions):
- Buyout: closes listing instantly, sets `winnerUserId` + `closingBid`
- Expiry auto-close (best-effort): on read/refresh, attempt to close expired listings

### Firestore Security Rules (guard rails)
On Spark plan, rules can constrain *who* can write *which fields*, but cannot fully enforce auction correctness against a modified client.

Current project state (as of late Jan 2026):
- A dev-permissive ruleset was used temporarily to unblock testing and confirm transaction behavior.
- Follow-up work: tighten rules to allow only constrained bidder listing updates and controlled bid doc creation.

### Future (Blaze-only): Cloud Functions
If/when the project moves to Blaze, we can restore server-side bidding enforcement using Cloud Functions.

---

## ADDENDUM (2026-01-23) — Day 6 Spark-plan pivot (no Cloud Functions)

### Why this pivot exists
Firebase Cloud Functions deployment requires enabling Cloud Build / Artifact Registry APIs, which requires the project to be on the Blaze (pay-as-you-go) plan. The course/demo goal is to stay on the free Spark plan (“payless”), so we cannot rely on Functions for server-side bidding enforcement.

### What we are pivoting to (Option B)
We will implement bidding using a Firestore client-side transaction from the Flutter app (still behind the Repository boundary).

High-level behavior (transactional):
- Read listing
- Validate: listing open, not expired, bid is high enough
- Write: create a bid document + update listing fields (`currentBid`, `hasBid`)

This keeps the UX and MVVM architecture intact (Shop UI/ViewModels stay the same shape), but replaces the “callable function” backend with a “transaction in repository” implementation.

### Correctness and security tradeoffs (important)
This pivot is good for demo-scale correctness under normal app usage, but it is not equivalent to server-side enforcement:
- A modified client can always bypass client-side checks.
- Firestore security rules can restrict writes, but they cannot fully guarantee auction correctness (e.g., comparing against the current value and enforcing strictly-increasing bids) without server logic.

Therefore:
- We can still demonstrate: auth-gated bidding, transaction-based conflict handling, clear error messages, and a functional “bid increments current price” flow.
- We cannot honestly claim: “invalid bids are rejected even if client is modified” without Cloud Functions (or another trusted server).

### Files affected by this pivot (implemented)
Firebase (repo root):
- `firestore.rules`: Firestore Security Rules used for demo/dev (tightening TBD)
- `firestore.indexes.json`: repeatable composite-index setup for the listings query shape

Flutter client:
- `pubspec.yaml`: removed `cloud_functions` dependency
- `lib/data/firestore/firestore_bid_repository.dart`: `placeBid()` implemented with `FirebaseFirestore.runTransaction`
- `lib/di/providers.dart`: repository wiring uses Firestore directly (no Functions)
- `lib/data/firestore/firestore_listing_repository.dart`: stabilized listings query shape to match planned indexes
- `lib/features/shop/listing_detail_view_model.dart` + `lib/features/shop/listing_detail_screen.dart`: improved error surfacing for Firestore failures

Existing callers expected to remain stable:
- `lib/features/shop/listing_detail_view_model.dart` (should not need API changes; continues to call `BidRepository.placeBid()`)
- `lib/features/shop/listing_detail_screen.dart` (no direct Firebase usage; continues to show success only on confirmed success)

### “Close expired listings” under Spark
Without scheduled Functions, we have two options:
- Demo-only: close manually via seller button.
- Opportunistic closure: when a listing is opened/read, if it is past `closingTimeMillis`, the seller can close it (or we can show “expired” and require seller to close).

We will keep this scope minimal and aligned to the grading/demo script.

---

## ADDENDUM (2026-02-04) — Post–Day 6 scope that landed in code

This section exists because the repo grew beyond the original Day 7 checklist.

### Identity (display names)
- Added `public_users/{uid}` as a public-readable identity surface.
- UI resolves UID → displayName live (streamed snapshots) and falls back to a shortened UID.
- Profile supports editing displayName; register optionally sets it.

### Comments voting (one vote per user)
- Voting is now: immutable vote doc + counter increment in a transaction.
- Rules treat vote docs as the "receipt" to prevent repeat votes.

### Shop behavior
- Place bid: transaction writes `bids/*` (bid history) and updates listing bid state.
- Buyout: transaction closes listing instantly and persists winner.
- Best-effort expiry auto-close and hiding expired listings from the "open" list.

### Directory UX & performance
- Bikes + Shop directories include local search (cached lists; typing doesn’t refetch).
- Filters/Sort controls are compact (accordions) with a single "Clear" to reset query + filters.
- Create Listing bike selection uses a searchable picker sheet (combobox-style).

### UI / styling
- OLED-friendly shadcn theme polish (high-contrast outlines, consistent mono typography).
- Standardized separators using `ShadSeparator.horizontal` for consistent spacing.
- Improved global snackbar reliability via root messenger wiring.

### App assets
- JetBrains Mono font is included as an asset and used app-wide.
- Splash is managed via `flutter_native_splash`.

## 9) Validation + UX behaviors (must show)
- Login/Register: email format, password min length
- Comment: title/body non-empty; length caps
- Listing create:
  - startingBid > 0
  - buyOutPrice >= startingBid
  - closing preset must be selected
- Place bid:
  - numeric
  - higher than currentBid (or >= startingBid if first)
  - show Firestore error messages from the transaction/rules (permission denied, expired, low bid, closed)

Network and permission:
- Show error banner + retry on list failures
- On permission-denied: show clear message (“You do not own this listing”)

## 10) Seed dataset requirements
- 40 motorcycles spanning many brands + all categories + all displacement buckets
- 10 listings across brands/categories/buckets; mixed closing times
- Optional: seed a handful of comments for 5 bikes

## 11) 7-day execution plan (minimum)
### Day 1
- Add deps, theme, router, auth guard, UI primitives

### Day 2
- Firebase init + models + repositories + validators

### Day 3
- Bike directory (filters/sorts) + bike detail + comments + vote counters

### Day 4
- Profile (my listings, my bids) + error/empty state polish

### Day 5
- Shop directory + listing detail + create listing + bid UI (calls repository; implementation depends on Day 6 track)

### Day 6
- Security rules + bidding enforcement (preferred: Cloud Functions; Spark-plan pivot: client transaction) — see Day 6 pivot addendum

### Day 7
- UX checklist pass + demo script + remove dead code

---

_wireframes_

## UX Flow Map (high level)

[App Launch]
  |
  |-- if NOT authenticated --> [Login] --> [Register] (optional) --> [Home]
  |
  `-- if authenticated ------> [Home]

[Home] is a shell with tabs:
  - Bikes (Directory)
  - Shop (Listings)
  - Profile

Bikes flow:
  [Bike Directory] -> [Bike Detail] -> (Add Comment) -> (Vote)

Shop flow:
  [Shop Directory] -> [Listing Detail] -> (Place Bid)
                             |
                             `-> (Seller) Close Listing

Create listing flow:
  [Profile] or [Shop] -> [Create Listing] -> [Listing Detail]

## Screen Wireframes (ASCII)

### 1) Login (/login)
+--------------------------------------------------+
| Project Gapping                                  |
|--------------------------------------------------|
| LOGIN                                            |
|                                                  |
| Email                                            |
| [____________________________]                   |
| Password                                         |
| [____________________________]                   |
|                                                  |
| (Error text area: invalid email / wrong password)|
|                                                  |
| [ Sign In ]                                      |
|                                                  |
| No account?  [ Register ]                        |
+--------------------------------------------------+

States:
- Loading: disable button, show spinner
- Error: inline message + snackbar

### 2) Register (/register)
+--------------------------------------------------+
| Project Gapping                                  |
|--------------------------------------------------|
| REGISTER                                         |
|                                                  |
| Email                                            |
| [____________________________]                   |
| Password (min length)                            |
| [____________________________]                   |
| Confirm Password                                 |
| [____________________________]                   |
|                                                  |
| [ Create Account ]                               |
|                                                  |
| Already have an account? [ Login ]               |
+--------------------------------------------------+

### 3) Home Shell (/home)
+--------------------------------------------------+
| Project Gapping                                  |
|--------------------------------------------------|
| [Bikes] [Shop] [Profile]                         |
|--------------------------------------------------|
| <Active tab content>                             |
+--------------------------------------------------+

### 4) Bike Directory (/bikes)
+--------------------------------------------------+
| Bikes                                            |
|--------------------------------------------------|
| Filters:                                         |
| Brand  [All v]  Category [All v]                 |
| CC     [All v]  Sort [A-Z v]                     |
|--------------------------------------------------|
| Results (list)                                   |
| +----------------------------------------------+ |
| | Ninja 400                         [Sport]   | |
| | 251–400cc | Kawasaki                         | |
| | Year: 2018                                 >| |
| +----------------------------------------------+ |
| +----------------------------------------------+ |
| | Vespa Primavera                  [Scooter]  | |
| | 0–150cc | Vespa                              | |
| | Year: 2021                                 >| |
| +----------------------------------------------+ |
|                                                  |
| Empty state: “No bikes match filters.”           |
| Error state: “Failed to load. [Retry]”           |
+--------------------------------------------------+

Sort options:
- A–Z (titleLower asc)
- Date added (dateCreatedMillis desc)
- Release year (releaseYear desc)

### 5) Bike Detail (/bike/:id)
+--------------------------------------------------+
| < Back                 Bike Detail               |
|--------------------------------------------------|
| Ninja 400                                      | |
| [Kawasaki] [Sport] [251–400cc]                 | |
|--------------------------------------------------|
| Specs                                            |
| - Displacement: 399cc                            |
| - Release year: 2018                             |
|                                                  |
| SEA Notes                                        |
| - Pricing: ...                                   |
| - Fuel: ...                                      |
| - Parts: ...                                     |
|--------------------------------------------------|
| Comments                                         |
| [ Add Comment ] (auth required)                  |
|                                                  |
| +----------------------------------------------+ |
| | “Common issues?”                              | |
| | ...comment text...                            | |
| | [^ Up 12] [v Down 1]                          | |
| +----------------------------------------------+ |
|                                                  |
| Empty: “No comments yet.”                        |
+--------------------------------------------------+

Add comment modal/screen:
+-----------------------------------------------+
| Add Comment                                   |
| Title [____________________]                  |
| Body  [____________________]                  |
|       [____________________]                  |
| Tags (optional) [maintenance] [mods] ...      |
|                                               |
| [ Post ]                                      |
+-----------------------------------------------+

### 6) Shop Directory (/shop)
+--------------------------------------------------+
| Shop                                             |
|--------------------------------------------------|
| Filters:                                         |
| Brand  [All v]  Category [All v]                 |
| CC     [All v]                                   |
|--------------------------------------------------|
| Listings                                         |
| +----------------------------------------------+ |
| | Ninja 400 Listing                             | |
| | [OPEN] [Sport] [251–400cc] [HasBid]           | |
| | Current: MYR 7,200  | Buyout: MYR 9,000       | |
| | Closes in: 5h                                 >| |
| +----------------------------------------------+ |
|                                                  |
| [ + Create Listing ]                             |
|                                                  |
| Empty: “No listings yet.”                        |
+--------------------------------------------------+

### 7) Create Listing (/listing/create)
+--------------------------------------------------+
| < Back                 Create Listing            |
|--------------------------------------------------|
| Select Bike Model                                |
| [ Search... ______________________ ]             |
| [Pick from bikes list]                           |
|--------------------------------------------------|
| Starting Bid (MYR)                               |
| [__________]                                     |
| Buyout Price (MYR)                               |
| [__________]                                     |
| Closing In                                       |
| ( ) 1h   ( ) 6h   ( ) 24h   ( ) 3d               |
| Listing Notes                                    |
| [______________________________]                 |
|                                                  |
| [ Publish Listing ]                              |
+--------------------------------------------------+

Validation errors (inline):
- startingBid must be > 0
- buyOutPrice must be >= startingBid
- closing preset required

### 8) Listing Detail (/listing/:id)
+--------------------------------------------------+
| < Back                 Listing Detail            |
|--------------------------------------------------|
| Ninja 400                                        |
| [Kawasaki] [Sport] [251–400cc]                   |
| Status: OPEN                                     |
|--------------------------------------------------|
| Starting: MYR 6,000                              |
| Current:  MYR 7,200 (hasBid=true)                |
| Buyout:   MYR 9,000                              |
| Closes:   2026-01-19 23:30                       |
|--------------------------------------------------|
| Seller Notes                                     |
| ...listingComments...                            |
|--------------------------------------------------|
| Place Bid (auth required)                        |
| Amount (MYR) [__________]                        |
| [ Place Bid ]                                    |
| (Error area: server rejects invalid bid)         |
|--------------------------------------------------|
| Seller Controls (only if sellerId == me)         |
| [ Close Listing Early ]                          |
+--------------------------------------------------+

Server-side errors to surface:
- “Listing already closed.”
- “Bidding has ended.”
- “Bid must be higher than current bid.”

### 9) Profile (/profile)
+--------------------------------------------------+
| Profile                                          |
|--------------------------------------------------|
| User: <email>                                    |
| [ Sign Out ]                                     |
|--------------------------------------------------|
| My Listings                                      |
| +----------------------------------------------+ |
| | Ninja 400 Listing  [OPEN]                    >| |
| +----------------------------------------------+ |
| Empty: “You have no listings.”                   |
|--------------------------------------------------|
| My Bids                                          |
| +----------------------------------------------+ |
| | Bid MYR 7,200 on Ninja 400                   >| |
| +----------------------------------------------+ |
| Empty: “You have no bids.”                       |
+--------------------------------------------------+
