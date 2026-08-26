import 'dart:async';
import 'package:flutter/foundation.dart';

import '../models/branding_model.dart';
import '../services/database_service.dart';

class BrandingProvider extends ChangeNotifier {
  BrandingModel _branding = BrandingModel();
  StreamSubscription<BrandingModel?>? _brandingSubscription;

  BrandingProvider() {
    _initLiveStream();
  }

  void _initLiveStream() {
    _brandingSubscription = DatabaseService.instance.brandingStream.listen(
      (liveBranding) {
        if (liveBranding != null) {
          _branding = liveBranding;
          notifyListeners();
        }
      },
      onError: (err) {
        debugPrint("Error in live branding stream: $err");
      },
    );
  }

  @override
  void dispose() {
    _brandingSubscription?.cancel();
    super.dispose();
  }

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
