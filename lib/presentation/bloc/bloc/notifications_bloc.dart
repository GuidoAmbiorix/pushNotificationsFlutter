import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:push_notifications/domain/entities/push_message.dart';

import '../../../firebase_options.dart';

// import '../../../firebase_options.dart';

part 'notifications_event.dart';
part 'notifications_state.dart';

Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");
}

class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  NotificationsBloc() : super(const NotificationsState()) {
    on<NotificationStatusChange>(_notificationStatusChanged);
    on<NotificationRecieved>(_onPushMessageRecieved);

    // Verificar estado de las notificaciones
    _initialStatusChecked();

    // Listener para notificaciones en foreground
    _onForegroundMessage();
  }

  static Future<void> initializeFirebaseNotification() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  void _notificationStatusChanged(
      NotificationStatusChange event, Emitter<NotificationsState> emit) {
    emit(state.copyWith(status: event.status));
    _getFCMToken();
  }

  void _onPushMessageRecieved(
      NotificationRecieved event, Emitter<NotificationsState> emit) {
    emit(
      state.copyWith(
        notifications: [event.pushMessage, ...state.notifications],
      ),
    );
  }

  void _initialStatusChecked() async {
    final settings = await messaging.getNotificationSettings();
    add(NotificationStatusChange(settings.authorizationStatus));
  }

  void _getFCMToken() async {
    final settgins = await messaging.getNotificationSettings();
    if (settgins.authorizationStatus != AuthorizationStatus.authorized) return;

    final token = await messaging.getToken();
  }

  void _handleRemoteMessage(RemoteMessage message) {
    if (message.notification == null) return;
    final notification = PushMessage(
      messageId:
          message.messageId?.replaceAll(':', '').replaceAll('%', '') ?? '',
      title: message.notification!.title ?? '',
      body: message.notification!.body ?? '',
      sentDate: message.sentTime ?? DateTime.now(),
      data: message.data,
      imageUrl: Platform.isAndroid
          ? message.notification!.android?.imageUrl
          : message.notification!.apple?.imageUrl,
    );
    add(NotificationRecieved(notification));
  }

  void _onForegroundMessage() {
    FirebaseMessaging.onMessage.listen(_handleRemoteMessage);
  }

  void requstPermission() async {
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    add(NotificationStatusChange(settings.authorizationStatus));

    settings.authorizationStatus;
  }
}
