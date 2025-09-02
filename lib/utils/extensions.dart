import 'package:check_in/utils/enum.dart';
import 'package:flutter/material.dart';

extension ScreenSize on BuildContext {
  get height => MediaQuery.of(this).size.height;

  get width => MediaQuery.of(this).size.width;
}

extension WorkDuration on DateTime {
  String workDuration(DateTime endTime) {
    final duration = endTime.difference(this);

    if (duration.inHours >= 1) {
      return "Your total work hour: ${duration.inHours} hour${duration.inHours > 1 ? 's' : ''}";
    } else {
      return "Your total work minute: ${duration.inMinutes} minute${duration.inMinutes > 1 ? 's' : ''}";
    }
  }
}

extension UserTypeExt on String {
  UserType get getUserType {
    switch (this) {
      case "Admin":
        return UserType.Admin;
      case "User":
        return UserType.RegularUser;
      default:
        return UserType.RegularUser;
    }
  }
}
