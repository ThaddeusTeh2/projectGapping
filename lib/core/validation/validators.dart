// Validation helpers.
// Responsibilities:
// - Email/password validation
// - Comment title/body validation
// - Listing create validation (startingBid > 0, buyOutPrice >= startingBid, preset required)
// - Bid pre-validation (numeric, > currentBid or >= startingBid)

class Validators {
  Validators._();

  static const int passwordMinLength = 8;
  static const int commentTitleMaxLength = 60;
  static const int commentBodyMaxLength = 500;
  static const int displayNameMinLength = 3;
  static const int displayNameMaxLength = 24;
  static final RegExp _displayNameAllowed = RegExp(r'^[a-zA-Z0-9 _-]+$');

  static String? email(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Email is required';
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(v)) return 'Enter a valid email';
    return null;
  }

  static String? password(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Password is required';
    if (v.length < passwordMinLength) {
      return 'Password must be at least $passwordMinLength characters';
    }
    return null;
  }

  static String? confirmPassword({
    required String? password,
    required String? confirm,
  }) {
    final p = password ?? '';
    final c = confirm ?? '';
    if (c.isEmpty) return 'Confirm password is required';
    if (p != c) return 'Passwords do not match';
    return null;
  }

  static String? displayName(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Display name is required';
    if (v.length < displayNameMinLength) {
      return 'Display name must be at least $displayNameMinLength characters';
    }
    if (v.length > displayNameMaxLength) {
      return 'Display name must be at most $displayNameMaxLength characters';
    }
    if (!_displayNameAllowed.hasMatch(v)) {
      return 'Display name contains invalid characters';
    }
    return null;
  }

  static String? commentTitle(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Title is required';
    if (v.length > commentTitleMaxLength) return 'Title is too long';
    return null;
  }

  static String? commentBody(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Comment is required';
    if (v.length > commentBodyMaxLength) return 'Comment is too long';
    return null;
  }

  static String? positiveMoney(String? value, {String fieldName = 'Amount'}) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return '$fieldName is required';
    final parsed = double.tryParse(v);
    if (parsed == null) return '$fieldName must be a number';
    if (parsed <= 0) return '$fieldName must be greater than 0';
    return null;
  }

  static String? listingStartingBid(String? value) =>
      positiveMoney(value, fieldName: 'Starting bid');

  static String? listingBuyoutPrice({
    required String? buyoutValue,
    required double? startingBid,
  }) {
    final v = (buyoutValue ?? '').trim();
    if (v.isEmpty) return 'Buyout price is required';
    final parsed = double.tryParse(v);
    if (parsed == null) return 'Buyout price must be a number';
    if (parsed <= 0) return 'Buyout price must be greater than 0';
    final start = startingBid;
    if (start != null && parsed < start) {
      return 'Buyout price must be ≥ starting bid';
    }
    return null;
  }

  static String? bidAmount({
    required String? value,
    required double? currentBid,
    required double? startingBid,
  }) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Bid amount is required';
    final parsed = double.tryParse(v);
    if (parsed == null) return 'Bid amount must be a number';
    if (parsed <= 0) return 'Bid amount must be greater than 0';
    if (currentBid != null) {
      if (parsed <= currentBid) return 'Bid must be higher than current bid';
    } else {
      final start = startingBid ?? 0;
      if (parsed < start) return 'Bid must be at least starting bid';
    }
    return null;
  }
}
