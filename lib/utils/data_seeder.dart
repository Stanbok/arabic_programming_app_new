import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart'; // لو عندك ملف Firebase Options

class DataSeeder {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> seedLesson1() async {
    final lessonData = {
      "id": "lesson_1",
      "title": "مقدمة في بايثون",
      "description": "ابدأ تعلم لغة بايثون بأسلوب مبسط وتدريجي. في هذا الدرس، ستتعرف على أساسيات اللغة وتكتب أول برنامج لك.",
      "imageUrl": "https://en.wikipedia.org/wiki/File:Python-logo-notext.svg",
      "level": 1,
      "order": 1,
      "xpReward": 50,
      "gemsReward": 2,
      "isPublished": true,
      "estimatedDuration": 15,
      "difficulty": "easy",
      "tags": ["مبتدئ", "أساسيات", "بايثون"],
      "prerequisites": [],
      "slides": [
        {
          "id": "slide_1_1",
          "title": "ما هي لغة بايثون؟",
          "content": "بايثون هي لغة برمجة مشهورة وسهلة الاستخدام. تم تطويرها عام 1991 بواسطة Guido van Rossum. تتميز ببساطة كتابتها ووضوحها، وهي مناسبة جدًا للمبتدئين.\n\nتُستخدم بايثون في مجالات كثيرة، مثل:\n• تطوير المواقع\n• الذكاء الاصطناعي وتعلم الآلة\n• تحليل البيانات\n• أتمتة المهام\n• تطوير الألعاب",
          "imageUrl": "https://en.wikipedia.org/wiki/File:Guido_van_Rossum_in_PyConUS24_(cropped).jpg",
          "order": 1,
          "type": "text"
        },
        {
          "id": "slide_1_2",
          "title": "لماذا تُعتبر بايثون خيارًا جيدًا؟",
          "content": "هناك عدة أسباب تجعل بايثون خيارًا رائعًا لمن يبدأ في البرمجة:\n\n1. **سهلة التعلم**: الكتابة فيها بسيطة وواضحة.\n2. **دعم كبير**: يوجد مجتمع ضخم من المطورين ومصادر تعليمية كثيرة.\n3. **مكتبات جاهزة**: تتوفر مكتبات تساعد في إنجاز المهام بسرعة.\n4. **فرص العمل**: مطلوبة في الكثير من الشركات.\n5. **تعدد الاستخدامات**: تُستخدم في مختلف المجالات التقنية.",
          "order": 2,
          "type": "text"
        },
        {
          "id": "slide_1_3",
          "title": "أول برنامج لك في بايثون",
          "content": "من العادات الشائعة عند تعلم أي لغة برمجة أن نبدأ بكتابة برنامج بسيط يقوم بطباعة جملة على الشاشة.\n\nفي بايثون، يمكن كتابة البرنامج التالي:",
          "codeExample": "print(\"Hello, World!\")",
          "order": 3,
          "type": "code"
        },
        {
          "id": "slide_1_4",
          "title": "شرح الكود",
          "content": "هذا السطر يقوم بطباعة النص الموجود بين علامتي التنصيص.\n\n• `print()` هي دالة مدمجة في بايثون.\n• نضع داخل الأقواس النص الذي نريد طباعته.\n• يجب وضع النص بين علامتي تنصيص مزدوجتين أو مفردتين.\n\nكل سطر في بايثون يُنفّذ بشكل مستقل، من الأعلى إلى الأسفل.",
          "order": 4,
          "type": "text"
        },
        {
          "id": "slide_1_5",
          "title": "أمثلة إضافية",
          "content": "لنجرّب طباعة أنواع مختلفة من البيانات:",
          "codeExample": "// طباعة نص\nprint(\"My name is Sara\")\n\n// طباعة أرقام\nprint(100)\nprint(3.14)\n\n// طباعة أكثر من عنصر في نفس السطر\nprint(\"Age:\", 20, \"years\")\n\n// طباعة سطر فارغ\nprint()",
          "order": 5,
          "type": "code"
        }
      ],
      "quiz": [
        {
          "question": "من هو مؤسس لغة بايثون؟",
          "options": [
            "Bill Gates",
            "Guido van Rossum",
            "Mark Zuckerberg",
            "Steve Jobs"
          ],
          "correctAnswerIndex": 1,
          "explanation": "Guido van Rossum هو مطور لغة بايثون، وأطلقها في عام 1991.",
          "difficulty": "easy",
          "points": 10
        },
        {
          "question": "ما هي الدالة المستخدمة لطباعة نص في بايثون؟",
          "options": [
            "show()",
            "display()",
            "print()",
            "write()"
          ],
          "correctAnswerIndex": 2,
          "explanation": "الدالة print() تُستخدم لطباعة النصوص والقيم على الشاشة.",
          "difficulty": "easy",
          "points": 10
        },
        {
          "question": "أي من هذه الأمثلة صحيح لطباعة كلمة Hello؟",
          "options": [
            "print(Hello)",
            "print('Hello')",
            "show('Hello')",
            "display(Hello)"
          ],
          "correctAnswerIndex": 1,
          "explanation": "النصوص يجب أن توضع داخل علامات تنصيص، مثل 'Hello'.",
          "difficulty": "easy",
          "points": 10
        }
      ],
      "createdAt": "2024-01-15T10:00:00Z",
      "updatedAt": "2024-01-15T10:00:00Z",
      "createdBy": "admin"
    };

    try {
      await _firestore.collection('lessons').doc('lesson_1').set(lessonData);
      print('✅ تم رفع بيانات الدرس lesson_1 بنجاح!');
    } catch (e) {
      print('❌ حدث خطأ أثناء رفع البيانات: $e');
    }
  }
}

// هذا الجزء المهم لتشغيل الدالة تلقائيًا
Future<void> main() async {
  // تأكد إن Firebase متفعّل
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await DataSeeder.seedLesson1();
}
