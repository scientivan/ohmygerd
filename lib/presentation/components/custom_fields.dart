import 'package:flutter/material.dart';
import 'package:OhMyGERD/core/colors.dart';
import 'package:OhMyGERD/core/fonts.dart';

class CustomTextField extends StatelessWidget {
  final String title;
  final String hintText;
  final TextEditingController controller;
  final String? iconAssetPath;
  final String? errorText;
  final TextInputType? keyboardType;

  const CustomTextField({
    super.key,
    required this.title,
    required this.hintText,
    required this.controller,
    this.iconAssetPath,
    this.errorText,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppFonts.medium(
            14,
          ).copyWith(color: AppColors.neutral.shade600),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            isDense: true,
            hintText: hintText,
            hintStyle: AppFonts.medium(
              14,
            ).copyWith(color: AppColors.neutral.shade400),
            fillColor: AppColors.neutral.shade0,
            filled: true,
            errorText: errorText,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color:
                    errorText != null
                        ? AppColors.danger.shade300
                        : AppColors.neutral.shade900,
                width: 1.0,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color:
                    errorText != null
                        ? AppColors.danger.shade300
                        : AppColors.secondary.shade500,
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 8,
            ),
            prefixIcon:
                iconAssetPath != null
                    ? Image.asset(iconAssetPath!, width: 20, height: 20)
                    : null,
          ),
        ),
      ],
    );
  }
}

class CustomPasswordField extends StatefulWidget {
  final String title;
  final String hintText;
  final TextEditingController controller;

  final String? errorText;

  const CustomPasswordField({
    super.key,
    required this.title,
    required this.hintText,
    required this.controller,
    this.errorText,
  });

  @override
  State<CustomPasswordField> createState() => _CustomPasswordFieldState();
}

class _CustomPasswordFieldState extends State<CustomPasswordField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title,
          style: AppFonts.medium(
            14,
          ).copyWith(color: AppColors.neutral.shade600),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: widget.controller,
          obscureText: _obscureText,
          decoration: InputDecoration(
            isDense: true,
            hintText: widget.hintText,
            hintStyle: AppFonts.medium(
              14,
            ).copyWith(color: AppColors.neutral.shade400),
            fillColor: AppColors.neutral.shade0,
            filled: true,
            errorText: widget.errorText,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color:
                    widget.errorText != null
                        ? AppColors.danger.shade300
                        : AppColors.neutral.shade900,
                width: 1.0,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color:
                    widget.errorText != null
                        ? AppColors.danger.shade300
                        : AppColors.neutral.shade900,
                width: 1.0,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color:
                    widget.errorText != null
                        ? AppColors.danger.shade300
                        : AppColors.secondary.shade500,
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 8,
            ),
            suffixIcon: IconButton(
              autofocus: true,
              icon: Icon(
                _obscureText ? Icons.visibility_off : Icons.visibility,
                color: AppColors.neutral.shade700,
                size: 20,
              ),
              onPressed: () {
                setState(() {
                  _obscureText = !_obscureText;
                });
              },
            ),
          ),
        ),
      ],
    );
  }
}

class CustomDropDownField extends StatelessWidget {
  final String title;
  final String hintText;
  final List<String> items;
  final String? selectedItem;
  final ValueChanged<String?> onChanged;
  final String? errorText; // Tambahan

  const CustomDropDownField({
    super.key,
    required this.title,
    required this.hintText,
    required this.items,
    required this.selectedItem,
    required this.onChanged,
    this.errorText, // Tambahan
  });

  @override
  Widget build(BuildContext context) {
    final borderColor =
        errorText != null
            ? AppColors.danger.shade300
            : AppColors.neutral.shade900;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppFonts.medium(
            14,
          ).copyWith(color: AppColors.neutral.shade600),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: borderColor, width: 1.0),
            borderRadius: BorderRadius.circular(10),
            color: AppColors.neutral.shade0,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isDense: true,
              value: selectedItem,
              isExpanded: true,
              hint: Text(
                hintText,
                style: AppFonts.medium(
                  14,
                ).copyWith(color: AppColors.neutral.shade400),
              ),
              icon: const Icon(Icons.keyboard_arrow_down_rounded),
              items:
                  items.map((value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(
                        value.toString(),
                        style: AppFonts.medium(
                          14,
                        ).copyWith(color: AppColors.neutral.shade900),
                      ),
                    );
                  }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 4),
          Text(
            errorText!,
            style: AppFonts.medium(
              12,
            ).copyWith(color: AppColors.danger.shade300),
          ),
        ],
      ],
    );
  }
}

