
# Project Gapping — `lib/` Index

Last updated: 2026-02-05

Scope: only `lib/`.

Goal: quick map of responsibilities + how files relate (who calls whom).

---

## Entry

- lib/main.dart — Boots Flutter, initializes Firebase, runs `ProviderScope(child: App())`.
- lib/firebase_options.dart — FlutterFire-generated Firebase options per platform.

---

## App shell

- lib/app/app.dart — Root `ShadApp.router` + global `ScaffoldMessenger` for snackbars.
- lib/app/router.dart — go_router config (routes + auth redirect + tab shell).
- lib/app/home_shell.dart — Bottom nav host for Bikes/Shop/Profile tabs.
- lib/app/theme.dart — OLED dark theme + shadcn_ui theme + mono typography.

---

## Core UI + helpers

- lib/core/ui/app_scaffold.dart — Standard screen scaffold wrapper.
- lib/core/ui/app_snackbar.dart — Snackbar API + global messenger key.
- lib/core/ui/loading_view.dart — Standard loading UI.
- lib/core/ui/empty_state_view.dart — Standard empty state.
- lib/core/ui/error_state_view.dart — Standard error + retry UI.

- lib/core/utils/time.dart — `nowMillis()` + listing duration presets.
- lib/core/validation/validators.dart — Form/business validators.

---

## DI

- lib/di/providers.dart — Riverpod providers: Firebase singletons, repos, router refresh, UID→displayName stream provider.

---

## Domain

- lib/domain/enums.dart — Canonical enums/mappings (category/bucket/brands) + parsing helpers.

- lib/domain/models/bike.dart — Bike model + Firestore (de)serialization.
- lib/domain/models/bike_comment.dart — Comment model + Firestore (de)serialization.
- lib/domain/models/shop_listing.dart — Listing model + Firestore (de)serialization; omits null fields on create.
- lib/domain/models/bid.dart — Bid history model + Firestore (de)serialization.
- lib/domain/models/app_user.dart — Minimal private user doc model.
- lib/domain/models/public_user.dart — Public identity model (`public_users/{uid}`).

---

## Data layer

Contracts (ViewModels depend on these):
- lib/data/repositories/auth_repository.dart
- lib/data/repositories/bike_repository.dart
- lib/data/repositories/comment_repository.dart
- lib/data/repositories/listing_repository.dart
- lib/data/repositories/bid_repository.dart
- lib/data/repositories/user_repository.dart

Firestore support:
- lib/data/firestore/firestore_paths.dart — Collection name constants.

Firestore implementations (Firebase SDK boundary):
- lib/data/firestore/firestore_auth_repository.dart
- lib/data/firestore/firestore_bike_repository.dart
- lib/data/firestore/firestore_comment_repository.dart
- lib/data/firestore/firestore_listing_repository.dart
- lib/data/firestore/firestore_bid_repository.dart
- lib/data/firestore/firestore_user_repository.dart

---

## Features

Auth:
- lib/features/auth/login_screen.dart
- lib/features/auth/register_screen.dart

Bikes:
- lib/features/bikes/bike_directory_view_model.dart
- lib/features/bikes/bike_directory_screen.dart
- lib/features/bikes/bike_detail_view_model.dart
- lib/features/bikes/bike_detail_screen.dart
- lib/features/bikes/add_comment_sheet.dart

Shop:
- lib/features/shop/shop_directory_view_model.dart
- lib/features/shop/shop_directory_screen.dart
- lib/features/shop/listing_detail_view_model.dart
- lib/features/shop/listing_detail_screen.dart
- lib/features/shop/create_listing_view_model.dart
- lib/features/shop/create_listing_screen.dart

Profile:
- lib/features/profile/profile_view_model.dart
- lib/features/profile/profile_screen.dart

---

## Seeding (dev tooling)

- lib/seeding/seed_pack.json — Seed dataset.
- lib/seeding/seeder.py — Python Firestore batch seeder.
- lib/seeding/serviceAccountKey.json — Local credential (treat as secret; should be gitignored).

---

## Historical-only paths (from git history)

- lib/core/utils/seed_pack.json — Old seed pack location; replaced by lib/seeding/seed_pack.json.

