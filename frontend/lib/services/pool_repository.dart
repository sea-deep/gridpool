import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:frontend/models/pool_model.dart';
import 'package:frontend/models/pool_member.dart';
import 'package:frontend/models/join_request.dart';
import 'package:frontend/models/ledger_entry.dart';
import 'package:frontend/models/expense_model.dart';
import 'package:frontend/models/payment_request.dart';

final poolRepositoryProvider = Provider<PoolRepository>((ref) {
  return PoolRepository(FirebaseFirestore.instance);
});

class PoolRepository {
  // ignore: unused_field
  final FirebaseFirestore _firestore;

  String get _baseUrl {
    return dotenv.env['API_BASE_URL'] ?? 'https://gridpool.up.railway.app/api';
  }

  PoolRepository(this._firestore);

  // NOTE: Known DI violation — uses FirebaseAuth.instance directly instead of
  // an injected field. Changing the constructor would break existing providers.
  Future<Map<String, String>> _getHeaders() async {
    final user = firebase_auth.FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Not authenticated');
    final token = await user.getIdToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ─── Pool CRUD ──────────────────────────────────────────────────────

  Future<List<Pool>> fetchPoolsForUser(String userId) async {
    final targetUrl = Uri.parse('$_baseUrl/pools');
    try {
      final headers = await _getHeaders();
      final response = await http.get(targetUrl, headers: headers);
      if (response.statusCode != 200) {
        throw Exception('Failed to fetch pools: ${response.body}');
      }
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Pool.fromJson(json['id'] ?? json['_id'] ?? '', json)).toList();
    } catch (e) {
      debugPrint('fetchPoolsForUser failed: $e');
      rethrow;
    }
  }

  Stream<List<Pool>> watchPoolsForUser(String userId) async* {
    try {
      yield await fetchPoolsForUser(userId);
    } catch (e) {
      yield [];
    }
    yield* Stream.periodic(const Duration(seconds: 4)).asyncMap((_) async {
      try {
        return await fetchPoolsForUser(userId);
      } catch (e) {
        return <Pool>[];
      }
    });
  }

