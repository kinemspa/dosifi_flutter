import 'package:flutter/material.dart';

/// Enhanced error handling utility for the Dosifi medication management app.
/// 
/// Provides:
/// - User-friendly error messages
/// - Detailed logging for debugging
/// - Error categorization for different contexts
/// - Recovery suggestions for common errors
class ErrorHandler {
  /// Logs an error with full context and stack trace
  /// 
  /// [error] - The error object
  /// [stackTrace] - Stack trace for debugging
  /// [context] - Additional context about where the error occurred
  static void logError(
    dynamic error, 
    StackTrace? stackTrace, {
    String? context,
  }) {
    final contextMessage = context != null ? '[$context] ' : '';
    debugPrint('${contextMessage}Error: $error');
    
    if (stackTrace != null) {
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  /// Shows a user-friendly error dialog with recovery options
  /// 
  /// [context] - BuildContext for showing dialog
  /// [error] - The error that occurred
  /// [onRetry] - Optional callback for retry functionality
  /// [title] - Custom title for the error dialog
  static void showErrorDialog(
    BuildContext context,
    dynamic error, {
    VoidCallback? onRetry,
    String? title,
  }) {
    final errorInfo = _getErrorInfo(error);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title ?? errorInfo.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(errorInfo.message),
            if (errorInfo.suggestion != null) ...[
              const SizedBox(height: 16),
              Text(
                'Suggestion:',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                errorInfo.suggestion!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
          if (onRetry != null)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                onRetry();
              },
              child: const Text('Retry'),
            ),
        ],
      ),
    );
  }

  /// Shows a snackbar with error information
  /// 
  /// [context] - BuildContext for showing snackbar
  /// [error] - The error that occurred
  /// [onRetry] - Optional callback for retry action
  static void showErrorSnackBar(
    BuildContext context,
    dynamic error, {
    VoidCallback? onRetry,
  }) {
    final errorInfo = _getErrorInfo(error);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(errorInfo.message),
        backgroundColor: Theme.of(context).colorScheme.error,
        action: onRetry != null
            ? SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: onRetry,
              )
            : null,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Gets user-friendly error information based on error type
  static _ErrorInfo _getErrorInfo(dynamic error) {
    final errorString = error.toString().toLowerCase();

    // Network related errors
    if (errorString.contains('network') ||
        errorString.contains('connection') ||
        errorString.contains('timeout')) {
      return _ErrorInfo(
        title: 'Connection Problem',
        message: 'Unable to connect to the server. Please check your internet connection.',
        suggestion: 'Make sure you have a stable internet connection and try again.',
      );
    }

    // Permission related errors
    if (errorString.contains('permission') ||
        errorString.contains('denied')) {
      return _ErrorInfo(
        title: 'Permission Required',
        message: 'The app needs permission to perform this action.',
        suggestion: 'Please grant the required permissions in your device settings.',
      );
    }

    // Database related errors
    if (errorString.contains('database') ||
        errorString.contains('sql') ||
        errorString.contains('table')) {
      return _ErrorInfo(
        title: 'Data Storage Error',
        message: 'There was a problem accessing your medication data.',
        suggestion: 'Try restarting the app. If the problem persists, you may need to reinstall.',
      );
    }

    // Notification related errors
    if (errorString.contains('notification') ||
        errorString.contains('scheduling')) {
      return _ErrorInfo(
        title: 'Notification Error',
        message: 'Unable to set up medication reminders.',
        suggestion: 'Check your notification settings and ensure the app has permission to send notifications.',
      );
    }

    // File system errors
    if (errorString.contains('file') ||
        errorString.contains('directory') ||
        errorString.contains('storage')) {
      return _ErrorInfo(
        title: 'Storage Error',
        message: 'Unable to access device storage.',
        suggestion: 'Make sure your device has enough free space and the app has storage permissions.',
      );
    }

    // Generic error fallback
    return _ErrorInfo(
      title: 'Something Went Wrong',
      message: 'An unexpected error occurred. Please try again.',
      suggestion: 'If this problem continues, try restarting the app.',
    );
  }
}

/// Internal class to hold error information
class _ErrorInfo {
  final String title;
  final String message;
  final String? suggestion;

  const _ErrorInfo({
    required this.title,
    required this.message,
    this.suggestion,
  });
}

/// Extension to add error handling capabilities to BuildContext
extension ErrorHandlingContext on BuildContext {
  /// Shows an error dialog using the error handler
  void showError(dynamic error, {VoidCallback? onRetry, String? title}) {
    ErrorHandler.showErrorDialog(this, error, onRetry: onRetry, title: title);
  }

  /// Shows an error snackbar using the error handler
  void showErrorSnackBar(dynamic error, {VoidCallback? onRetry}) {
    ErrorHandler.showErrorSnackBar(this, error, onRetry: onRetry);
  }
}
