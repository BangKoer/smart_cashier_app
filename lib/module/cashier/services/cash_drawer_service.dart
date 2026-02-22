import 'dart:developer';

class CashDrawerResult {
  final bool isSuccess;
  final String message;

  const CashDrawerResult({
    required this.isSuccess,
    required this.message,
  });
}

class CashDrawerService {
  // Placeholder mode for unsupported/legacy printer environment.
  // Set to false when real hardware command integration is ready.
  static const bool _usePlaceholderMode = true;

  Future<CashDrawerResult> openDrawer() async {
    if (_usePlaceholderMode) {
      log('[CashDrawer] Placeholder: open drawer triggered.');
      return const CashDrawerResult(
        isSuccess: true,
        message: 'Cash drawer placeholder executed.',
      );
    }

    // TODO: Replace with actual hardware integration:
    // 1) Platform channel (Windows/Linux native SDK)
    // 2) Serial/USB command
    // 3) HTTP call to local POS bridge service
    return const CashDrawerResult(
      isSuccess: false,
      message: 'Cash drawer integration is not implemented yet.',
    );
  }
}

