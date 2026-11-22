
class NumberRange {
  const NumberRange(this.min, this.max, this.unit);

  final double min;
  final double max;
  final String unit;

  bool contains(num value) {
    final number = value.toDouble();

    return number.isFinite &&
        number >= min &&
        number <= max;
  }

  String? check(num? value) {
    if (value == null) {
      return 'Required';
    }

    if (!contains(value)) {
      return 'Enter ${_format(min)} to ${_format(max)} $unit';
    }

    return null;
  }

  String _format(double value) {
    return value == value.truncateToDouble()
        ? value.toInt().toString()
        : value.toString();
  }
}

// Provisional ranges pending clinician approval.
const temperatureC = NumberRange(30, 45, '°C');
const muacMm = NumberRange(60, 250, 'mm');
const gestationalWeeks = NumberRange(1, 45, 'weeks');
