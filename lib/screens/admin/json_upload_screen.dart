import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'dart:io';
import '../../providers/admin_provider.dart';
import '../../models/admin_model.dart';

class JsonUploadScreen extends StatefulWidget {
  const JsonUploadScreen({Key? key}) : super(key: key);

  @override
  State<JsonUploadScreen> createState() => _JsonUploadScreenState();
}

class _JsonUploadScreenState extends State<JsonUploadScreen> {
  String? _selectedFilePath;
  Map<String, dynamic>? _jsonData;
  String? _validationError;
  bool _isValidating = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('رفع درس من ملف JSON'),
        backgroundColor: Colors.red[600],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildInstructionsCard(),
            const SizedBox(height: 24),
            _buildFilePickerSection(),
            const SizedBox(height: 24),
            if (_jsonData != null) _buildPreviewSection(),
            const SizedBox(height: 24),
            _buildUploadButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'تعليمات رفع ملف JSON',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'يجب أن يحتوي ملف JSON على البنية التالية:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '''
{
  "title": "عنوان الدرس",
  "description": "وصف الدرس",
  "level": 1,
  "order": 1,
  "xpReward": 50,
  "gemsReward": 2,
  "imageUrl": "رابط الصورة (اختياري)",
  "slides": [
    {
      "title": "عنوان الشريحة",
      "content": "محتوى الشريحة",
      "imageUrl": "رابط الصورة (اختياري)",
      "codeExample": "مثال الكود (اختياري)",
      "order": 1
    }
  ],
  "quiz": [
    {
      "question": "نص السؤال",
      "options": ["الخيار 1", "الخيار 2", "الخيار 3", "الخيار 4"],
      "correctAnswerIndex": 0,
      "explanation": "التفسير (اختياري)"
    }
  ]
}''',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilePickerSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'اختيار ملف JSON',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _pickJsonFile,
              icon: const Icon(Icons.file_upload),
              label: const Text('اختيار ملف JSON'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
            if (_selectedFilePath != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  border: Border.all(color: Colors.green[200]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'تم اختيار الملف: ${_selectedFilePath!.split('/').last}',
                        style: TextStyle(color: Colors.green[800]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (_validationError != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  border: Border.all(color: Colors.red[200]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.error, color: Colors.red[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _validationError!,
                        style: TextStyle(color: Colors.red[800]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'معاينة الدرس',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildPreviewItem('العنوان', _jsonData!['title']),
            _buildPreviewItem('الوصف', _jsonData!['description']),
            _buildPreviewItem('المستوى', _jsonData!['level'].toString()),
            _buildPreviewItem('عدد الشرائح', _jsonData!['slides'].length.toString()),
            _buildPreviewItem('عدد الأسئلة', _jsonData!['quiz'].length.toString()),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadButton() {
    return Consumer<AdminProvider>(
      builder: (context, adminProvider, child) {
        return ElevatedButton(
          onPressed: (_jsonData != null && !adminProvider.isLoading) 
              ? _uploadFromJson 
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red[600],
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
          ),
          child: adminProvider.isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text(
                  'رفع الدرس',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
        );
      },
    );
  }

  Future<void> _pickJsonFile() async {
    try {
      setState(() {
        _isValidating = true;
        _validationError = null;
      });

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null) {
        final file = File(result.files.single.path!);
        final jsonString = await file.readAsString();
        
        try {
          final jsonData = json.decode(jsonString);
          final validationResult = _validateJsonStructure(jsonData);
          
          if (validationResult == null) {
            setState(() {
              _selectedFilePath = result.files.single.path;
              _jsonData = jsonData;
              _validationError = null;
            });
          } else {
            setState(() {
              _validationError = validationResult;
              _jsonData = null;
            });
          }
        } catch (e) {
          setState(() {
            _validationError = 'خطأ في تحليل ملف JSON: ${e.toString()}';
            _jsonData = null;
          });
        }
      }
    } catch (e) {
      setState(() {
        _validationError = 'خطأ في قراءة الملف: ${e.toString()}';
        _jsonData = null;
      });
    } finally {
      setState(() {
        _isValidating = false;
      });
    }
  }

  String? _validateJsonStructure(Map<String, dynamic> data) {
    // التحقق من الحقول المطلوبة
    final requiredFields = ['title', 'description', 'level', 'order', 'slides'];
    for (final field in requiredFields) {
      if (!data.containsKey(field)) {
        return 'الحقل المطلوب "$field" مفقود';
      }
    }

    // التحقق من أنواع البيانات
    if (data['title'] is! String || data['title'].isEmpty) {
      return 'حقل "title" يجب أن يكون نص غير فارغ';
    }
    
    if (data['description'] is! String || data['description'].isEmpty) {
      return 'حقل "description" يجب أن يكون نص غير فارغ';
    }
    
    if (data['level'] is! int || data['level'] < 1) {
      return 'حقل "level" يجب أن يكون رقم أكبر من 0';
    }
    
    if (data['order'] is! int || data['order'] < 1) {
      return 'حقل "order" يجب أن يكون رقم أكبر من 0';
    }

    // التحقق من الشرائح
    if (data['slides'] is! List || (data['slides'] as List).isEmpty) {
      return 'يجب أن تحتوي على شريحة واحدة على الأقل';
    }

    final slides = data['slides'] as List;
    for (int i = 0; i < slides.length; i++) {
      final slide = slides[i];
      if (slide is! Map<String, dynamic>) {
        return 'الشريحة ${i + 1} يجب أن تكون كائن JSON';
      }
      
      if (!slide.containsKey('title') || slide['title'] is! String || slide['title'].isEmpty) {
        return 'الشريحة ${i + 1} تحتاج إلى عنوان صحيح';
      }
      
      if (!slide.containsKey('content') || slide['content'] is! String || slide['content'].isEmpty) {
        return 'الشريحة ${i + 1} تحتاج إلى محتوى صحيح';
      }
    }

    // التحقق من الأسئلة (اختياري)
    if (data.containsKey('quiz') && data['quiz'] is List) {
      final quiz = data['quiz'] as List;
      for (int i = 0; i < quiz.length; i++) {
        final question = quiz[i];
        if (question is! Map<String, dynamic>) {
          return 'السؤال ${i + 1} يجب أن يكون كائن JSON';
        }
        
        if (!question.containsKey('question') || question['question'] is! String || question['question'].isEmpty) {
          return 'السؤال ${i + 1} يحتاج إلى نص صحيح';
        }
        
        if (!question.containsKey('options') || question['options'] is! List || (question['options'] as List).length < 2) {
          return 'السؤال ${i + 1} يحتاج إلى خيارين على الأقل';
        }
        
        if (!question.containsKey('correctAnswerIndex') || question['correctAnswerIndex'] is! int) {
          return 'السؤال ${i + 1} يحتاج إلى فهرس الإجابة الصحيحة';
        }
        
        final correctIndex = question['correctAnswerIndex'] as int;
        final options = question['options'] as List;
        if (correctIndex < 0 || correctIndex >= options.length) {
          return 'السؤال ${i + 1} فهرس الإجابة الصحيحة غير صحيح';
        }
      }
    }

    return null; // لا توجد أخطاء
  }

  Future<void> _uploadFromJson() async {
    if (_jsonData == null) return;

    try {
      // تحويل البيانات إلى نموذج الرفع
      final slides = (_jsonData!['slides'] as List).map((slideData) {
        return SlideUploadModel(
          title: slideData['title'],
          content: slideData['content'],
          imageUrl: slideData['imageUrl'],
          codeExample: slideData['codeExample'],
          order: slideData['order'] ?? 0,
        );
      }).toList();

      final quiz = (_jsonData!['quiz'] as List?)?.map((questionData) {
        return QuizUploadModel(
          question: questionData['question'],
          options: List<String>.from(questionData['options']),
          correctAnswerIndex: questionData['correctAnswerIndex'],
          explanation: questionData['explanation'],
        );
      }).toList() ?? [];

      final lessonData = LessonUploadModel(
        title: _jsonData!['title'],
        description: _jsonData!['description'],
        imageUrl: _jsonData!['imageUrl'],
        level: _jsonData!['level'],
        order: _jsonData!['order'],
        xpReward: _jsonData!['xpReward'] ?? 50,
        gemsReward: _jsonData!['gemsReward'] ?? 2,
        slides: slides,
        quiz: quiz,
      );

      final success = await context.read<AdminProvider>().uploadLesson(lessonData);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم رفع الدرس بنجاح من ملف JSON!')),
        );
        setState(() {
          _selectedFilePath = null;
          _jsonData = null;
          _validationError = null;
        });
      } else if (mounted) {
        final error = context.read<AdminProvider>().errorMessage;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error ?? 'حدث خطأ أثناء رفع الدرس')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في معالجة البيانات: ${e.toString()}')),
        );
      }
    }
  }
}
