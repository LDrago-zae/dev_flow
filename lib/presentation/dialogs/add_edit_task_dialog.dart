import 'package:flutter/material.dart';
import 'package:dev_flow/core/constants/app_colors.dart';
import 'package:dev_flow/core/utils/app_text_styles.dart';
import 'package:dev_flow/data/models/task_model.dart';
import 'package:dev_flow/presentation/widgets/user_dropdown.dart';
import 'package:dev_flow/services/location_service.dart';
import 'package:geolocator/geolocator.dart';

class AddEditTaskDialog {
  static void show(
    BuildContext context, {
    Task? task,
    required DateTime initialDate,
    required TimeOfDay initialTime,
    required Function(
      String title,
      DateTime date,
      TimeOfDay time,
      String? assignedUserId,
      String? locationName,
      double? latitude,
      double? longitude,
      bool isRecurring,
      String? recurrencePattern,
    )
    onSubmit,
  }) {
    final titleController = TextEditingController(text: task?.title ?? '');
    DateTime selectedDate = task?.date ?? initialDate;
    TimeOfDay selectedTime = initialTime;
    String? selectedUserId = task?.assignedUserId;
    String? locationName = task?.locationName;
    double? latitude = task?.latitude;
    double? longitude = task?.longitude;
    bool isRecurring = task?.isRecurring ?? false;
    String? recurrencePattern = task?.recurrencePattern;
    final bool isEditing = task != null;
    final locationService = LocationService();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEditing ? 'Edit Task' : 'Add New Task',
                      style: AppTextStyles.headlineSmall.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: titleController,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: DarkThemeColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Task title',
                        hintStyle: AppTextStyles.bodyMedium.copyWith(
                          color: DarkThemeColors.textSecondary,
                        ),
                        filled: true,
                        fillColor: Colors.black,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    UserDropdown(
                      selectedUserId: selectedUserId,
                      onUserSelected: (userId) {
                        setModalState(() {
                          // Only accept valid UUIDs or null, ignore dummy user IDs
                          if (userId == null || userId.length > 30) {
                            selectedUserId = userId;
                          } else {
                            // If it's a dummy user ID (like '1', '2', etc), set to null
                            selectedUserId = null;
                          }
                        });
                      },
                      hintText: 'Assign task to user',
                    ),
                    const SizedBox(height: 16),
                    _buildLocationSection(
                      context,
                      locationName,
                      latitude,
                      longitude,
                      locationService,
                      (name, lat, lng) {
                        setModalState(() {
                          locationName = name;
                          latitude = lat;
                          longitude = lng;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDatePicker(context, selectedDate, (
                            date,
                          ) {
                            setModalState(() {
                              selectedDate = date;
                            });
                          }),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTimePicker(context, selectedTime, (
                            time,
                          ) {
                            setModalState(() {
                              selectedTime = time;
                            });
                          }),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Text(
                      'Repeat',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: DarkThemeColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildRecurrenceChip(
                          context,
                          'None',
                          !isRecurring || recurrencePattern == null,
                          () {
                            setModalState(() {
                              isRecurring = false;
                              recurrencePattern = null;
                            });
                          },
                        ),
                        _buildRecurrenceChip(
                          context,
                          'Daily',
                          recurrencePattern == 'daily',
                          () {
                            setModalState(() {
                              isRecurring = true;
                              recurrencePattern = 'daily';
                            });
                          },
                        ),
                        _buildRecurrenceChip(
                          context,
                          'Weekdays',
                          recurrencePattern == 'weekdays',
                          () {
                            setModalState(() {
                              isRecurring = true;
                              recurrencePattern = 'weekdays';
                            });
                          },
                        ),
                        _buildRecurrenceChip(
                          context,
                          'Weekly',
                          recurrencePattern == 'weekly',
                          () {
                            setModalState(() {
                              isRecurring = true;
                              recurrencePattern = 'weekly';
                            });
                          },
                        ),
                        _buildRecurrenceChip(
                          context,
                          'Monthly',
                          recurrencePattern == 'monthly',
                          () {
                            setModalState(() {
                              isRecurring = true;
                              recurrencePattern = 'monthly';
                            });
                          },
                        ),
                        _buildRecurrenceChip(
                          context,
                          'Yearly',
                          recurrencePattern == 'yearly',
                          () {
                            setModalState(() {
                              isRecurring = true;
                              recurrencePattern = 'yearly';
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (titleController.text.trim().isNotEmpty) {
                            onSubmit(
                              titleController.text.trim(),
                              selectedDate,
                              selectedTime,
                              selectedUserId,
                              locationName,
                              latitude,
                              longitude,
                              isRecurring,
                              recurrencePattern,
                            );
                            Navigator.pop(context);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: DarkThemeColors.primary100,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          isEditing ? 'Update Task' : 'Add Task',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  static Widget _buildDatePicker(
    BuildContext context,
    DateTime selectedDate,
    Function(DateTime) onDateSelected,
  ) {
    return GestureDetector(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: selectedDate,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (date != null) {
          onDateSelected(date);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today,
              size: 20,
              color: DarkThemeColors.textSecondary,
            ),
            const SizedBox(width: 12),
            Text(
              '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
              style: AppTextStyles.bodyMedium.copyWith(
                color: DarkThemeColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildTimePicker(
    BuildContext context,
    TimeOfDay selectedTime,
    Function(TimeOfDay) onTimeSelected,
  ) {
    return GestureDetector(
      onTap: () async {
        final time = await showTimePicker(
          context: context,
          initialTime: selectedTime,
        );
        if (time != null) {
          onTimeSelected(time);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              Icons.access_time,
              size: 20,
              color: DarkThemeColors.textSecondary,
            ),
            const SizedBox(width: 12),
            Text(
              '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
              style: AppTextStyles.bodyMedium.copyWith(
                color: DarkThemeColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildLocationSection(
    BuildContext context,
    String? locationName,
    double? latitude,
    double? longitude,
    LocationService locationService,
    Function(String?, double?, double?) onLocationSelected,
  ) {
    final hasLocation = latitude != null && longitude != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.location_on,
              size: 20,
              color: DarkThemeColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              'Location (Optional)',
              style: AppTextStyles.bodyMedium.copyWith(
                color: DarkThemeColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (hasLocation)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        locationName ?? 'Current Location',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: DarkThemeColors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${latitude!.toStringAsFixed(4)}, ${longitude!.toStringAsFixed(4)}',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: DarkThemeColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: DarkThemeColors.error),
                  onPressed: () => onLocationSelected(null, null, null),
                ),
              ],
            ),
          )
        else
          Wrap(
            spacing: 8,
            children: [
              _buildLocationChip(
                context,
                'Current Location',
                Icons.my_location,
                () async {
                  final position = await locationService.getCurrentLocation();
                  if (position != null) {
                    onLocationSelected(
                      'Current Location',
                      position.latitude,
                      position.longitude,
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Unable to get current location. Please enable GPS and location permissions.',
                        ),
                      ),
                    );
                  }
                },
              ),
              _buildLocationChip(context, 'Home', Icons.home, () {
                // For demo - you can save user's home location in preferences
                onLocationSelected('Home', 0.0, 0.0);
              }),
              _buildLocationChip(context, 'Office', Icons.business, () {
                // For demo - you can save user's office location in preferences
                onLocationSelected('Office', 0.0, 0.0);
              }),
            ],
          ),
      ],
    );
  }

  static Widget _buildRecurrenceChip(
    BuildContext context,
    String label,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? DarkThemeColors.primary100.withOpacity(0.12)
              : DarkThemeColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? DarkThemeColors.primary100
                : DarkThemeColors.textSecondary.withOpacity(0.2),
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: isSelected
                ? DarkThemeColors.primary100
                : DarkThemeColors.textPrimary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  static Widget _buildLocationChip(
    BuildContext context,
    String label,
    IconData icon,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: DarkThemeColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: DarkThemeColors.textSecondary.withOpacity(0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: DarkThemeColors.primary100),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: DarkThemeColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
