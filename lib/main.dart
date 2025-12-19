import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'core/services/auth_service.dart';
import 'core/services/firestore_service.dart';
import 'core/services/connectivity_service.dart';
import 'core/services/cache_service.dart';
import 'features/onboarding/screens/splash_screen.dart';
import 'features/dev/dev_seeder_screen.dart';

const bool kShowDevSeeder = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp();
  await Hive.initFlutter();
  await CacheService.init();
  
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<FirestoreService>(create: (_) => FirestoreService()),
        ChangeNotifierProvider<ConnectivityService>(
          create: (_) => ConnectivityService(),
        ),
      ],
      child: MaterialApp(
        title: 'تعلم بايثون',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        locale: const Locale('ar'),
        builder: (context, child) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: child!,
          );
        },
        home: kShowDevSeeder ? const DevSeederScreen() : const SplashScreen(),
      ),
    );
  }
}
