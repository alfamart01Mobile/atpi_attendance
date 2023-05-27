import 'package:flutter/foundation.dart';

class MyImageProvider with ChangeNotifier, DiagnosticableTreeMixin {
  String _imgPath = '';

  String get imgPath => _imgPath;

  void setImgPath(String path) {
    _imgPath = path;
    notifyListeners();
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('imagePath', _imgPath));
  }
}
