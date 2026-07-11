import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:sello/app.dart';
import 'package:sello/core/config/env.dart';
import 'package:sello/core/config/supabase_config.dart';
import 'package:sello/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Env.load();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await SupabaseConfig.initialize();
  runApp(const SelloApp());
}
