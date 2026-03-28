import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart'; // Importante adicionar
import 'home_screen.dart';
import 'medicamento_provider.dart';
import 'notification_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'medicamento.dart';
import 'registro_tomada.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  await Supabase.initialize(
    url: "SaiDaqui",
    anonKey: "Saia",
  );

  await NotificationService().initNotification();

  runApp(
    ChangeNotifierProvider(
      create: (_) => MedicamentoProvider(),
      child: const MyApp(),
    ),
  );
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.teal,
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      home: const HomeScreen(),
    );
  }
}