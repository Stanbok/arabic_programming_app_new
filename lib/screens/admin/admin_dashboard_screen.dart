import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../models/lesson_model.dart';
import 'lesson_upload_screen.dart';
import 'lesson_edit_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      context.read<AdminProvider>().loadMoreLessons();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'لوحة التحكم الإدارية',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.red[600],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () {
              context.read<AdminProvider>().exitAdminMode();
              Navigator.of(context).pop();
            },
            tooltip: 'خروج من وضع الإدارة',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.book), text: 'الدروس'),
            Tab(icon: Icon(Icons.upload), text: 'رفع درس'),
            Tab(icon: Icon(Icons.analytics), text: 'الإحصائيات'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLessonsTab(),
          const LessonUploadScreen(),
          _buildAnalyticsTab(),
        ],
      ),
    );
  }

  Widget _buildLessonsTab() {
    return Consumer<AdminProvider>(
      builder: (context, adminProvider, child) {
        if (adminProvider.isLoading && adminProvider.lessons.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (adminProvider.lessons.isEmpty) {
          return const Center(
            child: Text(
              'لا توجد دروس متاحة',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            // Refresh lessons
          },
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: adminProvider.lessons.length + 
                (adminProvider.hasMoreLessons ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == adminProvider.lessons.length) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final lesson = adminProvider.lessons[index];
              return _buildLessonCard(lesson, adminProvider);
            },
          ),
        );
      },
    );
  }

  Widget _buildLessonCard(LessonModel lesson, AdminProvider adminProvider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lesson.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        lesson.description,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: lesson.isPublished ? Colors.green : Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    lesson.isPublished ? 'منشور' : 'مسودة',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildInfoChip('المستوى ${lesson.level}', Icons.trending_up),
                const SizedBox(width: 8),
                _buildInfoChip('${lesson.slides.length} شريحة', Icons.slideshow),
                const SizedBox(width: 8),
                _buildInfoChip('${lesson.quiz.length} سؤال', Icons.quiz),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LessonEditScreen(lessonId: lesson.id),
                          ),
                        );
                      },
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('تعديل'),
                    ),
                    TextButton.icon(
                      onPressed: () => _showDeleteDialog(lesson, adminProvider),
                      icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                      label: const Text('حذف', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
                Switch(
                  value: lesson.isPublished,
                  onChanged: (value) {
                    adminProvider.toggleLessonPublishStatus(lesson.id, value);
                  },
                  activeColor: Colors.green,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'الإحصائيات',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'قريباً...',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(LessonModel lesson, AdminProvider adminProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف الدرس "${lesson.title}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await adminProvider.deleteLesson(lesson.id);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم حذف الدرس بنجاح')),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }
}
