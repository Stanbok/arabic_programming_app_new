/// Base exception class for all app exceptions
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const AppException(this.message, {this.code, this.originalError});

  @override
  String toString() => message;
}

/// Authentication related exceptions
class AuthException extends AppException {
  const AuthException(super.message, {super.code, super.originalError});

  factory AuthException.fromCode(String code) {
    switch (code) {
      case 'user-not-found':
        return const AuthException('المستخدم غير موجود', code: 'user-not-found');
      case 'wrong-password':
        return const AuthException('كلمة المرور غير صحيحة', code: 'wrong-password');
      case 'email-already-in-use':
        return const AuthException('البريد الإلكتروني مستخدم بالفعل', code: 'email-already-in-use');
      case 'weak-password':
        return const AuthException('كلمة المرور ضعيفة', code: 'weak-password');
      case 'invalid-email':
        return const AuthException('البريد الإلكتروني غير صالح', code: 'invalid-email');
      case 'credential-already-in-use':
        return const AuthException('هذا الحساب مرتبط بمستخدم آخر', code: 'credential-already-in-use');
      case 'user-disabled':
        return const AuthException('تم تعطيل هذا الحساب', code: 'user-disabled');
      case 'operation-not-allowed':
        return const AuthException('العملية غير مسموح بها', code: 'operation-not-allowed');
      case 'network-request-failed':
        return const AuthException('فشل الاتصال بالشبكة', code: 'network-request-failed');
      default:
        return AuthException('خطأ في المصادقة: $code', code: code);
    }
  }
}

/// Network related exceptions
class NetworkException extends AppException {
  const NetworkException(super.message, {super.code, super.originalError});

  factory NetworkException.noInternet() => 
    const NetworkException('لا يوجد اتصال بالإنترنت', code: 'no-internet');

  factory NetworkException.timeout() => 
    const NetworkException('انتهت مهلة الاتصال', code: 'timeout');

  factory NetworkException.serverError() => 
    const NetworkException('خطأ في الخادم', code: 'server-error');
}

/// Data/Storage related exceptions
class DataException extends AppException {
  const DataException(super.message, {super.code, super.originalError});

  factory DataException.notFound(String resource) => 
    DataException('$resource غير موجود', code: 'not-found');

  factory DataException.cacheMiss() => 
    const DataException('البيانات غير متوفرة محلياً', code: 'cache-miss');

  factory DataException.saveError() => 
    const DataException('فشل حفظ البيانات', code: 'save-error');

  factory DataException.parseError() => 
    const DataException('خطأ في تحليل البيانات', code: 'parse-error');
}

/// Lesson related exceptions
class LessonException extends AppException {
  const LessonException(super.message, {super.code, super.originalError});

  factory LessonException.notFound() => 
    const LessonException('الدرس غير موجود', code: 'lesson-not-found');

  factory LessonException.downloadFailed() => 
    const LessonException('فشل تحميل الدرس', code: 'download-failed');

  factory LessonException.locked() => 
    const LessonException('الدرس مقفل', code: 'lesson-locked');

  factory LessonException.progressSaveFailed() => 
    const LessonException('فشل حفظ التقدم', code: 'progress-save-failed');
}

/// Premium/Subscription related exceptions
class PremiumException extends AppException {
  const PremiumException(super.message, {super.code, super.originalError});

  factory PremiumException.required() => 
    const PremiumException('هذه الميزة تتطلب اشتراك بريميوم', code: 'premium-required');

  factory PremiumException.purchaseFailed() => 
    const PremiumException('فشل عملية الشراء', code: 'purchase-failed');

  factory PremiumException.expired() => 
    const PremiumException('انتهت صلاحية اشتراكك', code: 'subscription-expired');
}
