part of '../../main.dart';

class ReportDraftService {
  final LocalDataRepository _local;

  ReportDraftService({LocalDataRepository? local})
      : _local = local ?? LocalDataRepository();

  Future<ReportDraft?> load(String email) {
    return _local.loadReportDraft(email);
  }

  Future<void> save(ReportDraft draft) {
    return _local.saveReportDraft(draft);
  }

  Future<void> delete(String email) {
    return _local.deleteReportDraft(email);
  }
}
