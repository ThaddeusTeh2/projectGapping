# Project Gapping – Motorcycle Ownership Hub

A Flutter + Firebase mobile application designed to support the full motorcycle ownership lifecycle: research, ownership discussion, and resale — all within one focused ecosystem.

This project is built as a **non-trivial, production-style college project**, demonstrating real-world app structure, cloud backend usage, and error handling.

---

## Core Idea

**Problem:** Motorcycle information, ownership advice, and resale listings are fragmented across forums and marketplaces.

**Solution:** A model-centric mobile app where users:
1. Research a motorcycle
2. Learn from real owners
3. Buy or sell within the same system

Users exit with better information than they entered.

---

## Features

### 1. Discovery / Research
- Motorcycle directory (model-centric)
- Structured specs (brand, displacement, category, release year)
- Ownership notes and common issues
- SEA-local context (pricing, fuel usage, parts availability)
- Filtering and sorting

### 2. Ownership / Community
- Model-linked discussion threads
- Comment system scoped to motorcycle models
- Tags (maintenance, reliability, mods)
- Upvote / downvote system
- Empty states and permission handling

### 3. Marketplace (Buy / Sell)
- Listings linked to motorcycle models
- Fixed-price or bid-based listings
- Bid validation and automatic closing
- Seller controls (close listing, accept bid)

**Intentional scope limits**
- No payments
- No delivery
- No dispute resolution
- Text-only listings (no image upload)

### 4. User Profile
- View created listings
- View placed bids
- View discussion activity
- Auth-based permissions

---

## Tech Stack

**Frontend**
- Flutter (mobile-only)
- Material 3 UI
- MVVM architecture
- Riverpod (state management & DI)
- go_router (navigation)

**Backend**
- Firebase Authentication
- Cloud Firestore (NoSQL)
- Firebase Security Rules
- Firebase Cloud Functions (minimal backend logic)

---

## Architecture Overview

- **Model–View–ViewModel (MVVM)**
- Repository pattern for all data access
- Firestore is read-optimized and denormalized
- No direct Firestore access from UI widgets

---

## Firestore Collections

- `motorcycles` – bike models and specifications
- `comments` – model-scoped discussions
- `listings` – marketplace listings
- `bids` – bid records
- `users` – user profiles and history

---

## Error Handling & UX

This project explicitly demonstrates:
- Form validation (comments, prices, bids)
- Auth-required actions
- Permission-denied feedback
- Network failure handling
- Empty-state UI for all lists

---

## Project Scope

This is intentionally **not** a simple CRUD app.
It is comparable in complexity to a Notes or Word-style application, with:
- Multiple feature modules
- Cloud backend integration
- Real-world data constraints
- Clear user value

---

## Status

- Mobile platform only
- Educational project
- Designed for demonstration and assessment

---

## Future Improvements (Out of Scope)
- Image uploads
- Reputation system
- Payments
- Admin moderation
- Analytics

---

**Project Gapping – Motorcycle Ownership Hub**  
Flutter + Firebase | College Project