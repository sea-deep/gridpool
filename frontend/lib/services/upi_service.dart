import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class UpiService {
  static const MethodChannel _channel = MethodChannel('com.gridpool/upi');

  static String getUpiUrl({
    required String upiId,
    required String payeeName,
    required double amount,
    String transactionNote = 'GridPool Payment',
  }) {
    final amountString = amount.toStringAsFixed(2);
    final encodedPayeeName = Uri.encodeComponent(payeeName);
    final encodedNote = Uri.encodeComponent(transactionNote);
    return 'upi://pay?pa=$upiId&pn=$encodedPayeeName&am=$amountString&cu=INR&tn=$encodedNote';
  }

  /// Launches a UPI payment intent robustly via Native Android MethodChannel
  /// Returns the raw response string from the UPI app (e.g. "txnId=...&Status=SUCCESS")
  static Future<String?> executeNativeUpiTransaction({
    required String upiId,
    required String payeeName,
    required double amount,
    String transactionNote = 'GridPool Payment',
  }) async {
    final uriString = getUpiUrl(
      upiId: upiId,
      payeeName: payeeName,
      amount: amount,
      transactionNote: transactionNote,
    );
    
    try {
      final String? response = await _channel.invokeMethod('initiateTransaction', {'url': uriString});
      return response;
    } catch (e) {
      // Return null if channel fails (e.g. not on Android)
      return null;
    }
  }

  /// Old fallback launcher for testing or non-Android platforms
  static Future<bool> launchUpiPayment({
    required String upiId,
    required String payeeName,
    required double amount,
    String transactionNote = 'GridPool Payment',
  }) async {
    final uriString = getUpiUrl(
      upiId: upiId,
      payeeName: payeeName,
      amount: amount,
      transactionNote: transactionNote,
    );
    final uri = Uri.parse(uriString);

    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      return false;
    }
  }
}
