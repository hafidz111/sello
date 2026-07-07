import 'package:flutter/material.dart';
import 'package:sello/app.dart';
import 'package:sello/core/config/env.dart';
import 'package:sello/core/config/supabase_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Env.load();
  await SupabaseConfig.initialize();
  runApp(const SelloApp());
}
