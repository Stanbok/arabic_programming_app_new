import 'package:flutter/material.dart';
import '../../../scripts/seed_firestore.dart';

class DevSeederScreen extends StatefulWidget {
  const DevSeederScreen({super.key});

  @override
  State<DevSeederScreen> createState() => _DevSeederScreenState();
}

class _DevSeederScreenState extends State<DevSeederScreen> {
  final FirestoreSeeder _seeder = FirestoreSeeder();
  bool _isLoading = false;
  String _status = '';
  List<String> _logs = [];

  Future<void> _seedData() async {
    setState(() {
      _isLoading = true;
      _status = 'جاري إضافة البيانات...';
      _logs = [];
    });

    try {
      _addLog('بدء إضافة المسارات...');
      await _seeder.seedPaths();
      _addLog('تم إضافة 5 مسارات');
      
      _addLog('بدء إضافة الدروس...');
      await _seeder.seedLessons();
      _addLog('تم إضافة 15 درساً');
      
      setState(() {
        _status = 'تم إضافة جميع البيانات بنجاح!';
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إضافة البيانات بنجاح!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _status = 'خطأ: $e';
      });
      _addLog('خطأ: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _clearData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من حذف جميع البيانات؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isLoading = true;
      _status = 'جاري حذف البيانات...';
    });

    try {
      await _seeder.clearAll();
      setState(() {
        _status = 'تم حذف جميع البيانات';
        _logs = [];
      });
    } catch (e) {
      setState(() {
        _status = 'خطأ: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _addLog(String message) {
    setState(() {
      _logs.add('${DateTime.now().toString().substring(11, 19)} - $message');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إعداد قاعدة البيانات'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Card
            Card(
              color: Colors.deepPurple.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(
                      Icons.storage_rounded,
                      size: 48,
                      color: Colors.deepPurple.shade700,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'أداة إعداد Firestore',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'هذه الصفحة للمطورين فقط.\nاستخدمها لإضافة البيانات الأولية للتطبيق.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _seedData,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.cloud_upload_rounded),
                    label: const Text('إضافة البيانات'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _clearData,
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: const Text('حذف الكل'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Status
            if (_status.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _status.contains('خطأ')
                      ? Colors.red.shade50
                      : _status.contains('نجاح')
                          ? Colors.green.shade50
                          : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _status.contains('خطأ')
                        ? Colors.red.shade200
                        : _status.contains('نجاح')
                            ? Colors.green.shade200
                            : Colors.blue.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _status.contains('خطأ')
                          ? Icons.error_outline
                          : _status.contains('نجاح')
                              ? Icons.check_circle_outline
                              : Icons.info_outline,
                      color: _status.contains('خطأ')
                          ? Colors.red
                          : _status.contains('نجاح')
                              ? Colors.green
                              : Colors.blue,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _status,
                        style: TextStyle(
                          color: _status.contains('خطأ')
                              ? Colors.red.shade700
                              : _status.contains('نجاح')
                                  ? Colors.green.shade700
                                  : Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            
            const SizedBox(height: 16),
            
            // Logs
            if (_logs.isNotEmpty) ...[
              const Text(
                'السجل:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView.builder(
                    itemCount: _logs.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          _logs[index],
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ] else
              const Spacer(),
            
            // Data Overview
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'البيانات المتوفرة:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildDataItem('المسارات', '5 مسارات'),
                    _buildDataItem('الدروس', '15 درساً (عينة)'),
                    _buildDataItem('الأسئلة', '4 أسئلة لكل درس'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataItem(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.check_circle, size: 16, color: Colors.green.shade600),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
          const Spacer(),
          Text(value, style: TextStyle(color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}
