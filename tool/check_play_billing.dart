// Read-only Google Play diagnostics using the real SDK and production IDs.
// Run only after reviewing the target device/package installation:
//   flutter run -d <device> -t tool/check_play_billing.dart
// This is a separate entrypoint, not an integration test. It does not start
// PlayPurchases: its normal refresh acknowledges unfinished purchases.
// No checkout, acknowledgement, consumption, restoration event, or app data
// mutation is requested here. Logs omit receipts, tokens, orders, and accounts.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:focus_friend_app/purchases.dart' show Products;
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

const _queryTimeout = Duration(seconds: 20);
const _json = JsonEncoder.withIndent('  ');

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const _BillingDiagnosticApp());
}

Future<Map<String, Object?>> _queryProducts(InAppPurchase store) async {
  try {
    final response = await store
        .queryProductDetails(Products.all)
        .timeout(_queryTimeout);
    final products = [...response.productDetails]
      ..sort((a, b) => a.id.compareTo(b.id));
    return {
      'status': response.error == null ? 'ok' : 'store_error',
      'errorCode': response.error?.code,
      'products': [
        for (final product in products)
          {
            'id': product.id,
            'price': product.price,
            'currencyCode': product.currencyCode,
          },
      ],
      'notFoundIDs': [...response.notFoundIDs]..sort(),
    };
  } on TimeoutException {
    return {'status': 'timeout'};
  } catch (_) {
    // Exception text can contain native transaction details; never print it.
    return {'status': 'query_exception'};
  }
}

Future<Map<String, Object?>> _queryOwnership(InAppPurchase store) async {
  try {
    final response = await store
        .getPlatformAddition<InAppPurchaseAndroidPlatformAddition>()
        .queryPastPurchases()
        .timeout(_queryTimeout);
    final statuses = <String, int>{};
    for (final purchase in response.pastPurchases) {
      final status = purchase.status.name;
      statuses.update(status, (count) => count + 1, ifAbsent: () => 1);
    }
    return {
      'status': response.error == null ? 'ok' : 'store_error',
      'errorCode': response.error?.code,
      'purchaseCount': response.pastPurchases.length,
      'statusCounts': statuses,
    };
  } on TimeoutException {
    return {'status': 'timeout'};
  } catch (_) {
    return {'status': 'query_exception'};
  }
}

Future<Map<String, Object?>> _diagnose() async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
    return {'status': 'android_required'};
  }
  try {
    final store = InAppPurchase.instance;
    final available = await store.isAvailable().timeout(_queryTimeout);
    if (!available) return {'isAvailable': false};
    final results = await Future.wait([
      _queryProducts(store),
      _queryOwnership(store),
    ]);
    return {
      'isAvailable': true,
      'catalog': results[0],
      'ownership': results[1],
    };
  } on TimeoutException {
    return {'isAvailable': null, 'status': 'availability_timeout'};
  } catch (_) {
    return {'isAvailable': null, 'status': 'availability_exception'};
  }
}

class _BillingDiagnosticApp extends StatefulWidget {
  const _BillingDiagnosticApp();

  @override
  State<_BillingDiagnosticApp> createState() => _BillingDiagnosticAppState();
}

class _BillingDiagnosticAppState extends State<_BillingDiagnosticApp> {
  Map<String, Object?>? _report;

  @override
  void initState() {
    super.initState();
    unawaited(_run());
  }

  Future<void> _run() async {
    final report = await _diagnose();
    debugPrint('PLAY_BILLING_DIAGNOSTIC ${jsonEncode(report)}');
    if (mounted) setState(() => _report = report);
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      appBar: AppBar(title: const Text('Play Billing · 조회 진단')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('상품 가격과 구매 상태만 조회합니다.'),
              const SizedBox(height: 16),
              if (_report == null)
                const CircularProgressIndicator()
              else
                SelectableText(_json.convert(_report)),
            ],
          ),
        ),
      ),
    ),
  );
}
