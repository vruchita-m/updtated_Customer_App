// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:service_mitra/bloc/notification_bloc/notification_state.dart';
// import 'package:service_mitra/config/data/model/notification_modal.dart';
// import 'package:service_mitra/config/data/repository/notification_repositry/notification_repositry.dart';
// import 'notification_count_cubit.dart';
//
// class NotificationCubit extends Cubit<NotificationState> {
//   NotificationRepositry notificationRepositry;
//   NotificationCubit(this.notificationRepositry) : super(NotificationInitial());
//
//   void loadNotifications(BuildContext context) async {
//     emit(NotificationLoading());
//     try {
//       final notifications =
//       await notificationRepositry.fetchNotifications(context);
//
//       // Sync Logic: unseen notifications ko gino
//       final unseenCount = notifications.where((n) => !(n.seen ?? false)).length;
//       // Aur NotificationCountCubit ko update kar do
//       context.read<NotificationCountCubit>().updateCount(unseenCount);
//
//       emit(NotificationLoaded(notifications));
//     } catch (e) {
//       emit(NotificationError("Failed to load notifications"));
//     }
//   }
//
//   // Jab user kisi ek notification par tap karega
//   void handleNotificationTap(NotificationResults notification, BuildContext context) async {
//     bool wasUnseen = !(notification.seen ?? false);
//
//     if (wasUnseen) {
//       context.read<NotificationCountCubit>().decrement();
//     }
//
//     if (state is NotificationLoaded) {
//       final currentState = state as NotificationLoaded;
//       final updatedList = currentState.notifications.map((n) {
//         if (n.id == notification.id) {
//           return NotificationResults(
//             id: n.id,
//             userId: n.userId,
//             notificationtitle: n.notificationtitle,
//             notificationbody: n.notificationbody,
//             ticketId: n.ticketId,
//             seen: true, // seen ko true set kar do
//             createdAt: n.createdAt,
//           );
//         }
//         return n;
//       }).toList();
//       emit(NotificationLoaded(updatedList));
//     }
//   }
// }



import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:service_mitra/bloc/notification_bloc/notification_state.dart';
import 'package:service_mitra/config/data/model/notification_modal.dart';
import 'package:service_mitra/config/data/repository/notification_repositry/notification_repositry.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_count_cubit.dart';

class NotificationCubit extends Cubit<NotificationState> {
  NotificationRepositry notificationRepositry;
  NotificationCubit(this.notificationRepositry) : super(NotificationInitial());

  static const _seenNotificationsKey = 'seen_notifications';

  void loadNotifications(BuildContext context) async {
    emit(NotificationLoading());
    try {

      final serverNotifications =
      await notificationRepositry.fetchNotifications(context);

      final prefs = await SharedPreferences.getInstance();
      final seenIds = prefs.getStringList(_seenNotificationsKey) ?? [];

      final updatedNotifications = serverNotifications.map((notification) {

        if (seenIds.contains(notification.id)) {
          return NotificationResults(
            id: notification.id,
            userId: notification.userId,
            notificationtitle: notification.notificationtitle,
            notificationbody: notification.notificationbody,
            ticketId: notification.ticketId,
            seen: true,
            createdAt: notification.createdAt,
          );
        }
        return notification;
      }).toList();

      updatedNotifications.sort((a, b) {
        DateTime? dateA = a.createdAt != null ? DateTime.tryParse(a.createdAt!) : null;
        DateTime? dateB = b.createdAt != null ? DateTime.tryParse(b.createdAt!) : null;

        if (dateB == null) return -1;
        if (dateA == null) return 1;
        return dateB.compareTo(dateA);
      });

      final unseenCount = updatedNotifications.where((n) => !(n.seen ?? false)).length;
      context.read<NotificationCountCubit>().updateCount(unseenCount);

      emit(NotificationLoaded(updatedNotifications));
    } catch (e) {
      emit(NotificationError("Failed to load notifications"));
    }
  }

  void handleNotificationTap(NotificationResults notification, BuildContext context) async {
    bool wasUnseen = !(notification.seen ?? false);

    if (wasUnseen) {
      context.read<NotificationCountCubit>().decrement();

      if (notification.id != null) {
        final prefs = await SharedPreferences.getInstance();
        final seenIds = prefs.getStringList(_seenNotificationsKey) ?? [];
        if (!seenIds.contains(notification.id!)) {
          seenIds.add(notification.id!);
          await prefs.setStringList(_seenNotificationsKey, seenIds);
        }
      }
    }

    if (state is NotificationLoaded) {
      final currentState = state as NotificationLoaded;
      final updatedList = currentState.notifications.map((n) {
        if (n.id == notification.id) {
          return NotificationResults(
            id: n.id,
            userId: n.userId,
            notificationtitle: n.notificationtitle,
            notificationbody: n.notificationbody,
            ticketId: n.ticketId,
            seen: true,
            createdAt: n.createdAt,
          );
        }
        return n;
      }).toList();
      emit(NotificationLoaded(updatedList));
    }
  }
}