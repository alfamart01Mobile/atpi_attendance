import 'package:awesome_dialog/awesome_dialog.dart';

httpErrorDialog(context, title, message, onPressOk, onPressCancel) {
  AwesomeDialog(
    context: context,
    dialogType: DialogType.error,
    animType: AnimType.rightSlide,
    title: title,
    desc: message,
    btnOkOnPress: () async {
      onPressOk();
    },
    btnCancelText: 'Exit',
    btnCancelOnPress: () {
      onPressCancel();
    },
    btnOkText: 'Retry',
  ).show();
}

notRegisterDialog(context, title, message, onPressOk, onPressCancel) {
  AwesomeDialog(
      context: context,
      dialogType: DialogType.error,
      animType: AnimType.rightSlide,
      title: title,
      desc: message,
      btnOkText: 'Copy Device ID',
      btnOkOnPress: () async {
        onPressOk();
      },
      btnCancelText: 'Exit',
      btnCancelOnPress: () {
        onPressCancel();
      }).show();
}
