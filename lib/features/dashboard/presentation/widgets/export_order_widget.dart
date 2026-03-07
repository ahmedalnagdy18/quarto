import 'package:flutter/material.dart';
import 'package:quarto/core/services/orders_export_service.dart';

class ExportOrdersHelper {
  // نفس الدالة بنفس التوقيع
  static Future<void> exportToExcel(
    BuildContext context,
    List<dynamic> orders,
  ) async {
    // مجرد استدعاء للـ Service
    await OrdersExportService.exportOrders(context, orders);
  }
}
