import 'package:flutter/material.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/github.dart';
import '../../models/lesson_block_model.dart';
import '../../services/code_execution_service.dart';

class CodeBlockWidget extends StatefulWidget {
  final LessonBlockModel block;
  final Function(bool)? onEvaluationComplete;

  const CodeBlockWidget({
    Key? key,
    required this.block,
    this.onEvaluationComplete,
  }) super(key: key);

  @override
  State<CodeBlockWidget> createState() => _CodeBlockWidgetState();
}

class _CodeBlockWidgetState extends State<CodeBlockWidget> {
  late TextEditingController _codeController;
  bool _isExecuting = false;
  EvaluationResult? _lastResult;

  @override
  void initState() {
    super.initState();
    final codeType = widget.block.content['codeType'] as String;
    final initialCode = widget.block.content['code'] as String? ?? '';
    
    _codeController = TextEditingController(text: initialCode);
  }

  @override
  Widget build(BuildContext context) {
    final codeType = widget.block.content['codeType'] as String;
    final isReadonly = codeType == 'readonly';
    final isTemplate = codeType == 'template';
    
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.code,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.block.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  _buildCodeTypeChip(codeType),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // محرر الكود
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: isReadonly
                  ? _buildReadonlyCode()
                  : _buildEditableCode(isTemplate),
            ),
            
            const SizedBox(height: 16),
            
            // أزرار التحكم
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _isExecuting ? null : _executeCode,
                  icon: _isExecuting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.play_arrow),
                  label: Text(_isExecuting ? 'جاري التنفيذ...' : 'تشغيل'),
                ),
                if (!isReadonly) ...[
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: _resetCode,
                    icon: const Icon(Icons.refresh),
                    label: const Text('إعادة تعيين'),
                  ),
                ],
              ],
            ),
            
            // عرض النتيجة السابقة
            if (_lastResult != null) ...[
              const SizedBox(height: 16),
              _buildResultCard(_lastResult!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCodeTypeChip(String codeType) {
    Color chipColor;
    String chipLabel;
    
    switch (codeType) {
      case 'editable':
        chipColor = Colors.green;
        chipLabel = 'قابل للتعديل';
        break;
      case 'template':
        chipColor = Colors.orange;
        chipLabel = 'قالب';
        break;
      case 'readonly':
        chipColor = Colors.blue;
        chipLabel = 'للقراءة فقط';
        break;
      default:
        chipColor = Colors.grey;
        chipLabel = 'غير محدد';
    }
    
    return Chip(
      label: Text(
        chipLabel,
        style: const TextStyle(fontSize: 12, color: Colors.white),
      ),
      backgroundColor: chipColor,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildReadonlyCode() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: HighlightView(
        _codeController.text,
        language: 'python',
        theme: githubTheme,
        padding: const EdgeInsets.all(0),
        textStyle: const TextStyle(fontSize: 14),
      ),
    );
  }

  Widget _buildEditableCode(bool isTemplate) {
    return TextField(
      controller: _codeController,
      maxLines: null,
      style: const TextStyle(
        fontFamily: 'monospace',
        fontSize: 14,
      ),
      decoration: const InputDecoration(
        border: InputBorder.none,
        contentPadding: EdgeInsets.all(16),
        hintText: 'اكتب كودك هنا...',
      ),
    );
  }

  Widget _buildResultCard(EvaluationResult result) {
    return Card(
      color: result.passed ? Colors.green.shade50 : Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  result.passed ? Icons.check_circle : Icons.error,
                  color: result.passed ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  result.passed ? 'نجح!' : 'فشل!',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: result.passed ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(result.message),
            if (result.output.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('المخرجات:', style: TextStyle(fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  result.output,
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
              ),
            ],
            if (result.error.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('الأخطاء:', style: TextStyle(fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  result.error,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _executeCode() async {
    setState(() {
      _isExecuting = true;
    });

    try {
      if (widget.block.evaluation != null) {
        final result = await CodeExecutionService.evaluateCode(
          code: _codeController.text,
          evaluation: widget.block.evaluation!,
        );
        
        setState(() {
          _lastResult = result;
        });
        
        widget.onEvaluationComplete?.call(result.passed);
      } else {
        final result = await CodeExecutionService.executeCode(
          language: 'python',
          code: _codeController.text,
        );
        
        setState(() {
          _lastResult = EvaluationResult(
            passed: result.success,
            message: result.success ? 'تم التنفيذ بنجاح!' : 'حدث خطأ أثناء التنفيذ',
            output: result.output,
            error: result.error,
          );
        });
      }
    } finally {
      setState(() {
        _isExecuting = false;
      });
    }
  }

  void _resetCode() {
    final initialCode = widget.block.content['code'] as String? ?? '';
    _codeController.text = initialCode;
    setState(() {
      _lastResult = null;
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }
}
