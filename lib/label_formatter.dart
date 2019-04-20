
class LabelFormatter {

  static const Map<int, String> shorthandMonthMap = {
    DateTime.january: 'Jan',
    DateTime.february: 'Feb',
    DateTime.march: 'Mar',
    DateTime.april: 'Apr',
    DateTime.may: 'May',
    DateTime.june: 'June',
    DateTime.july: 'July',
    DateTime.august: 'Aug',
    DateTime.september: 'Sep',
    DateTime.october: 'Oct',
    DateTime.november: 'Nov',
    DateTime.december: 'Dec',
  };

 static Function labelToStringForType(Type type) {
    switch (type) {
      case DateTime:
        return formatDate;
      case int:
      case double:
        return _formatNumber;
      default:
        return (any) => any.toString();
    }
  }

  static String formatDate(DateTime date) {
   return '${shorthandMonthMap[date.month]} \'${_twoDigitYear(date.year)}';
  }

  static String _twoDigitYear(int year) {
   final fullYear = '$year';
   return fullYear.substring(fullYear.length - 2);
  }

  static String _formatLargeNumber(num n) {
    final tenThousand = 10000;
    final oneMillion = 1000000;
    final oneBillion = 1000000000;

    if (n > oneBillion) {
      final billions = n / oneBillion;
      return '${_formatNumber(billions)}b';
    }

    if (n > oneMillion) {
      final millions = n / oneMillion;
      return '${_formatNumber(millions)}m';
    }

    if (n > tenThousand) {
      final thousands = n / 1000;
      return '${_formatNumber(thousands)}k';
    }

    return '$n';
  }

  static String _formatNumber(num n) {
    if (n > 100000) return _formatLargeNumber(n);
    if (n is int) return '$n.00';

    final toString = '$n';
    final dotIndex = toString.indexOf('.');

    final lastIndex =
    dotIndex + 3 >= toString.length ? toString.length : dotIndex + 3;

    if (dotIndex == toString.length - 1) {
      return '${toString}00';
    } else if (dotIndex == toString.length - 2) {
      return '${toString}0';
    } else {
      return toString.substring(0, lastIndex);
    }
  }

}