class DateUtils {
  static String formatDate(DateTime date) {
    return '${_padZero(date.day)}/${_padZero(date.month)}/${date.year}';
  }

  static String formatDateTime(DateTime date) {
    return '${formatDate(date)} ${_padZero(date.hour)}:${_padZero(date.minute)}';
  }

  static String _padZero(int number) {
    return number.toString().padLeft(2, '0');
  }

  static String timeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      return 'Hace ${(difference.inDays / 365).floor()} años';
    } else if (difference.inDays > 30) {
      return 'Hace ${(difference.inDays / 30).floor()} meses';
    } else if (difference.inDays > 0) {
      return 'Hace ${difference.inDays} días';
    } else if (difference.inHours > 0) {
      return 'Hace ${difference.inHours} horas';
    } else if (difference.inMinutes > 0) {
      return 'Hace ${difference.inMinutes} minutos';
    } else {
      return 'Ahora mismo';
    }
  }
}
