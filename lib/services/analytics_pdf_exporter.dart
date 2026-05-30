import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../domain/models/sticky_note.dart';
import '../domain/models/task_item.dart';
import '../domain/models/wishlist_item.dart';
import '../domain/status.dart';
import '../features/dashboard/dashboard_store.dart';

class AnalyticsPdfExporter {
  static Future<void> export(
    BuildContext context, {
    required List<WishlistItem> wishlist,
    required List<TaskItem> tasks,
    required List<StickyNote> notes,
    required DashboardStore dashboard,
  }) async {
    try {
      final doc = pw.Document();
      final now = DateTime.now();
      final fmt = DateFormat('MMM d, yyyy • HH:mm');

      doc.addPage(
        pw.MultiPage(
          pageTheme: pw.PageTheme(
            margin: const pw.EdgeInsets.fromLTRB(32, 32, 32, 40),
            theme: pw.ThemeData.withFont(
              base: pw.Font.helvetica(),
              bold: pw.Font.helveticaBold(),
            ),
          ),
          build: (ctx) {
            return [
              _header(
                title: "Mikisho's Wish — Analytics Export",
                subtitle: 'Generated ${fmt.format(now)}',
              ),
              pw.SizedBox(height: 14),
              _kpiRow(dashboard),
              pw.SizedBox(height: 18),
              _sectionTitle('Weekly completed (last 7 days)'),
              pw.SizedBox(height: 8),
              _weeklyTable(dashboard.weeklyCompleted.toList(growable: false)),
              pw.SizedBox(height: 18),
              _sectionTitle('Wishlist'),
              pw.SizedBox(height: 8),
              _statusTableWishlist(wishlist),
              pw.SizedBox(height: 14),
              _itemsListWishlist(wishlist),
              pw.SizedBox(height: 18),
              _sectionTitle('Tasks'),
              pw.SizedBox(height: 8),
              _statusTableTasks(tasks),
              pw.SizedBox(height: 14),
              _itemsListTasks(tasks),
              pw.SizedBox(height: 18),
              _sectionTitle('Sticky notes'),
              pw.SizedBox(height: 8),
              _notesList(notes),
            ];
          },
          footer: (ctx) => pw.Container(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              'Page ${ctx.pageNumber} / ${ctx.pagesCount}',
              style: pw.TextStyle(
                fontSize: 10,
                color: PdfColors.grey700,
              ),
            ),
          ),
        ),
      );

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/mikishos_wish_analytics_${now.millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(await doc.save(), flush: true);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: "Mikisho's Wish — Analytics Export",
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF export failed: $e')),
      );
    }
  }

  static pw.Widget _header({required String title, required String subtitle}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: pw.BorderRadius.circular(12),
        border: pw.Border.all(color: PdfColors.blue200, width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            subtitle,
            style: pw.TextStyle(fontSize: 11, color: PdfColors.blueGrey700),
          ),
        ],
      ),
    );
  }

  static pw.Widget _kpiRow(DashboardStore dashboard) {
    pw.Widget kpi(String label, String value) {
      return pw.Expanded(
        child: pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey50,
            borderRadius: pw.BorderRadius.circular(12),
            border: pw.Border.all(color: PdfColors.grey300, width: 1),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                label,
                style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                value,
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey900,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final wishlistTotal = dashboard.wishlist.total;
    final tasksTotal = dashboard.tasks.total;
    final wishlistRate = (dashboard.wishlist.completionRate * 100).clamp(0, 100);
    final tasksRate = (dashboard.tasks.completionRate * 100).clamp(0, 100);

    return pw.Row(
      children: [
        kpi('Wishlist items', '$wishlistTotal'),
        pw.SizedBox(width: 10),
        kpi('Tasks', '$tasksTotal'),
        pw.SizedBox(width: 10),
        kpi('Wishlist completion', '${wishlistRate.toStringAsFixed(0)}%'),
        pw.SizedBox(width: 10),
        kpi('Tasks completion', '${tasksRate.toStringAsFixed(0)}%'),
      ],
    );
  }

  static pw.Widget _sectionTitle(String text) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        pw.Container(
          width: 10,
          height: 10,
          decoration: pw.BoxDecoration(
            color: PdfColors.blue600,
            borderRadius: pw.BorderRadius.circular(3),
          ),
        ),
        pw.SizedBox(width: 8),
        pw.Text(
          text,
          style: pw.TextStyle(
            fontSize: 13,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.grey900,
          ),
        ),
      ],
    );
  }

  static pw.Widget _weeklyTable(List<int> values) {
    final now = DateTime.now();
    DateTime dayForIndex(int i) =>
        DateTime(now.year, now.month, now.day).subtract(Duration(days: 6 - i));

    final rows = List.generate(values.length, (i) {
      final d = dayForIndex(i);
      return [
        '${d.month}/${d.day}',
        '${values[i]}',
      ];
    });

    return pw.TableHelper.fromTextArray(
      headers: const ['Date', 'Completed'],
      data: rows,
      headerStyle: pw.TextStyle(
        fontSize: 10,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.grey900,
      ),
      cellStyle: const pw.TextStyle(fontSize: 10),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
      cellAlignment: pw.Alignment.centerLeft,
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: const {
        0: pw.FlexColumnWidth(2),
        1: pw.FlexColumnWidth(1),
      },
    );
  }

  static Map<ItemStatus, int> _countsFromStatuses(Iterable<ItemStatus> statuses) {
    final map = <ItemStatus, int>{
      ItemStatus.pending: 0,
      ItemStatus.onTheWay: 0,
      ItemStatus.completed: 0,
      ItemStatus.notCompleted: 0,
    };
    for (final s in statuses) {
      map[s] = (map[s] ?? 0) + 1;
    }
    return map;
  }

  static String _statusLabel(ItemStatus s) => switch (s) {
        ItemStatus.pending => 'Pending',
        ItemStatus.onTheWay => 'On the way',
        ItemStatus.completed => 'Completed',
        ItemStatus.notCompleted => 'Not completed',
      };

  static pw.Widget _statusTableWishlist(List<WishlistItem> items) {
    final counts = _countsFromStatuses(items.map((e) => e.status));
    return _statusTable(counts);
  }

  static pw.Widget _statusTableTasks(List<TaskItem> items) {
    final counts = _countsFromStatuses(items.map((e) => e.status));
    return _statusTable(counts);
  }

  static pw.Widget _statusTable(Map<ItemStatus, int> counts) {
    final data = [
      for (final s in ItemStatus.values) [_statusLabel(s), '${counts[s] ?? 0}']
    ];
    return pw.TableHelper.fromTextArray(
      headers: const ['Status', 'Count'],
      data: data,
      headerStyle: pw.TextStyle(
        fontSize: 10,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.grey900,
      ),
      cellStyle: const pw.TextStyle(fontSize: 10),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
      cellAlignment: pw.Alignment.centerLeft,
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: const {
        0: pw.FlexColumnWidth(2),
        1: pw.FlexColumnWidth(1),
      },
    );
  }

  static pw.Widget _itemsListWishlist(List<WishlistItem> items) {
    final fmt = DateFormat('EEE, MMM d');
    final sorted = [...items]..sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));
    return _bullets(
      sorted.map((w) {
        final date = fmt.format(w.scheduledDate);
        final status = _statusLabel(w.status);
        final extra = (w.description?.trim().isNotEmpty ?? false) ? ' — ${w.description!.trim()}' : '';
        return '[$status] $date — ${w.title}$extra';
      }).toList(growable: false),
      emptyText: 'No wishlist items yet.',
    );
  }

  static pw.Widget _itemsListTasks(List<TaskItem> items) {
    final fmt = DateFormat('EEE, MMM d');
    final sorted = [...items]..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return _bullets(
      sorted.map((t) {
        final date = fmt.format(t.dueDate);
        final status = _statusLabel(t.status);
        final extra = (t.description?.trim().isNotEmpty ?? false) ? ' — ${t.description!.trim()}' : '';
        return '[$status] $date — ${t.title}$extra';
      }).toList(growable: false),
      emptyText: 'No tasks yet.',
    );
  }

  static pw.Widget _notesList(List<StickyNote> notes) {
    final fmt = DateFormat('MMM d');
    final sorted = [...notes]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return _bullets(
      sorted.map((n) {
        final date = fmt.format(n.createdAt);
        final text = n.content.replaceAll('\n', ' ').trim();
        final clipped = (text.length <= 120) ? text : '${text.substring(0, 120)}…';
        return '$date — $clipped';
      }).toList(growable: false),
      emptyText: 'No sticky notes yet.',
    );
  }

  static pw.Widget _bullets(List<String> lines, {required String emptyText}) {
    if (lines.isEmpty) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: PdfColors.grey50,
          borderRadius: pw.BorderRadius.circular(12),
          border: pw.Border.all(color: PdfColors.grey300, width: 1),
        ),
        child: pw.Text(emptyText, style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
      );
    }

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        borderRadius: pw.BorderRadius.circular(12),
        border: pw.Border.all(color: PdfColors.grey300, width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          for (final line in lines)
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 6),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('• ', style: const pw.TextStyle(fontSize: 11)),
                  pw.Expanded(child: pw.Text(line, style: const pw.TextStyle(fontSize: 10))),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

