import 'dart:convert';
import 'package:http/http.dart' as http;

class CodeExecutionService {
  static const String _pistonApiUrl = 'https://emkc.org/api/v2/piston';
  
  static Future<CodeExecutionResult> executeCode({
    required String language,
    required String code,
    List<String>? inputs,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_pistonApiUrl/execute'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'language': language,
          'version': '*',
          'files': [
            {
              'name': 'main.py',
              'content': code,
            }
          ],
          'stdin': inputs?.join('\n') ?? '',
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return CodeExecutionResult(
          success: true,
          output: data['run']['stdout'] ?? '',
          error: data['run']['stderr'] ?? '',
          exitCode: data['run']['code'] ?? 0,
        );
      } else {
        return CodeExecutionResult(
          success: false,
          output: '',
          error: 'فشل في تنفيذ الكود: ${response.statusCode}',
          exitCode: -1,
        );
      }
    } catch (e) {
      return CodeExecutionResult(
        success: false,
        output: '',
        error: 'خطأ في الاتصال: ${e.toString()}',
        exitCode: -1,
      );
    }
  }

  static Future<EvaluationResult> evaluateCode({
    required String code,
    required EvaluationModel evaluation,
    List<String>? inputs,
  }) async {
    final executionResult = await executeCode(
      language: 'python',
      code: code,
      inputs: inputs,
    );

    if (!executionResult.success) {
      return EvaluationResult(
        passed: false,
        message: evaluation.failureMessage,
        output: executionResult.output,
        error: executionResult.error,
      );
    }

    bool passed = false;
    String message = evaluation.failureMessage;

    switch (evaluation.type) {
      case 'exact':
        passed = executionResult.output.trim() == evaluation.expectedOutput.toString().trim();
        break;
      case 'contains':
        passed = executionResult.output.contains(evaluation.expectedOutput.toString());
        break;
      case 'regex':
        if (evaluation.pattern != null) {
          final regex = RegExp(evaluation.pattern!);
          passed = regex.hasMatch(executionResult.output);
        }
        break;
      case 'unit_tests':
        // تنفيذ اختبارات الوحدة
        passed = await _runUnitTests(code, evaluation.testCases ?? []);
        break;
      case 'custom':
        // تنفيذ سكريبت مخصص
        if (evaluation.customScript != null) {
          passed = await _runCustomScript(code, evaluation.customScript!);
        }
        break;
    }

    if (passed) {
      message = evaluation.successMessage;
    }

    return EvaluationResult(
      passed: passed,
      message: message,
      output: executionResult.output,
      error: executionResult.error,
    );
  }

  static Future<bool> _runUnitTests(String code, List<String> testCases) async {
    // تنفيذ اختبارات الوحدة
    for (String testCase in testCases) {
      final testCode = '$code\n$testCase';
      final result = await executeCode(language: 'python', code: testCode);
      if (!result.success || result.error.isNotEmpty) {
        return false;
      }
    }
    return true;
  }

  static Future<bool> _runCustomScript(String code, String customScript) async {
    final combinedCode = '$code\n$customScript';
    final result = await executeCode(language: 'python', code: combinedCode);
    return result.success && result.output.trim() == 'PASS';
  }
}

class CodeExecutionResult {
  final bool success;
  final String output;
  final String error;
  final int exitCode;

  CodeExecutionResult({
    required this.success,
    required this.output,
    required this.error,
    required this.exitCode,
  });
}

class EvaluationResult {
  final bool passed;
  final String message;
  final String output;
  final String error;

  EvaluationResult({
    required this.passed,
    required this.message,
    required this.output,
    required this.error,
  });
}
