import 'dart:async';

import 'package:flutter/foundation.dart';

/// Firestore çağrılarına üst sınır — veritabanı yok / offline iken sonsuz bekleme olmasın.
Future<T> withFirestoreTimeout<T>(
  Future<T> operation, {
  Duration timeout = const Duration(seconds: 8),
  required T fallback,
  String? debugLabel,
}) async {
  try {
    return await operation.timeout(timeout);
  } on TimeoutException {
    debugPrint(
      'Firestore timeout${debugLabel != null ? ' ($debugLabel)' : ''}',
    );
    return fallback;
  } catch (e) {
    debugPrint(
      'Firestore error${debugLabel != null ? ' ($debugLabel)' : ''}: $e',
    );
    return fallback;
  }
}

/// Yazma işlemleri — hata/timeout'ta sessizce devam eder.
Future<void> withFirestoreVoidTimeout(
  Future<void> operation, {
  Duration timeout = const Duration(seconds: 8),
  String? debugLabel,
}) async {
  try {
    await operation.timeout(timeout);
  } on TimeoutException {
    debugPrint(
      'Firestore timeout${debugLabel != null ? ' ($debugLabel)' : ''}',
    );
  } catch (e) {
    debugPrint(
      'Firestore error${debugLabel != null ? ' ($debugLabel)' : ''}: $e',
    );
  }
}
