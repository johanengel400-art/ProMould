import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class ChecklistExportService {
  static Future<void> exportToCSV(Map<String, dynamic> checklist) async {
    try {
      final csv = _generateCSV(checklist);
      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          'checklist_${checklist['title']}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(csv);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Checklist: ${checklist['title']}',
      );
    } catch (e) {
      throw Exception('Failed to export CSV: $e');
    }
  }

  static Future<void> exportToPDF(Map<String, dynamic> checklist) async {
    try {
      final pdf = await _generatePDF(checklist);
      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          'checklist_${checklist['title']}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(await pdf.save());

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Checklist: ${checklist['title']}',
      );
    } catch (e) {
      throw Exception('Failed to export PDF: $e');
    }
  }

  static Future<void> exportMultipleToCSV(
      List<Map<String, dynamic>> checklists) async {
    try {
      final csv = _generateMultipleCSV(checklists);
      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          'checklists_export_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(csv);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Checklists Export',
      );
    } catch (e) {
      throw Exception('Failed to export multiple CSV: $e');
    }
  }

  static String _generateCSV(Map<String, dynamic> checklist) {
    final buffer = StringBuffer();

    // Header
    buffer.writeln('Checklist Export');
    buffer.writeln('Title,${checklist['title']}');
    buffer.writeln('Category,${checklist['category'] ?? 'N/A'}');
    buffer.writeln(
        'Created,${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(checklist['createdAt']))}');
    buffer.writeln('');

    // Items
    buffer.writeln('Item,Status,Notes');
    final items = checklist['items'] as List? ?? [];
    for (final item in items) {
      final title = (item['title'] as String).replaceAll(',', ';');
      final isCompleted = item['isCompleted'] ?? false;
      final notes = ((item['notes'] as String?) ?? '').replaceAll(',', ';');
      buffer.writeln('$title,${isCompleted ? "Completed" : "Pending"},$notes');
    }

    return buffer.toString();
  }

  static String _generateMultipleCSV(List<Map<String, dynamic>> checklists) {
    final buffer = StringBuffer();

    buffer.writeln('Checklists Export');
    buffer.writeln(
        'Generated,${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}');
    buffer.writeln('');
    buffer.writeln('Checklist,Category,Item,Status,Notes');

    for (final checklist in checklists) {
      final checklistTitle =
          (checklist['title'] as String).replaceAll(',', ';');
      final category =
          ((checklist['category'] as String?) ?? 'N/A').replaceAll(',', ';');
      final items = checklist['items'] as List? ?? [];

      for (final item in items) {
        final itemTitle = (item['title'] as String).replaceAll(',', ';');
        final isCompleted = item['isCompleted'] ?? false;
        final notes = ((item['notes'] as String?) ?? '').replaceAll(',', ';');
        buffer.writeln(
            '$checklistTitle,$category,$itemTitle,${isCompleted ? "Completed" : "Pending"},$notes');
      }
    }

    return buffer.toString();
  }

  static Future<pw.Document> _generatePDF(
      Map<String, dynamic> checklist) async {
    final pdf = pw.Document();
    final items = checklist['items'] as List? ?? [];
    final completedCount = items.where((i) => i['isCompleted'] == true).length;
    final totalCount = items.length;
    final completionRate = totalCount > 0
        ? (completedCount / totalCount * 100).toStringAsFixed(1)
        : '0';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // Header
          pw.Header(
            level: 0,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  checklist['title'],
                  style: pw.TextStyle(
                      fontSize: 24, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'Category: ${checklist['category'] ?? 'N/A'}',
                  style: const pw.TextStyle(
                      fontSize: 12, color: PdfColors.grey700),
                ),
                pw.Text(
                  'Created: ${DateFormat('MMM dd, yyyy HH:mm').format(DateTime.parse(checklist['createdAt']))}',
                  style: const pw.TextStyle(
                      fontSize: 12, color: PdfColors.grey700),
                ),
                pw.SizedBox(height: 16),
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.blue50,
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Progress: $completedCount / $totalCount items'),
                      pw.Text('$completionRate% Complete',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                ),
                pw.SizedBox(height: 24),
              ],
            ),
          ),

          // Items
          ...items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isCompleted = item['isCompleted'] ?? false;
            final notes = item['notes'] as String?;

            return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 12),
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    children: [
                      pw.Container(
                        width: 20,
                        height: 20,
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(
                              color: isCompleted
                                  ? PdfColors.green
                                  : PdfColors.grey),
                          borderRadius: pw.BorderRadius.circular(4),
                          color: isCompleted ? PdfColors.green : null,
                        ),
                        child: isCompleted
                            ? pw.Center(
                                child: pw.Text(
                                  '✓',
                                  style: const pw.TextStyle(
                                      color: PdfColors.white, fontSize: 14),
                                ),
                              )
                            : null,
                      ),
                      pw.SizedBox(width: 12),
                      pw.Expanded(
                        child: pw.Text(
                          '${index + 1}. ${item['title']}',
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                            decoration: isCompleted
                                ? pw.TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (notes != null && notes.isNotEmpty) ...[
                    pw.SizedBox(height: 8),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.grey100,
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Text(
                        'Notes: $notes',
                        style: const pw.TextStyle(
                            fontSize: 12, color: PdfColors.grey800),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),

          // Footer
          pw.SizedBox(height: 24),
          pw.Divider(),
          pw.SizedBox(height: 8),
          pw.Text(
            'Generated by ProMould on ${DateFormat('MMM dd, yyyy HH:mm').format(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
          ),
        ],
      ),
    );

    return pdf;
  }

  static Future<void> exportChecklistHistory(
    String checklistId,
    List<Map<String, dynamic>> completions,
  ) async {
    try {
      final csv = _generateHistoryCSV(checklistId, completions);
      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          'checklist_history_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(csv);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Checklist History',
      );
    } catch (e) {
      throw Exception('Failed to export history: $e');
    }
  }

  static String _generateHistoryCSV(
    String checklistId,
    List<Map<String, dynamic>> completions,
  ) {
    final buffer = StringBuffer();

    buffer.writeln('Checklist Completion History');
    buffer.writeln('Checklist ID,$checklistId');
    buffer.writeln(
        'Generated,${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}');
    buffer.writeln('');
    buffer.writeln('Date,Completed By,Completion Rate,Duration (min),Notes');

    for (final completion in completions) {
      final date = DateTime.parse(completion['completedAt']);
      final completedBy = completion['completedBy'] ?? 'Unknown';
      final completionRate = completion['completionRate'] ?? 0;
      final duration = completion['duration'] ?? 0;
      final notes =
          ((completion['notes'] as String?) ?? '').replaceAll(',', ';');

      buffer.writeln(
        '${DateFormat('yyyy-MM-dd HH:mm').format(date)},$completedBy,$completionRate%,$duration,$notes',
      );
    }

    return buffer.toString();
  }

  static Future<void> exportSummaryReport(
    DateTime startDate,
    DateTime endDate,
    List<Map<String, dynamic>> checklists,
  ) async {
    try {
      final pdf = await _generateSummaryPDF(startDate, endDate, checklists);
      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          'checklist_summary_${DateFormat('yyyyMMdd').format(startDate)}_to_${DateFormat('yyyyMMdd').format(endDate)}.pdf';
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(await pdf.save());

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Checklist Summary Report',
      );
    } catch (e) {
      throw Exception('Failed to export summary: $e');
    }
  }

  static Future<pw.Document> _generateSummaryPDF(
    DateTime startDate,
    DateTime endDate,
    List<Map<String, dynamic>> checklists,
  ) async {
    final pdf = pw.Document();

    final totalChecklists = checklists.length;
    var totalItems = 0;
    var completedItems = 0;

    for (final checklist in checklists) {
      final items = checklist['items'] as List? ?? [];
      totalItems += items.length;
      completedItems += items.where((i) => i['isCompleted'] == true).length;
    }

    final overallCompletion = totalItems > 0
        ? (completedItems / totalItems * 100).toStringAsFixed(1)
        : '0';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Checklist Summary Report',
                  style: pw.TextStyle(
                      fontSize: 24, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'Period: ${DateFormat('MMM dd, yyyy').format(startDate)} - ${DateFormat('MMM dd, yyyy').format(endDate)}',
                  style: const pw.TextStyle(
                      fontSize: 14, color: PdfColors.grey700),
                ),
                pw.SizedBox(height: 24),
              ],
            ),
          ),

          // Summary Stats
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue50,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                        'Total Checklists', totalChecklists.toString()),
                    _buildStatItem('Total Items', totalItems.toString()),
                    _buildStatItem('Completed', completedItems.toString()),
                    _buildStatItem('Completion Rate', '$overallCompletion%'),
                  ],
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 24),
          pw.Text(
            'Checklist Details',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 12),

          // Checklist table
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  _buildTableCell('Checklist', isHeader: true),
                  _buildTableCell('Category', isHeader: true),
                  _buildTableCell('Items', isHeader: true),
                  _buildTableCell('Completed', isHeader: true),
                  _buildTableCell('Rate', isHeader: true),
                ],
              ),
              ...checklists.map((checklist) {
                final items = checklist['items'] as List? ?? [];
                final completed =
                    items.where((i) => i['isCompleted'] == true).length;
                final rate = items.isNotEmpty
                    ? (completed / items.length * 100).toStringAsFixed(0)
                    : '0';

                return pw.TableRow(
                  children: [
                    _buildTableCell(checklist['title']),
                    _buildTableCell(checklist['category'] ?? 'N/A'),
                    _buildTableCell(items.length.toString()),
                    _buildTableCell(completed.toString()),
                    _buildTableCell('$rate%'),
                  ],
                );
              }),
            ],
          ),

          pw.SizedBox(height: 24),
          pw.Divider(),
          pw.SizedBox(height: 8),
          pw.Text(
            'Generated by ProMould on ${DateFormat('MMM dd, yyyy HH:mm').format(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
          ),
        ],
      ),
    );

    return pdf;
  }

  static pw.Widget _buildStatItem(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(
          value,
          style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue800),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
        ),
      ],
    );
  }

  static pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 12 : 10,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }
}