class CustomTimePickerField extends StatelessWidget {
  final String title;
  final String hintText;
  final TextEditingController controller;
  final void Function(TimeOfDay?) onTimePicked;
  final String? errorText;

  // Parameter baru untuk rentang waktu (opsional)
  final TimeRange? timeRange;

  const CustomTimePickerField({
    super.key,
    required this.title,
    required this.hintText,
    required this.controller,
    required this.onTimePicked,
    this.errorText,
    this.timeRange,
  });

  Future<void> _selectTime(BuildContext context) async {
    // Parse existing value or use current time
    TimeOfDay initialTime = TimeOfDay.now();
    if (controller.text.isNotEmpty) {
      try {
        // Simple parsing for time format
        final text = controller.text;
        if (text.contains(':')) {
          final parts = text.split(':');
          int hour = int.parse(parts[0].trim());
          int minute = 0;

          if (parts.length > 1) {
            // Parse minutes if available
            String minutePart = parts[1].trim();
            if (minutePart.contains(' ')) {
              minutePart = minutePart.split(' ')[0];
            }
            minute = int.parse(minutePart);
          }

          initialTime = TimeOfDay(hour: hour, minute: minute);
        }
      } catch (_) {
        // Use default if parsing fails
      }
    }

    // Show custom time picker dialog with 30-minute intervals
    final TimeOfDay? picked = await showDialog<TimeOfDay>(
      context: context,
      builder: (BuildContext context) {
        return TimeRangePickerDialog(
          initialTime: initialTime,
          timeRange: timeRange,
        );
      },
    );

    if (picked != null) {
      // Format the time in 24-hour format
      final formattedTime = _formatTimeOfDay(picked);
      controller.text = formattedTime;
      onTimePicked(picked);
    }
  }

  // Custom formatter for 24-hour format
  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final borderColor =
        errorText != null
            ? AppColors.danger.shade300
            : AppColors.neutral.shade900;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppFonts.medium(
            14,
          ).copyWith(color: AppColors.neutral.shade600),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () => _selectTime(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: borderColor, width: 1.0),
              borderRadius: BorderRadius.circular(10),
              color: Colors.white,
            ),
            child: Row(
              children: [
                Image.asset('assets/icons/timer_icon.png'),
                const SizedBox(width: 10),
                Text(
                  controller.text.isNotEmpty ? controller.text : hintText,
                  style: AppFonts.medium(14).copyWith(
                    color:
                        controller.text.isNotEmpty
                            ? AppColors.neutral.shade900
                            : AppColors.neutral.shade400,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 4),
          Text(
            errorText!,
            style: AppFonts.medium(
              12,
            ).copyWith(color: AppColors.danger.shade300),
          ),
        ],
      ],
    );
  }
}

// Enum untuk tipe rentang waktu
enum TimeRangeType {
  morning, // Pagi (05:00 - 09:30)
  afternoon, // Siang (11:00 - 15:30)
  evening, // Malam (17:00 - 21:30)
  custom, // Rentang kustom atau tanpa rentang
}

// Class untuk menentukan rentang waktu
class TimeRange {
  final TimeRangeType type;
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;

  // Konstruktor untuk rentang waktu spesifik
  TimeRange({required this.type, this.startTime, this.endTime});

  // Factory constructor untuk rentang pagi (05:00 - 09:30)
  factory TimeRange.morning() {
    return TimeRange(
      type: TimeRangeType.morning,
      startTime: const TimeOfDay(hour: 5, minute: 0),
      endTime: const TimeOfDay(hour: 9, minute: 0),
    );
  }

  // Factory constructor untuk rentang siang (11:00 - 15:30)
  factory TimeRange.afternoon() {
    return TimeRange(
      type: TimeRangeType.afternoon,
      startTime: const TimeOfDay(hour: 11, minute: 0),
      endTime: const TimeOfDay(hour: 15, minute: 0),
    );
  }

