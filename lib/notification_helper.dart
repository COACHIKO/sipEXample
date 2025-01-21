import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:sip_ua/sip_ua.dart';

import '../../main.dart';

Call? callG;

class LocalNotificationService
    implements SipUaHelperListener, WidgetsBindingObserver {
  static FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  void _bindEventListeners() {
    sipHelperSingleton.helper.addSipUaHelperListener(this);
  }

  Future<void> init() async {
    _bindEventListeners();
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );

    await flutterLocalNotificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: onTap,
    );
  }

  static void onTap(NotificationResponse notificationResponse) {
    if (notificationResponse.payload == 'stateCheck') {
      print('stateCheck');
    }
    if (notificationResponse.payload == 'incoming_call') {
      navigatorKey.currentState!.pushNamed('/callscreen', arguments: callG);

      print('incoming call');
    }
  }

  static void showRepeatedNotification() async {
    const AndroidNotificationDetails android = AndroidNotificationDetails(
      'id 2',
      'repeated notification',
      importance: Importance.max,
      priority: Priority.high,
    );
    NotificationDetails details = const NotificationDetails(
      android: android,
    );
    await flutterLocalNotificationsPlugin.periodicallyShow(
      1,
      'Reapated Notification',
      'body',
      RepeatInterval.daily,
      details,
      payload: "Payload Data",
      androidScheduleMode: AndroidScheduleMode.alarmClock,
    );
  }

  static Future<void> cancelNotification() async {
    await flutterLocalNotificationsPlugin.cancel(0);
  }

  static Future<void> showSimpleNotification({
    required String title,
    required String body,
    required String payload,
  }) async {
    const notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails('egytel-id', 'egytel-name',
          importance: Importance.max,
          priority: Priority.max,
          category: AndroidNotificationCategory.call,
          fullScreenIntent: true,
          ongoing: true,
          playSound: true),
    );

    await flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      notificationDetails,
      payload: payload,
    );

    // Keep the service alive
    await keepServiceAlive();
  }

  static Future<void> keepServiceAlive() async {
    const AndroidNotificationDetails android = AndroidNotificationDetails(
      'my_foreground',
      'MY FOREGROUND SERVICE',
      importance: Importance.max,
      priority: Priority.high,
      ongoing: true,
      playSound: true,
    );
    const NotificationDetails details = NotificationDetails(
      android: android,
    );
    await flutterLocalNotificationsPlugin.show(
      888,
      'Service Alive',
      'The foreground service is running',
      details,
    );
  }

  static Future<void> connectionStateNotif() async {
    const AndroidNotificationDetails android = AndroidNotificationDetails(
      'my_foreground',
      'MY FOREGROUND SERVICE',
      importance: Importance.max,
      priority: Priority.high,
      ongoing: true,
      playSound: true,
    );
    const NotificationDetails details = NotificationDetails(
      android: android,
    );
    await flutterLocalNotificationsPlugin.show(
      888,
      'Service Alive',
      'The foreground service is running',
      details,
    );
  }

  static Future<void> pert({
    required String title,
    required String body,
    required String payload,
  }) async {
    const notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails('egytelss', 'egytel-name',
          importance: Importance.max,
          priority: Priority.max,
          category: AndroidNotificationCategory.call,
          fullScreenIntent: true,
          ongoing: true,
          playSound: true),
    );

    await flutterLocalNotificationsPlugin.periodicallyShow(
      1,
      title,
      body,
      RepeatInterval.everyMinute,
      notificationDetails,
      payload: payload,
      androidScheduleMode: AndroidScheduleMode.alarmClock,
    );
  }

  @override
  void callStateChanged(Call call, CallState state) {
    if (state.state == CallStateEnum.CALL_INITIATION) {
      showSimpleNotification(
          title: "Incoming Call",
          body: call.remote_display_name!,
          payload: "incoming_call");
    } else if (state.state == CallStateEnum.FAILED) {
      cancelNotification();
    }
  }

  @override
  void onNewMessage(SIPMessageRequest msg) {
    // TODO: implement onNewMessage
  }

  @override
  void onNewNotify(Notify ntf) {
    // TODO: implement onNewNotify
  }

  @override
  void onNewReinvite(ReInvite event) {
    // TODO: implement onNewReinvite
  }

  @override
  void registrationStateChanged(RegistrationState state) {
    print('Registration state changed: ${state.state}');
    pert(
        title: "Current State",
        body: state.state.toString(),
        payload: "stateCheck");
  }

  @override
  void transportStateChanged(TransportState state) {
    // TODO: implement transportStateChanged
  }

  @override
  void didChangeAccessibilityFeatures() {
    // TODO: implement didChangeAccessibilityFeatures
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    state == AppLifecycleState.resumed
        ? cancelNotification()
        : print('App is in background');
  }

  @override
  void didChangeLocales(List<Locale>? locales) {
    // TODO: implement didChangeLocales
  }

  @override
  void didChangeMetrics() {
    // TODO: implement didChangeMetrics
  }

  @override
  void didChangePlatformBrightness() {
    // TODO: implement didChangePlatformBrightness
  }

  @override
  void didChangeTextScaleFactor() {
    // TODO: implement didChangeTextScaleFactor
  }

  @override
  void didChangeViewFocus(ViewFocusEvent event) {
    // TODO: implement didChangeViewFocus
  }

  @override
  void didHaveMemoryPressure() {
    // TODO: implement didHaveMemoryPressure
  }

  @override
  Future<bool> didPopRoute() {
    // TODO: implement didPopRoute
    throw UnimplementedError();
  }

  @override
  Future<bool> didPushRoute(String route) {
    // TODO: implement didPushRoute
    throw UnimplementedError();
  }

  @override
  Future<bool> didPushRouteInformation(RouteInformation routeInformation) {
    // TODO: implement didPushRouteInformation
    throw UnimplementedError();
  }

  @override
  Future<AppExitResponse> didRequestAppExit() {
    // TODO: implement didRequestAppExit
    throw UnimplementedError();
  }

  @override
  void handleCancelBackGesture() {
    // TODO: implement handleCancelBackGesture
  }

  @override
  void handleCommitBackGesture() {
    // TODO: implement handleCommitBackGesture
  }

  @override
  bool handleStartBackGesture(PredictiveBackEvent backEvent) {
    // TODO: implement handleStartBackGesture
    throw UnimplementedError();
  }

  @override
  void handleUpdateBackGestureProgress(PredictiveBackEvent backEvent) {
    // TODO: implement handleUpdateBackGestureProgress
  }
}
