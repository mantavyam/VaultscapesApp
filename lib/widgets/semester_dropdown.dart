import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_strings.dart';
import '../core/constants/app_constants.dart';
import '../providers/preferences_provider.dart';

class SemesterDropdown extends StatelessWidget {
  const SemesterDropdown({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PreferencesProvider>(
      builder: (context, preferencesProvider, child) {
        return ListTile(
          leading: const Icon(Icons.school),
          title: const Text('Semester'),
          subtitle: Text(preferencesProvider.semesterDisplayString),
          trailing: const Icon(Icons.arrow_drop_down),
          onTap: () => _showSemesterPicker(context, preferencesProvider),
        );
      },
    );
  }

  void _showSemesterPicker(BuildContext context, PreferencesProvider preferencesProvider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSizes.borderRadiusLarge),
        ),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag Handle
              Container(
                width: AppSizes.dragHandleWidth,
                height: AppSizes.dragHandleHeight,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(AppSizes.dragHandleHeight / 2),
                ),
              ),
              
              const SizedBox(height: AppSpacing.md),
              
              // Title
              Text(
                'Select Semester',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              
              const SizedBox(height: AppSpacing.md),
              
              // Options
              ...preferencesProvider.getSemesterOptions().map(
                (option) => RadioListTile<int?>(
                  title: Text(option.display),
                  value: option.value,
                  groupValue: preferencesProvider.semesterPreference,
                  onChanged: (value) async {
                    await preferencesProvider.setSemesterPreference(value);
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}