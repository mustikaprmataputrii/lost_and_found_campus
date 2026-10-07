part of '../../main.dart';

String _formatJam(DateTime date) =>
    '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
String _formatTanggal(DateTime date) =>
    '${date.day}/${date.month}/${date.year} ${_formatJam(date)}';

String _formatRelativeTime(DateTime? date) {
  if (date == null) return 'belum tersedia';
  final difference = DateTime.now().difference(date);
  if (difference.inMinutes < 1) return 'baru saja';
  if (difference.inMinutes < 60) return '${difference.inMinutes} mnt lalu';
  if (difference.inHours < 24) return '${difference.inHours} jam lalu';
  return '${difference.inDays} hari lalu';
}