  // Factory constructor untuk rentang malam (17:00 - 21:30)
  factory TimeRange.evening() {
    return TimeRange(
      type: TimeRangeType.evening,
      startTime: const TimeOfDay(hour: 17, minute: 0),
      endTime: const TimeOfDay(hour: 21, minute: 0),
    );
  }

  // Memeriksa apakah waktu berada dalam rentang
  bool isInRange(TimeOfDay time) {
    // Convert to minutes for easier comparison
    final timeInMinutes = time.hour * 60 + time.minute;

    if (startTime == null || endTime == null) {
      return true; // No restrictions
    }

    final startInMinutes = startTime!.hour * 60 + startTime!.minute;
    final endInMinutes = endTime!.hour * 60 + endTime!.minute;

    return timeInMinutes >= startInMinutes && timeInMinutes <= endInMinutes;
  }
}

// Custom dialog that allows selecting time in 30-minute intervals
class TimeRangePickerDialog extends StatefulWidget {
  final TimeOfDay initialTime;
  final TimeRange? timeRange;

  const TimeRangePickerDialog({
    super.key,
    required this.initialTime,
    this.timeRange,
  });

  @override
  State<TimeRangePickerDialog> createState() => _TimeRangePickerDialogState();
}

class _TimeRangePickerDialogState extends State<TimeRangePickerDialog> {
  late TimeOfDay selectedTime;
  late List<TimeOfDay> availableTimes;

  @override
  void initState() {
    super.initState();

    // Initialize with the closest valid time
    selectedTime = _findClosestValidTime(widget.initialTime);

    // Generate all available times based on the time range
    availableTimes = _generateAvailableTimes();
  }

  // Generate times in 30-minute intervals within the range
  List<TimeOfDay> _generateAvailableTimes() {
    List<TimeOfDay> times = [];

    if (widget.timeRange == null) {
      // If no range specified, show all 24 hours with 30-minute intervals
      for (int hour = 0; hour < 24; hour++) {
        times.add(TimeOfDay(hour: hour, minute: 0));
        times.add(TimeOfDay(hour: hour, minute: 30));
      }
    } else {
      // If range specified, show only times within that range
      final start =
          widget.timeRange!.startTime ?? const TimeOfDay(hour: 0, minute: 0);
      final end =
          widget.timeRange!.endTime ?? const TimeOfDay(hour: 23, minute: 30);

      // Convert to minutes for easier calculation
      final startMinutes = start.hour * 60 + start.minute;
      final endMinutes = end.hour * 60 + end.minute;

      // Generate times in 30-minute intervals
      for (int minutes = startMinutes; minutes <= endMinutes; minutes += 30) {
        final hour = minutes ~/ 60;
        final minute = minutes % 60;
        times.add(TimeOfDay(hour: hour, minute: minute));
      }
    }

    return times;
  }

  // Find the closest valid time to the initial time
  TimeOfDay _findClosestValidTime(TimeOfDay time) {
    // If no time range, just round to nearest 30 minutes
    if (widget.timeRange == null) {
      final minutes = time.hour * 60 + time.minute;
      final roundedMinutes = (minutes / 30).round() * 30;
      return TimeOfDay(
        hour: (roundedMinutes ~/ 60) % 24,
        minute: roundedMinutes % 60,
      );
    }

    // If there's a time range, find the closest time within range
    final times = _generateAvailableTimes();
    if (times.isEmpty) {
      return const TimeOfDay(hour: 0, minute: 0);
    }

    // Check if time is already in the list
    for (final t in times) {
      if (t.hour == time.hour && t.minute == time.minute) {
        return time;
      }
    }

    // Find closest time
    final timeInMinutes = time.hour * 60 + time.minute;
    int minDifference = 24 * 60; // Maximum possible difference
    TimeOfDay closestTime = times.first;

    for (final t in times) {
      final tMinutes = t.hour * 60 + t.minute;
      final difference = (tMinutes - timeInMinutes).abs();

      if (difference < minDifference) {
        minDifference = difference;
        closestTime = t;
      }
    }

    return closestTime;
  }

