import 'package:flutter/foundation.dart'
    show debugDefaultTargetPlatformOverride;
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:sip_ua/sip_ua.dart';

import 'src/callscreen.dart';
import 'src/dialpad.dart';
import 'foreground_service.dart';

Call? callCome;
SIPUAHelperSingleton sipHelperSingleton = SIPUAHelperSingleton();

GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  print('main()');
  WidgetsFlutterBinding.ensureInitialized();
  Logger.level = Level.warning;
  if (WebRTC.platformIsDesktop) {
    debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;
  }
  // LocalNotificationService().init();
  //registerSip();

  await initializeService();

  runApp(MyApp());
}

typedef PageContentBuilder = Widget Function(
    [SIPUAHelper? helper, Object? arguments]);

// ignore: must_be_immutable
class MyApp extends StatelessWidget {
  Map<String, PageContentBuilder> routes = {
    '/': ([SIPUAHelper? helper, Object? arguments]) => DialPadWidget(helper),
    '/callscreen': ([SIPUAHelper? helper, Object? arguments]) =>
        CallScreenWidget(helper, arguments as Call?),
  };

  Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    final String? name = settings.name;
    final PageContentBuilder? pageContentBuilder = routes[name!];
    if (pageContentBuilder != null) {
      if (settings.arguments != null) {
        final Route route = MaterialPageRoute<Widget>(
            builder: (context) => pageContentBuilder(
                sipHelperSingleton.helper, settings.arguments));
        return route;
      } else {
        final Route route = MaterialPageRoute<Widget>(
            builder: (context) =>
                pageContentBuilder(sipHelperSingleton.helper));
        return route;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Flutter Demo',
      initialRoute: '/',
      onGenerateRoute: _onGenerateRoute,
    );
  }
}
