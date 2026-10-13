import 'package:flutter/widgets.dart';
import 'ota_update_controller.dart';

class OtaUpdateScope extends InheritedNotifier<OtaUpdateController> {
  const OtaUpdateScope(
      {super.key,
      required OtaUpdateController controller,
      required super.child})
      : super(notifier: controller);
  static OtaUpdateController? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<OtaUpdateScope>()?.notifier;
}