  Future<Pool> createPool({
    required String name,
    required String description,
    required String ownerId,
    required String ownerName,
    required String ownerEmail,
    required String ownerAvatarUrl,
    String currency = 'INR',
    String? upiId,
    String frequency = 'once',
    int? customInterval,
    double expectedContribution = 0.0,
  }) async {
    final targetUrl = Uri.parse('$_baseUrl/pools/create');
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        targetUrl,
        headers: headers,
        body: jsonEncode({
          'name': name,
          'description': description,
          'ownerName': ownerName,
          'ownerEmail': ownerEmail,
          'ownerAvatarUrl': ownerAvatarUrl,
          'currency': currency,
          'upiId': upiId,
          'frequency': frequency,
          'customInterval': customInterval,
          'expectedContribution': expectedContribution,
        }),
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to create pool: ${response.body}');
      }
      final data = jsonDecode(response.body);
      return Pool.fromJson(data['id'] ?? data['_id'] ?? '', data);
    } catch (e) {
      debugPrint('createPool failed: $e');
      rethrow;
    }
  }


  Future<void> updatePool({
    required String poolId,
    required String name,
    required String description,
    String? upiId,
    required String frequency,
    int? customInterval,
    required double expectedContribution,
  }) async {
    final targetUrl = Uri.parse('$_baseUrl/pools/$poolId');
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        targetUrl,
        headers: headers,
        body: jsonEncode({
          'name': name,
          'description': description,
          'upiId': upiId,
          'frequency': frequency,
          'customInterval': customInterval,
          'expectedContribution': expectedContribution,
        }),
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to update pool: ${response.body}');
      }
    } catch (e) {
      debugPrint('updatePool failed: $e');
      rethrow;
    }
  }

  Future<void> deletePool(String poolId) async {
    final targetUrl = Uri.parse('$_baseUrl/pools/$poolId');
    try {
      final headers = await _getHeaders();
      final response = await http.delete(targetUrl, headers: headers);
      if (response.statusCode != 200) {
        throw Exception('Failed to delete pool: ${response.body}');
      }
    } catch (e) {
      debugPrint('deletePool failed: $e');
      rethrow;
    }
  }

  // ─── Join Requests ──────────────────────────────────────────────────


  Future<void> submitJoinRequest({
    required String inviteCode,
    required String userId,
    required String userName,
    required String userEmail,
    required String userAvatarUrl,
  }) async {
    final targetUrl = Uri.parse('$_baseUrl/pools/join');
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        targetUrl,
        headers: headers,
        body: jsonEncode({
          'inviteCode': inviteCode,
          'userName': userName,
          'userEmail': userEmail,
          'userAvatarUrl': userAvatarUrl,
        }),
      );
      if (response.statusCode != 200) {
        String errorMsg = 'Unknown error';
        try {
          errorMsg = jsonDecode(response.body)['error'] ?? response.body;
        } catch (_) {
          errorMsg = response.body;
        }
        throw Exception('Join failed: $errorMsg');
      }
    } catch (e) {
      debugPrint('submitJoinRequest failed: $e');
      rethrow;
    }
  }

  Future<List<JoinRequest>> fetchJoinRequests(String poolId) async {
    final targetUrl = Uri.parse('$_baseUrl/pools/$poolId/join-requests');
    try {
      final headers = await _getHeaders();
      final response = await http.get(targetUrl, headers: headers);
      if (response.statusCode != 200) {
        throw Exception('Failed to fetch join requests: ${response.body}');
      }
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => JoinRequest.fromJson(json['id'] ?? json['_id'] ?? '', json)).toList();
    } catch (e) {
      debugPrint('fetchJoinRequests failed: $e');
      rethrow;
    }
  }

  Stream<List<JoinRequest>> watchJoinRequests(String poolId) async* {
    try {
      yield await fetchJoinRequests(poolId);
    } catch (e) {
      yield [];
    }
    yield* Stream.periodic(const Duration(seconds: 4)).asyncMap((_) async {
      try {
        return await fetchJoinRequests(poolId);
      } catch (e) {
        return <JoinRequest>[];
      }
    });
  }

  Future<void> approveJoinRequest({
    required String poolId,
    required JoinRequest request,
    required String approverId,
  }) async {
    final targetUrl = Uri.parse('$_baseUrl/pools/$poolId/join-requests/approve');
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        targetUrl,
        headers: headers,
        body: jsonEncode({'userId': request.userId}),
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to approve join request: ${response.body}');
      }
    } catch (e) {
      debugPrint('approveJoinRequest failed: $e');
      rethrow;
    }
  }

  Future<void> rejectJoinRequest({
    required String poolId,
    required JoinRequest request,
    required String approverId,
  }) async {
    final targetUrl = Uri.parse('$_baseUrl/pools/$poolId/join-requests/reject');
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        targetUrl,
        headers: headers,
        body: jsonEncode({'userId': request.userId}),
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to reject join request: ${response.body}');
      }
    } catch (e) {
      debugPrint('rejectJoinRequest failed: $e');
      rethrow;
    }
  }


  // --- Payment Requests ---

  Future<void> submitPaymentRequest({
    required String poolId,
    required double amount,
    required String screenshotUrl,
  }) async {
    final targetUrl = Uri.parse('$_baseUrl/pools/$poolId/payment-requests');
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        targetUrl,
        headers: headers,
        body: jsonEncode({
          'amount': amount,
          'screenshotUrl': screenshotUrl,
        }),
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to submit payment request: ${response.body}');
      }
    } catch (e) {
      debugPrint('submitPaymentRequest failed: $e');
      rethrow;
    }
  }

  Future<List<PaymentRequest>> fetchPaymentRequests(String poolId) async {
    final targetUrl = Uri.parse('$_baseUrl/pools/$poolId/payment-requests');
    try {
      final headers = await _getHeaders();
      final response = await http.get(targetUrl, headers: headers);
      if (response.statusCode != 200) {
        throw Exception('Failed to fetch payment requests: ${response.body}');
      }
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => PaymentRequest.fromJson(json['id'] ?? json['_id'] ?? '', json)).toList();
    } catch (e) {
      debugPrint('fetchPaymentRequests failed: $e');
      rethrow;
    }
  }

  Stream<List<PaymentRequest>> watchPaymentRequests(String poolId) async* {
    try {
      yield await fetchPaymentRequests(poolId);
    } catch (e) {
      yield [];
    }
    yield* Stream.periodic(const Duration(seconds: 4)).asyncMap((_) async {
      try {
        return await fetchPaymentRequests(poolId);
      } catch (e) {
        return <PaymentRequest>[];
      }
    });
  }

  Future<void> approvePaymentRequest(String poolId, String requestId) async {
    final targetUrl = Uri.parse('$_baseUrl/pools/$poolId/payment-requests/$requestId/approve');
    try {
      final headers = await _getHeaders();
      final response = await http.post(targetUrl, headers: headers);
      if (response.statusCode != 200) {
        throw Exception('Failed to approve payment request: ${response.body}');
      }
    } catch (e) {
      debugPrint('approvePaymentRequest failed: $e');
      rethrow;
    }
  }

  Future<void> rejectPaymentRequest(String poolId, String requestId) async {
    final targetUrl = Uri.parse('$_baseUrl/pools/$poolId/payment-requests/$requestId/reject');
    try {
      final headers = await _getHeaders();
      final response = await http.post(targetUrl, headers: headers);
      if (response.statusCode != 200) {
        throw Exception('Failed to reject payment request: ${response.body}');
      }
    } catch (e) {
      debugPrint('rejectPaymentRequest failed: $e');
      rethrow;
    }
  }

  // ─── Members ────────────────────────────────────────────────────────

  Future<List<PoolMember>> fetchMembers(String poolId) async {
    final targetUrl = Uri.parse('$_baseUrl/pools/$poolId/members');
    try {
      final headers = await _getHeaders();
      final response = await http.get(targetUrl, headers: headers);
      if (response.statusCode != 200) {
        throw Exception('Failed to fetch members: ${response.body}');
      }
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => PoolMember.fromJson(json['userId'] ?? json['_id'] ?? '', json)).toList();
    } catch (e) {
      debugPrint('fetchMembers failed: $e');
      rethrow;
    }
  }

  Stream<List<PoolMember>> watchMembers(String poolId) async* {
    try {
      yield await fetchMembers(poolId);
    } catch (e) {
      yield [];
    }
    yield* Stream.periodic(const Duration(seconds: 4)).asyncMap((_) async {
      try {
        return await fetchMembers(poolId);
      } catch (e) {
        return <PoolMember>[];
      }
    });
  }

  Future<PoolRole?> fetchMemberRole(String poolId, String userId) async {
    try {
      final members = await fetchMembers(poolId);
      final memberMatch = members.where((m) => m.id == userId);
      if (memberMatch.isEmpty) return null;
      return memberMatch.first.role;
    } catch (_) {
      return null;
    }
  }

  Stream<PoolRole?> watchMemberRole(String poolId, String userId) async* {
    try {
      yield await fetchMemberRole(poolId, userId);
    } catch (e) {
      yield null;
    }
    yield* Stream.periodic(const Duration(seconds: 4)).asyncMap((_) async {
      try {
        return await fetchMemberRole(poolId, userId);
      } catch (e) {
        return null;
      }
    });
  }

  Future<PoolMember> addCustomMember({
    required String poolId,
    required String name,
  }) async {
    final targetUrl = Uri.parse('$_baseUrl/pools/$poolId/members/custom');
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        targetUrl,
        headers: headers,
        body: jsonEncode({'name': name}),
      );
      if (response.statusCode != 200) {
        String errorMsg = 'Unknown error';
        try {
          errorMsg = jsonDecode(response.body)['error'] ?? response.body;
        } catch (_) {
          errorMsg = response.body;
        }
        throw Exception('Failed to add custom member: $errorMsg');
      }
      final data = jsonDecode(response.body);
      return PoolMember.fromJson(data['userId'] ?? data['_id'] ?? '', data);
    } catch (e) {
      debugPrint('addCustomMember failed: $e');
      rethrow;
    }
  }

  // ─── Ledger, Contributions & Expenses ───────────────────────────────

  Future<List<LedgerEntry>> fetchLedger(String poolId) async {
    final targetUrl = Uri.parse('$_baseUrl/pools/$poolId/ledger');
    try {
      final headers = await _getHeaders();
      final response = await http.get(targetUrl, headers: headers);
      if (response.statusCode != 200) {
        throw Exception('Failed to fetch ledger: ${response.body}');
      }
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => LedgerEntry.fromJson(json['id'] ?? json['_id'] ?? '', json)).toList();
    } catch (e) {
      debugPrint('fetchLedger failed: $e');
      rethrow;
    }
  }

  Stream<List<LedgerEntry>> watchLedger(String poolId) async* {
    try {
      yield await fetchLedger(poolId);
    } catch (e) {
      yield [];
    }
    yield* Stream.periodic(const Duration(seconds: 4)).asyncMap((_) async {
      try {
        return await fetchLedger(poolId);
      } catch (e) {
        return <LedgerEntry>[];
      }
    });
  }

  Future<void> addExpense({
    required String poolId,
    required Expense expense,
  }) async {
    final targetUrl = Uri.parse('$_baseUrl/ledger/expense');
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        targetUrl,
        headers: headers,
        body: jsonEncode({
          'poolId': poolId,
          'title': expense.title,
          'amount': expense.amount,
          'category': expense.category,
          'note': expense.note,
          'receiptUrl': expense.receiptUrl,
        }),
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to add expense: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to add expense: $e');
    }
  }

  Future<void> logCollection({
    required String poolId,
    required Map<String, dynamic> data,
  }) async {
    final targetUrl = Uri.parse('$_baseUrl/pools/$poolId/log-collection');
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        targetUrl,
        headers: headers,
        body: jsonEncode(data),
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to log collection: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to log collection: $e');
    }
  }

  Future<void> updateMemberRole({
    required String poolId,
    required String userId,
    required String role,
  }) async {
    final targetUrl = Uri.parse('$_baseUrl/pools/$poolId/members/$userId/role');
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        targetUrl,
        headers: headers,
        body: jsonEncode({'role': role}),
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to update member role: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to update member role: $e');
    }
  }

  Future<void> payDue({
    required String poolId,
    required double amount,
  }) async {
    final targetUrl = Uri.parse('$_baseUrl/ledger/pay-due');
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        targetUrl,
        headers: headers,
        body: jsonEncode({
          'poolId': poolId,
          'amount': amount,
        }),
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to record due payment: ${response.body}');
      }
    } catch (e) {
      debugPrint('payDue failed: $e');
      rethrow;
    }
  }

  // ─── Activity Feed (Cross-Pool) ─────────────────────────────────────

  Future<List<Map<String, dynamic>>> fetchActivity() async {
    final targetUrl = Uri.parse('$_baseUrl/activity');
    try {
      final headers = await _getHeaders();
      final response = await http.get(targetUrl, headers: headers);
      if (response.statusCode != 200) {
        throw Exception('Failed to fetch activity: ${response.body}');
      }
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('fetchActivity failed: $e');
      rethrow;
    }
  }

  Stream<List<Map<String, dynamic>>> watchActivity() async* {
    try {
      yield await fetchActivity();
    } catch (e) {
      yield [];
    }
    yield* Stream.periodic(const Duration(seconds: 6)).asyncMap((_) async {
      try {
        return await fetchActivity();
      } catch (e) {
        return <Map<String, dynamic>>[];
      }
    });
  }
}
