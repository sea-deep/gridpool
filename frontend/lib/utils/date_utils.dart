import 'package:cloud_firestore/cloud_firestore.dart';

/// Safely converts various date representations to DateTime.
/// Handles Firestore Timestamps, ISO 8601 strings, and raw DateTime objects.
DateTime? asDateTime(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  if (v is Timestamp) return v.toDate();
  if (v is String) {
    return DateTime.tryParse(v);
  }
  return null;
}