  @override
  Widget build(BuildContext context) {
    // Get range title based on type
    String rangeTitle = 'Pilih Waktu';
    if (widget.timeRange != null) {
      switch (widget.timeRange!.type) {
        case TimeRangeType.morning:
          rangeTitle = 'Pilih Waktu Pagi (05:00 - 09:00)';
          break;
        case TimeRangeType.afternoon:
          rangeTitle = 'Pilih Waktu Siang (11:00 - 15:00)';
          break;
        case TimeRangeType.evening:
          rangeTitle = 'Pilih Waktu Malam (17:00 - 21:00)';
          break;
        default:
          rangeTitle = 'Pilih Waktu';
      }
    }

    return AlertDialog(
      title: Text(rangeTitle),
      content: SizedBox(
        height: 300,
        width: 300,
        child: ListView.builder(
          itemCount: availableTimes.length,
          itemBuilder: (context, index) {
            final timeOption = availableTimes[index];
            final isSelected =
                selectedTime.hour == timeOption.hour &&
                selectedTime.minute == timeOption.minute;

            // Format time in 24-hour format
            final hour = timeOption.hour.toString().padLeft(2, '0');
            final minute = timeOption.minute.toString().padLeft(2, '0');
            final formatted = '$hour:$minute';

            return ListTile(
              title: Text(
                formatted,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Theme.of(context).primaryColor : null,
                ),
              ),
              onTap: () {
                setState(() {
                  selectedTime = timeOption;
                });
              },
              selected: isSelected,
              trailing:
                  isSelected
                      ? Icon(Icons.check, color: Theme.of(context).primaryColor)
                      : null,
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Batal'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, selectedTime),
          child: Text('OK'),
        ),
      ],
    );
  }
}

class CustomDatePickerField extends StatelessWidget {
  final String title;
  final String hintText;
  final TextEditingController controller;
  final void Function(DateTime?) onDatePicked;
  final String? errorText;

  const CustomDatePickerField({
    super.key,
    required this.title,
    required this.hintText,
    required this.controller,
    required this.onDatePicked,
    this.errorText,
  });

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      controller.text = "${picked.day}/${picked.month}/${picked.year}";
      onDatePicked(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final borderColor =
        errorText != null
            ? AppColors.danger.shade300
            : AppColors.neutral.shade900;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppFonts.medium(
            14,
          ).copyWith(color: AppColors.neutral.shade600),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () => _selectDate(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: borderColor, width: 1.0),
              borderRadius: BorderRadius.circular(10),
              color: Colors.white,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  controller.text.isNotEmpty ? controller.text : hintText,
                  style: AppFonts.medium(14).copyWith(
                    color:
                        controller.text.isNotEmpty
                            ? AppColors.neutral.shade900
                            : AppColors.neutral.shade400,
                  ),
                ),
                Icon(Icons.calendar_month),
              ],
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 4),
          Text(
            errorText!,
            style: AppFonts.medium(
              12,
            ).copyWith(color: AppColors.danger.shade300),
          ),
        ],
      ],
    );
  }
}

class CustomCheckboxField extends StatelessWidget {
  final String title;
  final List<String> items;
  final List<String> selectedItems;
  final ValueChanged<List<String>> onChanged;

  const CustomCheckboxField({
    super.key,
    required this.title,
    required this.items,
    required this.selectedItems,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppFonts.medium(
            14,
          ).copyWith(color: AppColors.neutral.shade600),
        ),
        const SizedBox(height: 4),
        ...items.map((item) {
          final isSelected = selectedItems.contains(item);
          return CheckboxListTile(
            value: isSelected,
            title: Text(
              item,
              style: AppFonts.medium(
                14,
              ).copyWith(color: AppColors.neutral.shade900),
            ),
            onChanged: (bool? checked) {
              List<String> updatedSelectedItems = List.from(selectedItems);
              if (checked == true) {
                updatedSelectedItems.add(item);
              } else {
                updatedSelectedItems.remove(item);
              }
              onChanged(updatedSelectedItems);
            },
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: AppColors.secondary.shade400,
            dense: true,
            contentPadding: EdgeInsets.zero,
          );
        }).toList(),
      ],
    );
  }
}
