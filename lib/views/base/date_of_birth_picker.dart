import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:ree_social_media_app/utils/app_colors.dart';
import 'package:ree_social_media_app/views/base/custom_text_field.dart';

class DateOfBirthField extends StatefulWidget {
  final TextEditingController controller;

  const DateOfBirthField({super.key, required this.controller});

  @override
  State<DateOfBirthField> createState() => _DateOfBirthFieldState();
}

class _DateOfBirthFieldState extends State<DateOfBirthField> {
  DateTime _selectedDate = DateTime.now();

  Future<void> _selectDate(BuildContext context) async {
    DateTime tempPickedDate = _selectedDate;

    await showModalBottomSheet(
      context: context,
      builder: (BuildContext builder) {
        return Container(
          height: 300,
          color: Colors.white,
          child: Column(
            children: [
              // Done Button
              Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedDate = tempPickedDate;
                      widget.controller.text = DateFormat(
                        'MM/dd/yyyy',
                      ).format(_selectedDate);
                    });
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Done',
                    style: TextStyle(
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              // Cupertino Date Picker
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: _selectedDate,
                  minimumDate: DateTime(1900),
                  maximumDate: DateTime.now(),
                  onDateTimeChanged: (DateTime newDate) {
                    tempPickedDate = newDate;
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      isRealOnly: true,
      onTap: () => _selectDate(context),
      controller: widget.controller,
      hintText: 'Enter your birthday',
      borderSide: const BorderSide(color: Color(0xFFC4C3C3), width: 1),
      prefixIcon: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          height: 24,
          width: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primaryColor,
          ),
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: SvgPicture.asset('assets/icons/dateOfBirth.svg'),
          ),
        ),
      ),
      suffixIcon: Padding(
        padding: const EdgeInsets.all(14),
        child: SizedBox(
          height: 16,
          width: 16,
          child: SvgPicture.asset(
            'assets/icons/calender_blue.svg',
            height: 16,
            width: 16,
          ),
        ),
      ),
    );
  }
}
