import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/constants/app_colors.dart';
import 'core/constants/supabase_config.dart';
import 'core/theme/theme_controller.dart';
import 'features/auth/data/datasources/auth_remote_datasource.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/pages/register_page.dart';
import 'features/auth/presentation/pages/reset_password_page.dart';
import 'features/ticket/data/datasources/ticket_remote_datasource.dart';
import 'features/ticket/data/repositories/ticket_repository_impl.dart';
import 'features/ticket/presentation/bloc/ticket_bloc.dart';
import 'features/dashboard/presentation/pages/dashboard_page.dart';
import 'splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi Supabase
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );

  // Muat preferensi tema (light/dark/system) yang tersimpan sebelumnya
  await ThemeController.loadSavedTheme();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authRemote = AuthRemoteDataSource();
    final authRepo = AuthRepositoryImpl(authRemote);
    final ticketRemote = TicketRemoteDataSource();
    final ticketRepo = TicketRepositoryImpl(ticketRemote);

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AuthBloc(authRepo)),
        BlocProvider(create: (_) => TicketBloc(ticketRepo)),
      ],
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: ThemeController.themeMode,
        builder: (context, mode, _) {
          return MaterialApp(
            title: 'E-Ticketing Helpdesk',
            debugShowCheckedModeBanner: false,
            themeMode: mode,
            theme: AppColors.lightTheme,
            darkTheme: AppColors.darkTheme,
            initialRoute: '/splash',
            routes: {
              '/splash':         (_) => const SplashScreen(),
              '/login':          (_) => const LoginPage(),
              '/register':       (_) => const RegisterPage(),
              '/reset-password': (_) => const ResetPasswordPage(),
              '/dashboard':      (_) => const DashboardPage(),
            },
          );
        },
      ),
    );
  }
}