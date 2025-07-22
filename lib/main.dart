import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tap_payment/flutter_tap_payment.dart';
import 'package:tgl_final_with_user_staff/screens/addmeeting.dart';
import 'package:tgl_final_with_user_staff/screens/coffee.dart';
import 'package:tgl_final_with_user_staff/screens/dashboard.dart';
import 'package:tgl_final_with_user_staff/screens/meeting.dart';
import 'package:tgl_final_with_user_staff/screens/password_screen.dart';
import 'package:tgl_final_with_user_staff/screens/upload_civil_id.dart';
import 'package:tgl_final_with_user_staff/screens/board_games.dart';
import 'package:tgl_final_with_user_staff/screens/food.dart';
import 'package:tgl_final_with_user_staff/screens/home_screen.dart';
import 'package:tgl_final_with_user_staff/screens/library.dart';
import 'package:tgl_final_with_user_staff/screens/login_screen.dart';
import 'package:tgl_final_with_user_staff/screens/multiconsole.dart';
import 'package:tgl_final_with_user_staff/screens/museum.dart';
import 'package:tgl_final_with_user_staff/screens/onboard_screen.dart';
import 'package:tgl_final_with_user_staff/screens/register_screen.dart';
import 'package:tgl_final_with_user_staff/screens/verify_otp_screen.dart';
import 'package:http/http.dart' as http;
import 'package:tgl_final_with_user_staff/user/buy_hours.dart';
import 'package:tgl_final_with_user_staff/user/transactions.dart';
import 'package:provider/provider.dart';
import 'package:go_sell_sdk_flutter/go_sell_sdk_flutter.dart';
class UserProvider extends ChangeNotifier {
  String? userId;
  void setUserId(String? id) {
    userId = id;
    notifyListeners();
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  GoSellSdkFlutter.configureApp(
      bundleId: "me.celebr8.client",
      productionSecretKey: "sk_live_FVTkiZcAuDPfeo7Gj8USRLdQ",
      sandBoxSecretKey: "sk_test_FCWuk5visAyod7S3BnxIK9VZ",
      lang: "en"
  );
  // Initialize Tap SDK for TEST mode
  // FlutterTapPayment.configure(
  //   publicKey: 'pk_test_Wt7dDTfp5swSLVqMANyJnFKb',
  //   secretKey: 'sk_test_xGIJVesm8NrQ4FhC6jMEg30y',
  //   returnUrl: 'myapp://payment-callback',
  //   environment: TapEnvironment.SANDBOX, // Use SANDBOX for testing
  // );

  runApp(
    ChangeNotifierProvider(
      create: (_) => UserProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  String? mobile;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeMobile();
  }

  Future<void> _initializeMobile() async {
    final prefs = await SharedPreferences.getInstance();
    mobile = prefs.getString('mobile');
    if (mobile != null) {
      _setOnlineStatus(1);
    }
  }

  @override
  void dispose() {
    _setOnlineStatus(0);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (mobile == null) return;
    if (state == AppLifecycleState.resumed) {
      _setOnlineStatus(1);
    } else {
      _setOnlineStatus(0);
    }
  }

  Future<void> _setOnlineStatus(int status) async {
    if (mobile == null) return;
    await http.post(
      Uri.parse('https://tgl.inchrist.co.in/set_online_status.php'),
      body: {
        'mobile': mobile!,
        'status': status.toString(),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(

        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      routes: {
        '/onboard': (context) => const OnboardScreen(),
        '/login': (context) => const LoginScreen(),
        '/password': (context) =>  PasswordScreen(),
        '/home': (context) => HomeScreen(userId: Provider.of<UserProvider>(context).userId),
        '/buy_hours': (context) => BuyHoursScreen(userId: Provider.of<UserProvider>(context).userId),
        '/staffDashboard': (context) => const StaffDashboard(),
        '/museum': (context) => const MuseumScreen(),
        '/food': (context) => const FoodScreen(),
        '/profile': (context) => const FoodScreen(),
        '/console': (context) => const MultiConsoleScreen(),
        '/coffee': (context) => const CoffeeBeansScreen(),
        '/meeting': (context) => const MeetingPage(),
        '/add': (context) => const AddMeetingPage(),
        '/board': (context) => const BoardGamesScreen(),
        '/library': (context) => const LibraryScreen(),
        '/transactions': (context) => TransactionsPage(userId: Provider.of<UserProvider>(context).userId),
        '/uploadCivilId': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map;
          return UploadCivilIdScreen(mobile: args['mobile']);
        },
        '/register': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map;
          return RegisterScreen(mobile: args['mobile']);
        },
        '/verify': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map;
          return VerifyOtpScreen(mobile: args['mobile']);
        },
      },
      home: const SplashWrapper(),
    );
  }
}


class SplashWrapper extends StatefulWidget {
  const SplashWrapper({super.key});

  @override
  State<SplashWrapper> createState() => _SplashWrapperState();
}

class _SplashWrapperState extends State<SplashWrapper> {
  String? userType;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    final staffId = prefs.getString('staff_id');

    if (userId != null) {
      userType = 'user';
      Provider.of<UserProvider>(context, listen: false).setUserId(userId);
    } else if (staffId != null) {
      userType = 'staff';
    } else {
      userType = null;
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) {
        if (userType == 'user') {
          return HomeScreen(userId: Provider.of<UserProvider>(context, listen: false).userId);
        } else if (userType == 'staff') {
          return const MuseumScreen(); // Assuming staff lands on Museum
        } else {
          return const OnboardScreen();
        }
      },
    ));
  }
  void initTapSdk() {


  }
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
