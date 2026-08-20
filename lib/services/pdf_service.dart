import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/order_model.dart';
import '../models/recipe_model.dart';
import '../models/branding_model.dart';

class PdfService {
  /// Generate printable PDF Invoice for an order
  static Future<Uint8List> generateInvoicePdf({
    required OrderModel order,
    required BrandingModel branding,
  }) async {
    final pdf = pw.Document();

    final currencyFormat = NumberFormat.currency(
      symbol: branding.currencySymbol,
      decimalDigits: 2,
    );

    final dateFormat = DateFormat('dd MMMM yyyy, HH:mm');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // 1. Header Section
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        branding.businessName.toUpperCase(),
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.brown900,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text("Owner: ${branding.ownerName}", style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                      pw.Text(branding.welcomeMessage, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.brown800,
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                        child: pw.Text(
                          "INVOICE",
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Text("Invoice No: ${order.invoiceNumber}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                      pw.Text("Date: ${dateFormat.format(order.createdAt)}", style: const pw.TextStyle(fontSize: 9)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Divider(color: PdfColors.grey300, thickness: 1),
              pw.SizedBox(height: 15),

              // 2. Customer & Fulfillment Information
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text("BILLED TO / CUSTOMER:", style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.brown800)),
                      pw.SizedBox(height: 4),
                      pw.Text(order.customerName, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                      if (order.customerPhone.isNotEmpty)
                        pw.Text("Phone: ${order.customerPhone}", style: const pw.TextStyle(fontSize: 10)),
                      if (order.customerAddress.isNotEmpty)
                        pw.Text("Address: ${order.customerAddress}", style: const pw.TextStyle(fontSize: 10)),
                      if (order.customerPostcode.isNotEmpty)
                        pw.Text("Postcode: ${order.customerPostcode}", style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text("ORDER STATUS:", style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.brown800)),
                      pw.SizedBox(height: 4),
                      pw.Text(order.status.displayName, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 4),
                      pw.Text("Fulfillment: ${order.fulfillment.name.toUpperCase()}", style: const pw.TextStyle(fontSize: 10)),
                      pw.Text("Payment: ${order.paymentStatus.name.toUpperCase()}", style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: order.paymentStatus == PaymentStatus.paid ? PdfColors.green800 : PdfColors.red800)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 25),

              // 3. Items Table
              pw.TableHelper.fromTextArray(
                headers: ['Item Description', 'Qty', 'Unit Price', 'Total'],
                data: order.items.map((item) {
                  return [
                    item.recipeName,
                    item.quantity.toString(),
                    currencyFormat.format(item.unitPrice),
                    currencyFormat.format(item.lineTotal),
                  ];
                }).toList(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.brown700),
                rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.5))),
                cellAlignment: pw.Alignment.centerLeft,
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.center,
                  2: pw.Alignment.centerRight,
                  3: pw.Alignment.centerRight,
                },
                cellStyle: const pw.TextStyle(fontSize: 10),
                cellPadding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
              pw.SizedBox(height: 20),

              // 4. Totals Summary
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Container(
                    width: 220,
                    child: pw.Column(
                      children: [
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text("Subtotal:", style: const pw.TextStyle(fontSize: 10)),
                            pw.Text(currencyFormat.format(order.subtotal), style: const pw.TextStyle(fontSize: 10)),
                          ],
                        ),
                        pw.SizedBox(height: 4),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text("VAT (${(order.vatRate * 100).toInt()}%):", style: const pw.TextStyle(fontSize: 10)),
                            pw.Text(currencyFormat.format(order.vatAmount), style: const pw.TextStyle(fontSize: 10)),
                          ],
                        ),
                        pw.Divider(color: PdfColors.grey400),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text("GRAND TOTAL:", style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.brown900)),
                            pw.Text(currencyFormat.format(order.totalAmount), style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.brown900)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.Spacer(),

              // 5. Footer Notes & Payment Terms
              if (order.notes.isNotEmpty) ...[
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text("Order Notes:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                      pw.Text(order.notes, style: const pw.TextStyle(fontSize: 9)),
                    ],
                  ),
                ),
                pw.SizedBox(height: 15),
              ],
              pw.Center(
                child: pw.Text(
                  "Thank you for supporting our artisanal bakery! • ${branding.businessName}",
                  style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600, fontStyle: pw.FontStyle.italic),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Generate printable PDF Specification & Recipe Sheet
  static Future<Uint8List> generateRecipePdf({
    required RecipeModel recipe,
    required BrandingModel branding,
  }) async {
    final pdf = pw.Document();
    final currencyFormat = NumberFormat.currency(symbol: branding.currencySymbol, decimalDigits: 2);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(branding.businessName, style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
                      pw.Text(recipe.title, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.brown900)),
                      pw.Text("Category: ${recipe.category}", style: pw.TextStyle(fontSize: 10, color: PdfColors.brown700, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.brown100,
                      borderRadius: pw.BorderRadius.circular(6),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text("Yield: ${recipe.yieldServings} servings", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                        pw.Text("Prep: ${recipe.prepTimeMins} mins | Bake: ${recipe.bakeTimeMins} mins", style: const pw.TextStyle(fontSize: 9)),
                        pw.Text("Temp: ${recipe.bakingTempC}°C", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.deepOrange900)),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 15),
              pw.Divider(color: PdfColors.grey300),
              pw.SizedBox(height: 10),

              // Allergen Alert Badge Box
              if (recipe.allergens.isNotEmpty) ...[
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.amber50,
                    border: pw.Border.all(color: PdfColors.amber800, width: 1),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Row(
                    children: [
                      pw.Text("ALLERGEN WARNING (UK): ", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.amber900, fontSize: 10)),
                      pw.Expanded(
                        child: pw.Text(
                          recipe.allergens.join(', '),
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.red900, fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 15),
              ],

              // Ingredients Table & Financial Costing
              pw.Text("INGREDIENTS & COSTING", style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.brown800)),
              pw.SizedBox(height: 6),
              pw.TableHelper.fromTextArray(
                headers: ['Ingredient', 'Quantity', 'Unit', 'Estimated Cost'],
                data: recipe.ingredients.map((ing) {
                  return [
                    ing.name,
                    ing.quantity.toString(),
                    ing.unit,
                    currencyFormat.format(ing.itemTotalCost),
                  ];
                }).toList(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 9),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.brown700),
                cellStyle: const pw.TextStyle(fontSize: 9),
                cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              ),
              pw.SizedBox(height: 6),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("Total Batch Cost: ${currencyFormat.format(recipe.totalBatchCost)}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                  pw.Text("Cost per Serving: ${currencyFormat.format(recipe.costPerServing)}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.green900)),
                ],
              ),
              pw.SizedBox(height: 15),

              // Step-by-Step Baking Method
              pw.Text("BAKING INSTRUCTIONS", style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.brown800)),
              pw.SizedBox(height: 6),
              ...recipe.instructions.asMap().entries.map((entry) {
                return pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 6),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Container(
                        width: 18,
                        height: 18,
                        alignment: pw.Alignment.center,
                        decoration: const pw.BoxDecoration(color: PdfColors.brown800, shape: pw.BoxShape.circle),
                        child: pw.Text('${entry.key + 1}', style: pw.TextStyle(color: PdfColors.white, fontSize: 9, fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.SizedBox(width: 8),
                      pw.Expanded(child: pw.Text(entry.value, style: const pw.TextStyle(fontSize: 9.5))),
                    ],
                  ),
                );
              }),
              pw.SizedBox(height: 15),

              // Nutritional Info Table
              pw.Text("NUTRITIONAL INFORMATION (Per Serving)", style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800)),
              pw.SizedBox(height: 4),
              pw.TableHelper.fromTextArray(
                headers: ['Calories', 'Protein', 'Carbs', 'Fat', 'Sugar', 'Salt', 'Fibre'],
                data: [
                  [
                    '${recipe.nutritionalInfo.calories} kcal',
                    '${recipe.nutritionalInfo.protein}g',
                    '${recipe.nutritionalInfo.carbohydrates}g',
                    '${recipe.nutritionalInfo.fat}g',
                    '${recipe.nutritionalInfo.sugar}g',
                    '${recipe.nutritionalInfo.salt}g',
                    '${recipe.nutritionalInfo.fibre}g',
                  ]
                ],
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8, color: PdfColors.brown900),
                cellStyle: const pw.TextStyle(fontSize: 8),
                cellPadding: const pw.EdgeInsets.all(4),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }
}
