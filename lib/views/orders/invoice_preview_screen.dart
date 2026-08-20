import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../../models/order_model.dart';
import '../../models/branding_model.dart';
import '../../services/pdf_service.dart';

class InvoicePreviewScreen extends StatelessWidget {
  final OrderModel order;
  final BrandingModel branding;

  const InvoicePreviewScreen({
    super.key,
    required this.order,
    required this.branding,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Invoice ${order.invoiceNumber}"),
        backgroundColor: branding.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: PdfPreview(
        build: (format) => PdfService.generateInvoicePdf(order: order, branding: branding),
        allowPrinting: true,
        allowSharing: true,
        canChangeOrientation: false,
        canChangePageFormat: false,
        pdfFileName: 'Invoice_${order.invoiceNumber}.pdf',
      ),
    );
  }
}
