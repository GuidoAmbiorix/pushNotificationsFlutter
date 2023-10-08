part of 'notifications_bloc.dart';

abstract class NotificationsEvent {
  const NotificationsEvent();
}

class NotificationStatusChange extends NotificationsEvent {
  final AuthorizationStatus status;
  NotificationStatusChange(this.status);
}

class NotificationRecieved extends NotificationsEvent {
  final PushMessage pushMessage;
  NotificationRecieved(this.pushMessage);
}
