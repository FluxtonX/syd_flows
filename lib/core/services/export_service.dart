import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../features/cycle/data/models/cycle_types.dart';
import '../../features/cycle/domain/cycle_calculator.dart';
import '../utils/helpers.dart';
import 'cycle_service.dart';

enum ExportDateRange {
  currentMonth,
  last3Months,
  last6Months,
  allTime,
}

extension ExportDateRangeExtension on ExportDateRange {
  String get label {
    switch (this) {
      case ExportDateRange.currentMonth:
        return 'This Month';
      case ExportDateRange.last3Months:
        return 'Last 3 Months';
      case ExportDateRange.last6Months:
        return 'Last 6 Months';
      case ExportDateRange.allTime:
        return 'All Time History';
    }
  }

  String get description {
    switch (this) {
      case ExportDateRange.currentMonth:
        return 'Export current month cycle journal records';
      case ExportDateRange.last3Months:
        return 'Export 90 days quarterly health summary';
      case ExportDateRange.last6Months:
        return 'Export 180 days half-yearly summary';
      case ExportDateRange.allTime:
        return 'Export complete historical cycle records';
    }
  }
}

class ExportResult {
  final String filePath;
  final int recordCount;
  final String csvContent;
  final ExportDateRange range;

  const ExportResult({
    required this.filePath,
    required this.recordCount,
    required this.csvContent,
    required this.range,
  });
}

class ExportService {
  ExportService._privateConstructor();
  static final ExportService instance = ExportService._privateConstructor();

  /// Generates, saves, and shares a CSV health report for [uid] with specified [range].
  Future<ExportResult> exportCycleLogsCsv({
    required String uid,
    CycleSettings? settings,
    ExportDateRange range = ExportDateRange.allTime,
    bool shareFile = true,
  }) async {
    try {
      final userSettings = settings ?? CycleSettings.defaults;
      final logsMap = await CycleService.instance.fetchAllCycleLogs(uid);

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final buffer = StringBuffer();
      // Professional CSV Metadata Header
      buffer.writeln('# SYD FLOW - Personal Health & Cycle Report');
      buffer.writeln(
        '# Export Date: ${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
      );
      buffer.writeln('# Filter Range: ${range.label}');
      buffer.writeln('# Format: Professional CSV Health Summary');
      buffer.writeln(
        'Date,Cycle Day,Cycle Phase,Flow Level,Period Start,Moods,Symptoms,Energy Level,Notes',
      );

      final sortedDates = logsMap.keys.toList()..sort();
      int count = 0;

      for (final dateKey in sortedDates) {
        final date = DateTime.tryParse(dateKey);
        if (date == null) continue;

        // Apply Date Range Filter
        bool includeDate = false;
        switch (range) {
          case ExportDateRange.currentMonth:
            includeDate =
                (date.month == today.month && date.year == today.year);
            break;
          case ExportDateRange.last3Months:
            includeDate =
                date.isAfter(today.subtract(const Duration(days: 90)));
            break;
          case ExportDateRange.last6Months:
            includeDate =
                date.isAfter(today.subtract(const Duration(days: 180)));
            break;
          case ExportDateRange.allTime:
            includeDate = true;
            break;
        }

        if (!includeDate) continue;

        final journal = logsMap[dateKey]!;
        final computedStatus = CycleCalculator.compute(
          settings: userSettings,
          today: date,
        );

        final cycleDayStr = '${computedStatus.cycleDay}';
        final phaseStr = computedStatus.phase.displayName;
        final flowStr = journal.flow != null && journal.flow!.isNotEmpty
            ? _capitalize(journal.flow!)
            : 'None';
        final periodStartStr = journal.isPeriodStart ? 'Yes' : 'No';
        final moodsStr = journal.moods.join('; ');
        final symptomsStr = journal.symptoms.join('; ');
        final energyStr = '${(journal.energy * 100).toInt()}%';
        final notesStr = journal.notes;

        final row = [
          _escapeCsv(dateKey),
          _escapeCsv(cycleDayStr),
          _escapeCsv(phaseStr),
          _escapeCsv(flowStr),
          _escapeCsv(periodStartStr),
          _escapeCsv(moodsStr),
          _escapeCsv(symptomsStr),
          _escapeCsv(energyStr),
          _escapeCsv(notesStr),
        ].join(',');

        buffer.writeln(row);
        count++;
      }

      final csvText = buffer.toString();
      final cleanRangeName = range.label.replaceAll(' ', '');
      final fileName = 'SYD_FLOW_Cycle_Report_$cleanRangeName.csv';

      File? targetFile;

      // 1. On Android: Save directly to public Download folder (/storage/emulated/0/Download)
      if (Platform.isAndroid) {
        try {
          final publicDownloadDir = Directory('/storage/emulated/0/Download');
          if (await publicDownloadDir.exists()) {
            final pubFile = File('${publicDownloadDir.path}/$fileName');
            await pubFile.writeAsString(csvText, flush: true);
            targetFile = pubFile;
            Helpers.log(
              'Saved directly to public Android Download folder: ${pubFile.path}',
            );
          }
        } catch (e) {
          Helpers.log('Could not write to public Android Download dir: $e');
        }
      }

      // 2. Fallback / iOS: Save to App Documents folder (Visible in Files App)
      if (targetFile == null) {
        final docsDir = await getApplicationDocumentsDirectory();
        targetFile = File('${docsDir.path}/$fileName');
        await targetFile.writeAsString(csvText, flush: true);
        Helpers.log('Saved to App Documents folder: ${targetFile.path}');
      }

      final file = targetFile;

      Helpers.log(
        'Exported $count cycle logs (${range.label}) to CSV: ${file.path}',
      );

      if (shareFile) {
        try {
          await Share.shareXFiles(
            [XFile(file.path)],
            subject: 'SYD FLOW Cycle Health Report (${range.label})',
            text:
                'Here is my SYD FLOW cycle health summary report (${range.label}).',
          );
        } catch (shareError) {
          Helpers.log(
            'Native share plugin notice (requires app rebuild): $shareError',
          );
        }
      }

      return ExportResult(
        filePath: file.path,
        recordCount: count,
        csvContent: csvText,
        range: range,
      );
    } catch (e) {
      Helpers.log('Error exporting cycle logs CSV: $e');
      rethrow;
    }
  }

  static String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  static String _escapeCsv(String input) {
    if (input.contains(',') || input.contains('"') || input.contains('\n')) {
      final escaped = input.replaceAll('"', '""');
      return '"$escaped"';
    }
    return input;
  }
}
