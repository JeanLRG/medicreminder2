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
    url: 'https://okqjugerjvxupcfntssq.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9rcWp1Z2VyanZ4dXBjZm50c3NxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njc4NTMxNDEsImV4cCI6MjA4MzQyOTE0MX0.EMS_M73dbVaaOZO4tI5WGDeEVwkOYt6I0fUkQoEX354',
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