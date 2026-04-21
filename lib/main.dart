import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'features/calls/data/call_api_service.dart';
import 'features/calls/presentation/call_details_screen.dart';
import 'features/calls/presentation/call_qr_verify_screen.dart';
import 'features/calls/presentation/call_state.dart';
import 'features/calls/presentation/call_tracking_screen.dart';
import 'features/notifications/notification_service.dart';
import 'features/realtime/realtime_service.dart';
import 'screens/donation_history_screen.dart';
import 'screens/edit_profile_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/reset_password_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/signup_verification_screen.dart';
import 'services/api_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService.initToken();
  await NotificationService.instance.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) =>
              CallState(CallApiService(), RealtimeService())..loadActiveCall(),
        ),
      ],
      child: MaterialApp(
        navigatorKey: NotificationService.navigatorKey,
        debugShowCheckedModeBanner: false,
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        title: 'وريد',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.redAccent),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.redAccent,
            foregroundColor: Colors.white,
            centerTitle: true,
            elevation: 2,
          ),
        ),
        builder: (context, child) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: child ?? const SizedBox.shrink(),
          );
        },
        initialRoute: '/',
        routes: {
          '/': (context) => const LoginScreen(),
          '/signup': (context) => const SignUpScreen(),
          '/signup-verify': (context) {
            final args =
                ModalRoute.of(context)?.settings.arguments
                    as Map<String, dynamic>? ??
                const {};
            final email = (args['email'] as String?) ?? '';
            return SignUpVerificationScreen(email: email);
          },
          '/home': (context) => const HomeScreen(),
          '/edit-profile': (context) => const EditProfileScreen(),
          '/reset-password': (context) => const ResetPasswordScreen(),
          '/donation-history': (context) => const DonationHistoryScreen(),
        },
        onGenerateRoute: (settings) {
          if (settings.name == '/call-details') {
            final args =
                (settings.arguments as Map<String, dynamic>?) ?? const {};
            final callId = int.tryParse('${args['callId']}') ?? 0;
            return MaterialPageRoute(
              builder: (_) => CallDetailsScreen(callId: callId),
            );
          }

          if (settings.name == '/call-tracking') {
            final args =
                (settings.arguments as Map<String, dynamic>?) ?? const {};
            final callId = int.tryParse('${args['callId']}') ?? 0;
            return MaterialPageRoute(
              builder: (_) => CallTrackingScreen(callId: callId),
            );
          }

          if (settings.name == '/call-qr-verify') {
            final args =
                (settings.arguments as Map<String, dynamic>?) ?? const {};
            final callId = int.tryParse('${args['callId']}') ?? 0;
            return MaterialPageRoute(
              builder: (_) => CallQrVerifyScreen(callId: callId),
            );
          }

          return null;
        },
      ),
    );
  }
}
