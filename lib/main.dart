import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'src/core/database_service.dart';
import 'src/view/home_view.dart';

final dbService = DatabaseService();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FluentApp(
      debugShowCheckedModeBanner: false,
      title: 'Gemini App',
      theme: FluentThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF212121),
      ),
      home: HomeView(databaseService: dbService),
    );
  }
}
