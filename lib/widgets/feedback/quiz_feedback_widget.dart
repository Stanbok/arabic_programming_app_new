import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class QuizFeedbackWidget extends StatefulWidget {
  final bool isCorrect;
  final String? explanation;
  final VoidCallback? onContinue;
  final int? earnedXP;
  final int? earnedGems;

  const QuizFeedbackWidget({
    Key? key,
    required this.isCorrect,
    this.explanation,
    this.onContinue,
    this.earnedXP,
    this.earnedGems,
  }) : super(key: key);

  @override
  State<QuizFeedbackWidget> createState() => _QuizFeedbackWidgetState();
}

class _QuizFeedbackWidgetState extends State<QuizFeedbackWidget>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _bounceController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));

    _bounceAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.elasticOut,
    ));

    _slideController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _bounceController.forward();
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: widget.isCorrect ? Colors.green.shade50 : Colors.red.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: widget.isCorrect ? Colors.green : Colors.red,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: (widget.isCorrect ? Colors.green : Colors.red).withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animation and Icon
            ScaleTransition(
              scale: _bounceAnimation,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: widget.isCorrect ? Colors.green : Colors.red,
                  shape: BoxShape.circle,
                ),
                child: widget.isCorrect
                    ? Lottie.asset(
                        'assets/animations/success.json',
                        width: 60,
                        height: 60,
                        fit: BoxFit.contain,
                      )
                    : const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 40,
                      ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Title
            Text(
              widget.isCorrect ? 'ممتاز!' : 'حاول مرة أخرى',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: widget.isCorrect ? Colors.green.shade700 : Colors.red.shade700,
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Explanation
            if (widget.explanation != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Text(
                  widget.explanation!,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Rewards (if correct)
            if (widget.isCorrect && (widget.earnedXP != null || widget.earnedGems != null)) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.amber.shade100, Colors.orange.shade100],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (widget.earnedXP != null)
                      _buildRewardItem(
                        Icons.star,
                        '${widget.earnedXP}',
                        'XP',
                        Colors.blue,
                      ),
                    if (widget.earnedGems != null)
                      _buildRewardItem(
                        Icons.diamond,
                        '${widget.earnedGems}',
                        'جوهرة',
                        Colors.amber,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Continue Button
            if (widget.onContinue != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: widget.onContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.isCorrect ? Colors.green : Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    widget.isCorrect ? 'متابعة' : 'إعادة المحاولة',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRewardItem(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color.withOpacity(0.8),
          ),
        ),
      ],
    );
  }
}
