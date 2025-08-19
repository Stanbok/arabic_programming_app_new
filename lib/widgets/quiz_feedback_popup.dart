import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../models/lesson_model.dart';
import '../services/quiz_engine.dart';
import 'custom_button.dart';

class QuizFeedbackPopup extends StatefulWidget {
  final QuizQuestionModel question;
  final dynamic userAnswer;
  final bool isCorrect;
  final VoidCallback onContinue;

  const QuizFeedbackPopup({
    Key? key,
    required this.question,
    required this.userAnswer,
    required this.isCorrect,
    required this.onContinue,
  }) : super(key: key);

  @override
  State<QuizFeedbackPopup> createState() => _QuizFeedbackPopupState();
}

class _QuizFeedbackPopupState extends State<QuizFeedbackPopup>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _slideController;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _scaleController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      child: Center(
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // أيقونة النتيجة مع الرسوم المتحركة
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.isCorrect 
                          ? Colors.green.withOpacity(0.1)
                          : Colors.red.withOpacity(0.1),
                    ),
                    child: widget.isCorrect
                        ? Lottie.asset(
                            'assets/animations/success.json',
                            width: 60,
                            height: 60,
                            repeat: false,
                          )
                        : Icon(
                            Icons.close_rounded,
                            size: 40,
                            color: Colors.red[600],
                          ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // عنوان النتيجة
                  Text(
                    widget.isCorrect ? 'إجابة صحيحة!' : 'إجابة خاطئة',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: widget.isCorrect 
                          ? Colors.green[700]
                          : Colors.red[700],
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // الشرح إذا كان متوفراً
                  if (widget.question.explanation?.isNotEmpty == true) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.lightbulb_outline,
                                size: 20,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'الشرح',
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.question.explanation!,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // الإجابة الصحيحة إذا كانت الإجابة خاطئة
                  if (!widget.isCorrect) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.green.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                size: 20,
                                color: Colors.green[700],
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'الإجابة الصحيحة',
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[700],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _getCorrectAnswerText(),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.green[800],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // زر المتابعة
                  SizedBox(
                    width: double.infinity,
                    child: CustomButton(
                      text: 'متابعة',
                      onPressed: widget.onContinue,
                      icon: Icons.arrow_forward_ios,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getCorrectAnswerText() {
    switch (widget.question.type) {
      case QuestionType.multipleChoice:
        final correctIndex = widget.question.correctAnswerIndex ?? 0;
        return widget.question.options![correctIndex];
      
      case QuestionType.trueFalse:
        return widget.question.correctBoolean == true ? 'صحيح' : 'خطأ';
      
      case QuestionType.fillInBlank:
        return widget.question.correctAnswers?.join(', ') ?? '';
      
      case QuestionType.reorderCode:
        final correctOrder = widget.question.correctOrder ?? [];
        return correctOrder.map((i) => widget.question.codeBlocks![i]).join('\n');
      
      case QuestionType.findBug:
        return widget.question.correctCode ?? '';
      
      case QuestionType.codeOutput:
        return widget.question.expectedOutput ?? '';
      
      case QuestionType.completeCode:
        return widget.question.codeTemplate ?? '';
      
      default:
        return 'غير محدد';
    }
  }
}
