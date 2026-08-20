import 'package:flutter/material.dart';

class BrandingModel {
  final String businessName;
  final String ownerName;
  final String welcomeMessage;
  final int primaryColorValue;
  final int accentColorValue;
  final String? logoPath;
  final String? ownerPhotoPath;
  final String currencySymbol;
  final double vatRate; // e.g. 0.20 for 20% VAT

  BrandingModel({
    this.businessName = "Honey & Flour Artisanal Bakery",
    this.ownerName = "Eleanor Vance",
    this.welcomeMessage = "Freshly Baked with Love & Passion",
    this.primaryColorValue = 0xFF8D6E63, // Warm Amber Brown
    this.accentColorValue = 0xFFD81B60, // Rose Berry
    this.logoPath,
    this.ownerPhotoPath,
    this.currencySymbol = "£",
    this.vatRate = 0.20,
  });

  Color get primaryColor => Color(primaryColorValue);
  Color get accentColor => Color(accentColorValue);

  BrandingModel copyWith({
    String? businessName,
    String? ownerName,
    String? welcomeMessage,
    int? primaryColorValue,
    int? accentColorValue,
    String? logoPath,
    String? ownerPhotoPath,
    String? currencySymbol,
    double? vatRate,
  }) {
    return BrandingModel(
      businessName: businessName ?? this.businessName,
      ownerName: ownerName ?? this.ownerName,
      welcomeMessage: welcomeMessage ?? this.welcomeMessage,
      primaryColorValue: primaryColorValue ?? this.primaryColorValue,
      accentColorValue: accentColorValue ?? this.accentColorValue,
      logoPath: logoPath ?? this.logoPath,
      ownerPhotoPath: ownerPhotoPath ?? this.ownerPhotoPath,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      vatRate: vatRate ?? this.vatRate,
    );
  }

  Map<String, dynamic> toMap() => {
        'businessName': businessName,
        'ownerName': ownerName,
        'welcomeMessage': welcomeMessage,
        'primaryColorValue': primaryColorValue,
        'accentColorValue': accentColorValue,
        'logoPath': logoPath,
        'ownerPhotoPath': ownerPhotoPath,
        'currencySymbol': currencySymbol,
        'vatRate': vatRate,
      };

  factory BrandingModel.fromMap(Map<String, dynamic> map) => BrandingModel(
        businessName: map['businessName'] ?? "Honey & Flour Artisanal Bakery",
        ownerName: map['ownerName'] ?? "Eleanor Vance",
        welcomeMessage: map['welcomeMessage'] ?? "Freshly Baked with Love & Passion",
        primaryColorValue: map['primaryColorValue'] ?? 0xFF8D6E63,
        accentColorValue: map['accentColorValue'] ?? 0xFFD81B60,
        logoPath: map['logoPath'],
        ownerPhotoPath: map['ownerPhotoPath'],
        currencySymbol: map['currencySymbol'] ?? "£",
        vatRate: (map['vatRate'] as num?)?.toDouble() ?? 0.20,
      );
}
