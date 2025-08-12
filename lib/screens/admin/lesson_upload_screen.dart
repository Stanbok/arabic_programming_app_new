import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../models/admin_model.dart';

class LessonUploadScreen extends StatefulWidget {
  const LessonUploadScreen({Key? key}) : super(key: key);

  @override
  State<LessonUploadScreen> createState() => _LessonUploadScreenState();
}

class _LessonUploadScreenState extends State<LessonUploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _levelController = TextEditingController(text: '1');
  final _orderController = TextEditingController(text: '1');
  final _xpRewardController = TextEditingController(text: '50');
  final _gemsRewardController = TextEditingController(text: '2');

  List<SlideUploadModel> _slides = [];
  List<QuizUploadModel> _quiz = [];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    _levelController.dispose();
    _orderController.dispose();
    _xpRewardController.dispose();
    _gemsRewardController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('رفع درس جديد'),
        backgroundColor: Colors.red[600],
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.white,
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildBasicInfoSection(),
            const SizedBox(height: 24),
            _buildSlidesSection(),
            const SizedBox(height: 24),
            _buildQuizSection(),
            const SizedBox(height: 32),
            _buildUploadButton(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'معلومات الدرس الأساسية',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'عنوان الدرس *',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'يرجى إدخال عنوان الدرس';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'وصف الدرس *',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'يرجى إدخال وصف الدرس';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _imageUrlController,
              decoration: const InputDecoration(
                labelText: 'رابط الصورة (اختياري)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _levelController,
                    decoration: const InputDecoration(
                      labelText: 'المستوى *',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'مطلوب';
                      }
                      if (int.tryParse(value) == null) {
                        return 'رقم غير صحيح';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _orderController,
                    decoration: const InputDecoration(
                      labelText: 'الترتيب *',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'مطلوب';
                      }
                      if (int.tryParse(value) == null) {
                        return 'رقم غير صحيح';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _xpRewardController,
                    decoration: const InputDecoration(
                      labelText: 'مكافأة XP',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _gemsRewardController,
                    decoration: const InputDecoration(
                      labelText: 'مكافأة الجواهر',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlidesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'شرائح الدرس',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  onPressed: _addSlide,
                  icon: const Icon(Icons.add),
                  label: const Text('إضافة شريحة'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_slides.isEmpty)
              const Center(
                child: Text(
                  'لم يتم إضافة شرائح بعد',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _slides.length,
                itemBuilder: (context, index) {
                  return _buildSlideCard(index);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlideCard(int index) {
    final slide = _slides[index];
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'الشريحة ${index + 1}: ${slide.title}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: () => _editSlide(index),
                      icon: const Icon(Icons.edit, size: 20),
                    ),
                    IconButton(
                      onPressed: () => _removeSlide(index),
                      icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                    ),
                  ],
                ),
              ],
            ),
            Text(
              slide.content,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey[600]),
            ),
            if (slide.codeExample != null)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  slide.codeExample!,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizSection() {
    return Card(
      color: Colors.white,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'أسئلة الاختبار',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showQuizQuestionDialog(),
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text('إضافة سؤال'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_quiz.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.quiz_outlined, size: 48, color: Colors.grey),
                    SizedBox(height: 8),
                    Text(
                      'لم يتم إضافة أسئلة بعد',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  ],
                ),
              )
            else
              Container(
                constraints: const BoxConstraints(maxHeight: 400),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _quiz.length,
                  itemBuilder: (context, index) {
                    return _buildQuizQuestionCard(index);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizQuestionCard(int index) {
    final question = _quiz[index];
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'السؤال ${index + 1}: ${question.question}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: () => _editQuizQuestion(index),
                      icon: const Icon(Icons.edit, size: 20),
                    ),
                    IconButton(
                      onPressed: () => _removeQuizQuestion(index),
                      icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...question.options.asMap().entries.map((entry) {
              final optionIndex = entry.key;
              final option = entry.value;
              final isCorrect = optionIndex == question.correctAnswerIndex;
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(
                      isCorrect ? Icons.check_circle : Icons.radio_button_unchecked,
                      color: isCorrect ? Colors.green : Colors.grey,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(option)),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadButton() {
    return Consumer<AdminProvider>(
      builder: (context, adminProvider, child) {
        return Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton.icon(
            onPressed: adminProvider.isLoading ? null : _uploadLesson,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            icon: adminProvider.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.cloud_upload, size: 24),
            label: Text(
              adminProvider.isLoading ? 'جاري الرفع...' : 'رفع الدرس',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        );
      },
    );
  }

  void _addSlide() {
    _showSlideDialog();
  }

  void _editSlide(int index) {
    _showSlideDialog(slide: _slides[index], index: index);
  }

  void _removeSlide(int index) {
    setState(() {
      _slides.removeAt(index);
    });
  }

  void _editQuizQuestion(int index) {
    _showQuizQuestionDialog(question: _quiz[index], index: index);
  }

  void _removeQuizQuestion(int index) {
    setState(() {
      _quiz.removeAt(index);
    });
  }

  void _showQuizQuestionDialog({QuizUploadModel? question, int? index}) {
    final questionController = TextEditingController(text: question?.question ?? '');
    final explanationController = TextEditingController(text: question?.explanation ?? '');
    final optionControllers = List.generate(4, (i) => 
        TextEditingController(text: ((question?.options.length ?? 0) > i) ? question!.options[i] : ''));
    int correctAnswer = question?.correctAnswerIndex ?? 0;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(question == null ? 'إضافة سؤال' : 'تعديل السؤال'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: questionController,
                  decoration: const InputDecoration(labelText: 'نص السؤال'),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                ...List.generate(4, (i) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Radio<int>(
                        value: i,
                        groupValue: correctAnswer,
                        onChanged: (value) {
                          setDialogState(() {
                            correctAnswer = value!;
                          });
                        },
                      ),
                      Expanded(
                        child: TextField(
                          controller: optionControllers[i],
                          decoration: InputDecoration(labelText: 'الخيار ${i + 1}'),
                        ),
                      ),
                    ],
                  ),
                )),
                const SizedBox(height: 16),
                TextField(
                  controller: explanationController,
                  decoration: const InputDecoration(labelText: 'التفسير (اختياري)'),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () {
                if (questionController.text.isNotEmpty &&
                    optionControllers.every((controller) => controller.text.isNotEmpty)) {
                  final newQuestion = QuizUploadModel(
                    question: questionController.text,
                    options: optionControllers.map((c) => c.text).toList(),
                    correctAnswerIndex: correctAnswer,
                    explanation: explanationController.text.isEmpty ? null : explanationController.text,
                  );

                  setState(() {
                    if (index != null) {
                      _quiz[index] = newQuestion;
                    } else {
                      _quiz.add(newQuestion);
                    }
                  });
                  Navigator.pop(context);
                }
              },
              child: Text(question == null ? 'إضافة' : 'تحديث'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSlideDialog({SlideUploadModel? slide, int? index}) {
    final titleController = TextEditingController(text: slide?.title ?? '');
    final contentController = TextEditingController(text: slide?.content ?? '');
    final imageUrlController = TextEditingController(text: slide?.imageUrl ?? '');
    final codeController = TextEditingController(text: slide?.codeExample ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(slide == null ? 'إضافة شريحة' : 'تعديل الشريحة'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'عنوان الشريحة'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: contentController,
                decoration: const InputDecoration(labelText: 'محتوى الشريحة'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: imageUrlController,
                decoration: const InputDecoration(labelText: 'رابط الصورة (اختياري)'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: codeController,
                decoration: const InputDecoration(labelText: 'مثال الكود (اختياري)'),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              if (titleController.text.isNotEmpty && contentController.text.isNotEmpty) {
                final newSlide = SlideUploadModel(
                  title: titleController.text,
                  content: contentController.text,
                  imageUrl: imageUrlController.text.isEmpty ? null : imageUrlController.text,
                  codeExample: codeController.text.isEmpty ? null : codeController.text,
                  order: index ?? _slides.length,
                );

                setState(() {
                  if (index != null) {
                    _slides[index] = newSlide;
                  } else {
                    _slides.add(newSlide);
                  }
                });
                Navigator.pop(context);
              }
            },
            child: Text(slide == null ? 'إضافة' : 'تحديث'),
          ),
        ],
      ),
    );
  }

  Future<void> _uploadLesson() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_slides.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يجب إضافة شريحة واحدة على الأقل')),
      );
      return;
    }

    final lessonData = LessonUploadModel(
      title: _titleController.text,
      description: _descriptionController.text,
      imageUrl: _imageUrlController.text.isEmpty ? null : _imageUrlController.text,
      level: int.parse(_levelController.text),
      order: int.parse(_orderController.text),
      xpReward: int.parse(_xpRewardController.text),
      gemsReward: int.parse(_gemsRewardController.text),
      slides: _slides,
      quiz: _quiz,
    );

    final success = await context.read<AdminProvider>().uploadLesson(lessonData);
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم رفع الدرس بنجاح!')),
      );
      _clearForm();
    } else if (mounted) {
      final error = context.read<AdminProvider>().errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? 'حدث خطأ أثناء رفع الدرس')),
      );
    }
  }

  void _clearForm() {
    _titleController.clear();
    _descriptionController.clear();
    _imageUrlController.clear();
    _levelController.text = '1';
    _orderController.text = '1';
    _xpRewardController.text = '50';
    _gemsRewardController.text = '2';
    setState(() {
      _slides.clear();
      _quiz.clear();
    });
  }
}
