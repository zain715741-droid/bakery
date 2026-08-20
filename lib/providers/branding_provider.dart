import 'package:flutter/foundation.dart';
import '../models/branding_model.dart';

class BrandingProvider extends ChangeNotifier {
  BrandingModel _branding = BrandingModel();

  BrandingModel get branding => _branding;

  void updateBranding(BrandingModel newBranding) {
    _branding = newBranding;
    notifyListeners();
  }

  void updateColors({required int primaryColor, required int accentColor}) {
    _branding = _branding.copyWith(
      primaryColorValue: primaryColor,
      accentColorValue: accentColor,
    );
    notifyListeners();
  }

  void updateLogo(String logoPath) {
    _branding = _branding.copyWith(logoPath: logoPath);
    notifyListeners();
  }

  void updateOwnerPhoto(String photoPath) {
    _branding = _branding.copyWith(ownerPhotoPath: photoPath);
    notifyListeners();
  }
}
