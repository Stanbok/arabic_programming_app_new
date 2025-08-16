import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/enhanced_lesson_model.dart';
import '../../providers/lesson_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/interactive_blocks/text_block_widget.dart';
import '../../widgets/interactive_blocks/code_block_widget.dart';
import '../../widgets/interactive_blocks/hint_widget.dart';
import '../../widgets/interactive_blocks/quiz_widgets/multiple_choice_widget.dart';
import '../../widgets/interactive_blocks/quiz_widgets/fill_blank_widget.dart';
import '../../widgets/interactive_blocks/quiz_widgets/code_completion_widget.dart';
import '../../widgets/interactive_blocks/quiz_widgets/drag_drop_widget.dart';

class EnhancedLessonScreen extends StatefulWidget {
  final String lessonId;

  const EnhancedLessonScreen({Key? key, required this.lessonId}) : super(key: key);

  @override
  State<EnhancedLessonScreen> createState() => _EnhancedLessonScreenState();
}

class _EnhancedLessonScreenState extends State<EnhancedLessonScreen> {
  PageController _pageController = PageController();
  int _currentBlockIndex = 0;
  Map<String, dynamic> _quizAnswers = {};
  bool _isQuizMode = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<LessonProvider, AuthProvider>(
      builder: (context, lessonProvider, authProvider, child) {
        final lesson = lessonProvider.getLessonById(widget.lessonId);
        
        if (lesson == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('درس غير موجود')),
            body: const Center(child: Text('لم يتم العثور على الدرس')),
          );
        }

        // تحويل الدرس العادي إلى درس محسن (مؤقت)
        final enhancedLesson = _convertToEnhancedLesson(lesson);

        return Scaffold(
          appBar: AppBar(
            title: Text(enhancedLesson.title),
            actions: [
              if (_isQuizMode)
                TextButton(
                  onPressed: _submitQuiz,
                  child: const Text('إرسال الإجابات'),
                ),
            ],
          ),
          body: Column(
            children: [
              // شريط التقدم
              LinearProgressIndicator(
                value: (_currentBlockIndex + 1) / enhancedLesson.blocks.length,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).primaryColor,
                ),
              ),
              
              // محتوى الدرس
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentBlockIndex = index;
                      _isQuizMode = enhancedLesson.blocks[index].type.startsWith('quiz');
                    });
                  },
                  itemCount: enhancedLesson.blocks.length,
                  itemBuilder: (context, index) {
                    final block = enhancedLesson.blocks[index];
                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: _buildBlock(block),
                    );
                  },
                ),
              ),
              
              // أزرار التنقل
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      onPressed: _currentBlockIndex > 0 ? _previousBlock : null,
                      child: const Text('السابق'),
                    ),
                    Text(
                      '${_currentBlockIndex + 1} من ${enhancedLesson.blocks.length}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    ElevatedButton(
                      onPressed: _currentBlockIndex < enhancedLesson.blocks.length - 1 
                          ? _nextBlock 
                          : _completeLesson,
                      child: Text(
                        _currentBlockIndex < enhancedLesson.blocks.length - 1 
                            ? 'التالي' 
                            : 'إنهاء الدرس'
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBlock(LessonBlock block) {
    switch (block.type) {
      case 'text':
        return TextBlockWidget(
          content: block.content['text'] ?? '',
          style: block.content['style'] ?? 'normal',
        );
      
      case 'code':
        return CodeBlockWidget(
          code: block.content['code'] ?? '',
          language: block.content['language'] ?? 'python',
          type: block.content['type'] ?? 'readonly',
          expectedOutput: block.content['expectedOutput'],
          onCodeChanged: (code) {
            // حفظ الكود المعدل
          },
        );
      
      case 'hint':
        return HintWidget(
          title: block.content['title'] ?? '',
          content: block.content['content'] ?? '',
          cost: block.content['cost'] ?? 5,
          onHintRevealed: () {
            // خصم الجواهر
          },
        );
      
      case 'quiz_multiple_choice':
        return MultipleChoiceWidget(
          question: MultipleChoiceQuestion.fromJson(block.content),
          onAnswerChanged: (answer) {
            _quizAnswers[block.id] = answer;
          },
        );
      
      case 'quiz_fill_blank':
        return FillBlankWidget(
          question: FillBlankQuestion.fromJson(block.content),
          onAnswerChanged: (answer) {
            _quizAnswers[block.id] = answer;
          },
        );
      
      case 'quiz_code_completion':
        return CodeCompletionWidget(
          question: CodeCompletionQuestion.fromJson(block.content),
          onAnswerChanged: (answer) {
            _quizAnswers[block.id] = answer;
          },
        );
      
      case 'quiz_drag_drop':
        return DragDropWidget(
          question: DragDropQuestion.fromJson(block.content),
          onAnswerChanged: (answer) {
            _quizAnswers[block.id] = answer;
          },
        );
      
      default:
        return Container(
          padding: const EdgeInsets.all(16),
          child: Text('نوع كتلة غير مدعوم: ${block.type}'),
        );
    }
  }

  void _nextBlock() {
    if (_currentBlockIndex < _pageController.positions.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousBlock() {
    if (_currentBlockIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _submitQuiz() {
    // تقييم الإجابات وعرض النتائج
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم إرسال الإجابات')),
    );
  }

  void _completeLesson() {
    // إنهاء الدرس والانتقال للاختبار النهائي
    Navigator.of(context).pop();
  }

  // دالة مؤقتة لتحويل الدرس العادي إلى درس محسن
  EnhancedLessonModel _convertToEnhancedLesson(dynamic lesson) {
    return EnhancedLessonModel(
      id: lesson.id,
      title: lesson.title,
      description: lesson.description,
      unit: lesson.unit,
      order: lesson.order,
      xpReward: lesson.xpReward,
      gemsReward: lesson.gemsReward,
      blocks: [
        LessonBlock(
          id: 'intro',
          type: 'text',
          content: {
            'text': lesson.description,
            'style': 'intro',
          },
        ),
        // إضافة المزيد من الكتل حسب محتوى الدرس
      ],
    );
  }
}
