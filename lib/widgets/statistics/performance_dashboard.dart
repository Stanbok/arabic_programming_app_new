import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/lesson_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/lesson_model.dart';

class PerformanceDashboard extends StatelessWidget {
  const PerformanceDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<LessonProvider, AuthProvider>(
      builder: (context, lessonProvider, authProvider, child) {
        final userId = authProvider.user?.uid ?? 'guest';
        final performanceStats = lessonProvider.getUserPerformanceStats(userId);
        final questionTypePerformance = lessonProvider.getQuestionTypePerformance(userId);
        final dailyProgress = lessonProvider.getDailyProgress(userId);
        final studyStreak = lessonProvider.getStudyStreak(userId);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'لوحة الأداء',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 24),
              
              // إحصائيات عامة
              _buildOverallStats(context, performanceStats, studyStreak),
              
              const SizedBox(height: 24),
              
              // أداء أنواع الأسئلة
              if (questionTypePerformance.isNotEmpty) ...[
                _buildQuestionTypePerformance(context, questionTypePerformance),
                const SizedBox(height: 24),
              ],
              
              // التقدم اليومي
              if (dailyProgress.isNotEmpty) ...[
                _buildDailyProgressChart(context, dailyProgress),
                const SizedBox(height: 24),
              ],
              
              // نقاط القوة والضعف
              if (performanceStats != null) ...[
                _buildStrengthsAndWeaknesses(context, performanceStats),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildOverallStats(BuildContext context, UserPerformanceStats? stats, StudyStreak streak) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'الإحصائيات العامة',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    context,
                    'إجمالي الاختبارات',
                    '${stats?.totalQuizzes ?? 0}',
                    Icons.quiz,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    context,
                    'المتوسط العام',
                    '${(stats?.averageScore ?? 0).round()}%',
                    Icons.trending_up,
                    Colors.green,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    context,
                    'السلسلة الحالية',
                    '${streak.currentStreak} يوم',
                    Icons.local_fire_department,
                    streak.isActive ? Colors.orange : Colors.grey,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    context,
                    'أطول سلسلة',
                    '${streak.longestStreak} يوم',
                    Icons.emoji_events,
                    Colors.amber,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionTypePerformance(BuildContext context, Map<QuestionType, double> performance) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'أداء أنواع الأسئلة',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 16),
            
            ...performance.entries.map((entry) {
              final typeName = _getQuestionTypeLabel(entry.key);
              final percentage = entry.value;
              final color = _getPerformanceColor(percentage);
              
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(typeName),
                        Text(
                          '${percentage.round()}%',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: percentage / 100,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyProgressChart(BuildContext context, List<DailyProgress> dailyProgress) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'التقدم اليومي (آخر 7 أيام)',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 16),
            
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text('${value.toInt()}%');
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < dailyProgress.length) {
                            final date = dailyProgress[index].date;
                            return Text('${date.day}/${date.month}');
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: dailyProgress.asMap().entries.map((entry) {
                        return FlSpot(entry.key.toDouble(), entry.value.averageScore);
                      }).toList(),
                      isCurved: true,
                      color: Theme.of(context).colorScheme.primary,
                      barWidth: 3,
                      dotData: FlDotData(show: true),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStrengthsAndWeaknesses(BuildContext context, UserPerformanceStats stats) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // نقاط القوة
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.trending_up, color: Colors.green),
                      const SizedBox(width: 8),
                      Text(
                        'نقاط القوة',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (stats.strongAreas.isEmpty)
                    const Text('لا توجد بيانات كافية')
                  else
                    ...stats.strongAreas.map((type) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('• ${_getQuestionTypeLabel(type)}'),
                    )),
                ],
              ),
            ),
          ),
        ),
        
        const SizedBox(width: 16),
        
        // نقاط الضعف
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.trending_down, color: Colors.red),
                      const SizedBox(width: 8),
                      Text(
                        'نقاط الضعف',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (stats.weakAreas.isEmpty)
                    const Text('أداء ممتاز في جميع المجالات!')
                  else
                    ...stats.weakAreas.map((type) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('• ${_getQuestionTypeLabel(type)}'),
                    )),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _getQuestionTypeLabel(QuestionType type) {
    switch (type) {
      case QuestionType.multipleChoice:
        return 'اختيار من متعدد';
      case QuestionType.reorderCode:
        return 'ترتيب الكود';
      case QuestionType.findBug:
        return 'اكتشف الخطأ';
      case QuestionType.fillInBlank:
        return 'املأ الفراغ';
      case QuestionType.trueFalse:
        return 'صح أو خطأ';
      case QuestionType.matchPairs:
        return 'توصيل الأزواج';
      case QuestionType.codeOutput:
        return 'نتيجة الكود';
      case QuestionType.completeCode:
        return 'أكمل الكود';
    }
  }

  Color _getPerformanceColor(double percentage) {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 60) return Colors.orange;
    return Colors.red;
  }
}
