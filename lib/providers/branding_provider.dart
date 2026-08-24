import 'package:flutter/foundation.dart';

import '../models/branding_model.dart';
import '../services/database_service.dart';

class BrandingProvider extends ChangeNotifier {
  BrandingModel _branding = BrandingModel();

  BrandingModel get branding => _branding;

  void updateBranding(BrandingModel newBranding) {
    _branding = newBranding;
    notifyListeners();
    DatabaseService.instance.saveDocument('branding', 'main_branding', _branding.toMap());
  }

  void updateColors({required int primaryColor, required int accentColor}) {
    _branding = _branding.copyWith(
      primaryColorValue: primaryColor,
      accentColorValue: accentColor,
    );
    notifyListeners();
    DatabaseService.instance.saveDocument('branding', 'main_branding', _branding.toMap());
  }

  void updateLogo(String logoPath) {
    _branding = _branding.copyWith(logoPath: logoPath);
    notifyListeners();
    DatabaseService.instance.saveDocument('branding', 'main_branding', _branding.toMap());
  }

  void updateOwnerPhoto(String photoPath) {
    _branding = _branding.copyWith(ownerPhotoPath: photoPath);
    notifyListeners();
    DatabaseService.instance.saveDocument('branding', 'main_branding', _branding.toMap());
  }
}
