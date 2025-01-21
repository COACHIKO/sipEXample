import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:dart_sip_ua_example/main.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:sip_ua/sip_ua.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';

extension CallExtension on Call {
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'remote_display_name': remote_display_name,
      'remote_identity': remote_identity.toString(),
      'state': state.toString(),
    };
  }
}

final StreamController<Call> callStreamController =
    StreamController<Call>.broadcast();

Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'my_foreground',
    'MY FOREGROUND SERVICE',
    description: 'This channel is used for important notifications.',
    importance: Importance.low,
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  if (Platform.isIOS || Platform.isAndroid) {
    await flutterLocalNotificationsPlugin.initialize(
      const InitializationSettings(
        iOS: DarwinInitializationSettings(),
        android: AndroidInitializationSettings('ic_bg_service_small'),
      ),
    );
  }

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      isForegroundMode: true,
      autoStartOnBoot: true,
      notificationChannelId: 'my_foreground',
      initialNotificationTitle: 'AWESOME SERVICE',
      initialNotificationContent: 'Initializing',
      foregroundServiceNotificationId: 888,
      foregroundServiceTypes: [AndroidForegroundType.dataSync],
    ),
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  SharedPreferences preferences = await SharedPreferences.getInstance();
  await preferences.reload();
  final log = preferences.getStringList('log') ?? <String>[];
  log.add(DateTime.now().toIso8601String());
  await preferences.setStringList('log', log);
  return true;
}

class SIPUAHelperSingleton implements SipUaHelperListener {
  static final SIPUAHelperSingleton _instance =
      SIPUAHelperSingleton._internal();
  late SIPUAHelper helper = SIPUAHelper();

  factory SIPUAHelperSingleton() {
    return _instance;
  }

  SIPUAHelperSingleton._internal() {
    helper.addSipUaHelperListener(this);
  }

  @override
  void callStateChanged(Call call, CallState state) {
    if (state.state == CallStateEnum.CALL_INITIATION) {
      callCome = call;
      _showIncomingCall(call);
    } else if (state.state == CallStateEnum.FAILED) {
      callCome = null;
      FlutterCallkitIncoming.endAllCalls();
    }
  }

  void _showIncomingCall(Call call) async {
    final params = CallKitParams(
      id: call.id,
      nameCaller: call.remote_display_name,
      appName: 'Hatif',
      handle: call.remote_identity.toString(),
      type: 0,
      duration: 30000,
      textAccept: 'Accept',
      textDecline: 'Decline',
    );
    await FlutterCallkitIncoming.showCallkitIncoming(params);
  }

  @override
  void onNewMessage(SIPMessageRequest msg) {}

  @override
  void onNewNotify(Notify ntf) {}

  @override
  void onNewReinvite(ReInvite event) {}

  @override
  void registrationStateChanged(RegistrationState state) {}

  @override
  void transportStateChanged(TransportState state) {}
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  SharedPreferences preferences = await SharedPreferences.getInstance();
  await preferences.setString("hello", "world");
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  service.on('getHelper').listen((event) {
    service.invoke('getHelper', {'helper': sipHelperSingleton.helper});
  });

  callStreamController.stream.listen((call) {
    service.invoke('incomingCall', {'call': call});
  }, onError: (error) {
    print('Error occurred while processing the stream: $error');
  }, onDone: () {
    print('Stream is done.');
  });

  Timer.periodic(const Duration(seconds: 1), (timer) async {
    SIPUAHelper helper = sipHelperSingleton.helper;
    sipHelperSingleton.helper = helper;

    if (helper.registerState.state == null ||
        helper.registerState.state != RegistrationStateEnum.REGISTERED) {
      registerSip();
    } else {
      print('SIPUAHelper is already registered');
    }
    if (service is AndroidServiceInstance) {
      if (await service.isForegroundService()) {
        flutterLocalNotificationsPlugin.show(
          888,
          'Greetings COACHIKO',
          'Connection state : ${helper.registerState.state?.name}',
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'my_foreground',
              'MY FOREGROUND SERVICE',
              icon: 'ic_bg_service_small',
              ongoing: true,
              playSound: true,
            ),
          ),
        );
      }
    }

    debugPrint('FLUTTER BACKGROUND SERVICE: ${DateTime.now()}');

    final deviceInfo = DeviceInfoPlugin();
    String? device;
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      device = androidInfo.model;
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      device = iosInfo.model;
    }
    service.invoke(
      'update',
      {
        "current_date": DateTime.now().toIso8601String(),
        "device": device,
        "registration_state": helper.registerState.state?.name,
      },
    );
  });

  FlutterCallkitIncoming.onEvent.listen((CallEvent? event) {
    switch (event!.event) {
      case Event.actionCallIncoming:
        break;
      case Event.actionCallStart:
        break;
      case Event.actionCallAccept:
        break;
      case Event.actionCallDecline:
        break;
      case Event.actionCallEnded:
        break;
      case Event.actionCallTimeout:
        break;
      case Event.actionCallCallback:
        break;
      case Event.actionCallToggleHold:
        break;
      case Event.actionCallToggleMute:
        break;
      case Event.actionCallToggleDmtf:
        break;
      case Event.actionCallToggleGroup:
        break;
      case Event.actionCallToggleAudioSession:
        break;
      case Event.actionDidUpdateDevicePushTokenVoip:
        break;
      case Event.actionCallCustom:
        break;
    }
  });
}

void registerSip() {
  UaSettings settings = UaSettings();

  settings.port = "8089";
  settings.webSocketSettings.extraHeaders = {};
  settings.webSocketSettings.allowBadCertificate = true;
  settings.webSocketSettings.userAgent = 'Hatif';
  settings.tcpSocketSettings.allowBadCertificate = true;
  settings.transportType = TransportType.WS;
  settings.uri = "991001@dev1.egytelecoms.com";
  settings.webSocketUrl = "wss://dev1.egytelecoms.com:8089/ws";
  settings.host = "991001@dev1.egytelecoms.com".split('@')[1];
  settings.authorizationUser = "991001";
  settings.password = "ac49d0b1a58dbf3f58f132d645f5c79c";
  settings.displayName = "COACHIKO";
  settings.userAgent = 'Hatif MobileApp';
  settings.dtmfMode = DtmfMode.RFC2833;
  settings.contact_uri = 'sip:1001@dev1.egytelecoms.com';
  sipHelperSingleton.helper.start(settings);
  sipHelperSingleton.helper.register();
}
