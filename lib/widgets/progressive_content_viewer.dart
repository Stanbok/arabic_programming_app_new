import 'package:flutter/material.dart';
import 'dart:async';

class ProgressiveContentViewer extends StatefulWidget {
  final String title;
  final String content;
  final String? imageUrl;
  final String? codeExample;
  final VoidCallback? onCompleted;
  final bool isLastSlide;

  const ProgressiveContentViewer({
    super.key,
    required this.title,
    required this.content,
    this.imageUrl,
    this.codeExample,
    this.onCompleted,
    this.isLastSlide = false,
  });

  @override
  State<ProgressiveContentViewer> createState() => _ProgressiveContentViewerState();
}

class _ProgressiveContentViewerState extends State<ProgressiveContentViewer>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  List<String> _contentParagraphs = [];
  int _currentParagraphIndex = 0;
  bool _showContinueHint = true;
  bool _allContentShown = false;
  bool _showNextButton = false;
  
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    _initializeContent();
    _startContentDisplay();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _initializeContent() {
    // تقسيم المحتوى إلى فقرات
    final paragraphs = widget.content
        .split('\n\n')
        .where((p) => p.trim().isNotEmpty)
        .map((p) => p.trim())
        .toList();
    
    // إذا كان هناك فقرة واحدة طويلة، قسمها بناءً على الجمل
    if (paragraphs.length == 1 && paragraphs[0].length > 200) {
      final sentences = paragraphs[0].split('. ');
      _contentParagraphs = [];
      String currentParagraph = '';
      
      for (int i = 0; i < sentences.length; i++) {
        final sentence = sentences[i] + (i < sentences.length - 1 ? '. ' : '');
        if (currentParagraph.length + sentence.length > 150 && currentParagraph.isNotEmpty) {
          _contentParagraphs.add(currentParagraph.trim());
          currentParagraph = sentence;
        } else {
          currentParagraph += sentence;
        }
      }
      
      if (currentParagraph.isNotEmpty) {
        _contentParagraphs.add(currentParagraph.trim());
      }
    } else {
      _contentParagraphs = paragraphs;
    }
    
    // إضافة العنوان كفقرة أولى إذا لم يكن فارغاً
    if (widget.title.isNotEmpty) {
      _contentParagraphs.insert(0, widget.title);
    }
  }

  void _startContentDisplay() {
    _fadeController.forward();
    _slideController.forward();
  }

  void _handleTap() {
    if (!_allContentShown) {
      _showNextParagraph();
    }
  }

  void _showNextParagraph() {
    if (_currentParagraphIndex < _contentParagraphs.length - 1) {
      setState(() {
        _currentParagraphIndex++;
        _showContinueHint = true;
      });
      
      // تحريك النص لأسفل تلقائياً
      Timer(const Duration(milliseconds: 300), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
      });
      
      // إخفاء التلميح بعد ثانيتين
      Timer(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _showContinueHint = false;
          });
        }
      });
    } else {
      // تم عرض جميع الفقرات
      setState(() {
        _allContentShown = true;
        _showContinueHint = false;
        _showNextButton = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      behavior: HitTestBehavior.translucent,
      child: Container(
        height: double.infinity,
        width: double.infinity,
        child: Stack(
          children: [
            // المحتوى الرئيسي
            SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // الصورة إذا كانت موجودة
                  if (widget.imageUrl != null) ...[
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Container(
                          width: double.infinity,
                          height: 200,
                          margin: const EdgeInsets.only(bottom: 24),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.asset(
                              widget.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                  child: Icon(
                                    Icons.image_not_supported,
                                    size: 40,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                  
                  // الفقرات التدريجية
                  ...List.generate(_currentParagraphIndex + 1, (index) {
                    final isTitle = index == 0 && widget.title.isNotEmpty;
                    final paragraph = _contentParagraphs[index];
                    
                    return AnimatedContainer(
                      duration: Duration(milliseconds: 600 + (index * 200)),
                      curve: Curves.easeOutCubic,
                      margin: const EdgeInsets.only(bottom: 20),
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: isTitle 
                                  ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                                  : Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              paragraph,
                              style: isTitle
                                  ? Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).colorScheme.primary,
                                    )
                                  : Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      height: 1.6,
                                      fontSize: 16,
                                    ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                  
                  // مثال الكود إذا كان موجوداً
                  if (widget.codeExample != null && _allContentShown) ...[
                    const SizedBox(height: 20),
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[900],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey[700]!,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.code, color: Colors.blue[300], size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'مثال الكود',
                                  style: TextStyle(
                                    color: Colors.blue[300],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              widget.codeExample!,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 100), // مساحة للزر
                ],
              ),
            ),
            
            // تلميح "انقر للمتابعة"
            if (_showContinueHint && !_allContentShown)
              Positioned(
                bottom: 100,
                left: 0,
                right: 0,
                child: AnimatedOpacity(
                  opacity: _showContinueHint ? 0.7 : 0.0,
                  duration: const Duration(milliseconds: 500),
                  child: Container(
                    alignment: Alignment.center,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.touch_app,
                            color: Colors.white.withOpacity(0.8),
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'انقر للمتابعة',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            
            // زر "تابع" البنفسجي
            if (_showNextButton)
              Positioned(
                bottom: 30,
                left: 24,
                right: 24,
                child: AnimatedScale(
                  scale: _showNextButton ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.elasticOut,
                  child: Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF8B5CF6).withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: widget.onCompleted,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'تابع',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.arrow_forward_ios,
                                color: Colors.white,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
