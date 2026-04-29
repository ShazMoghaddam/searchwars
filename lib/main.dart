import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'data/dataset_loader.dart';
import 'screens/splash_screen.dart';
import 'services/sound_service.dart';
import 'theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppColors.background,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  await DatasetLoader.load();
  await SoundService.init(); // Load persisted mute preference
  runApp(const SearchWarsApp());
}

class SearchWarsApp extends StatelessWidget {
  const SearchWarsApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'SearchWars',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.dark,
    home: const SplashScreen(),
  );
}
