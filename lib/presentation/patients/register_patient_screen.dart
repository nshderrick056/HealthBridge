
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';
import '../../data/db.dart';
import 'patients_screen.dart';
import 'register_patient_controller.dart';

class RegisterPatientScreen extends ConsumerStatefulWidget {
  const RegisterPatientScreen({
    super.key,
    this.patient,
  });

  final Patient? patient;

  @override
  ConsumerState<RegisterPatientScreen> createState() =>
      _RegisterPatientScreenState();
}

class _RegisterPatientScreenState
    extends ConsumerState<RegisterPatientScreen> {
  final _form = GlobalKey<FormState>();

  late final _name = TextEditingController(
    text: widget.patient?.fullName,
  );
  late final _village = TextEditingController(
    text: widget.patient?.village,
  );
  late final _age = TextEditingController(
    text: widget.patient?.ageEstimate?.toString(),
  );
  late final _phone = TextEditingController(
    text: widget.patient?.phone,
  );

  bool get _editing => widget.patient != null;

  @override
  void dispose() {
    _name.dispose();
    _village.dispose();
    _age.dispose();
    _phone.dispose();
    super.dispose();
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required.';
    }
    return null;
  }

  Future<void> _save() async {
    if (!(_form.currentState?.validate() ?? false)) return;

    final provider = registerPatientProvider(widget.patient);
    final choices = ref.read(provider);

    if (choices.busy || !choices.consent) return;

    FocusScope.of(context).unfocus();

    try {
      await ref.read(provider.notifier).save(
            fullName: _name.text,
            village: _village.text,
            age: _age.text,
            phone: _phone.text,
          );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _editing
                ? 'Patient information updated.'
                : 'Patient saved successfully.',
          ),
        ),
      );

      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not save the patient. Please try again.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = registerPatientProvider(widget.patient);
    final choices = ref.watch(provider);
    final controller = ref.read(provider.notifier);

    return Scaffold(
      backgroundColor: HbColors.canvas,
      appBar: AppBar(
        backgroundColor: HbColors.canvas,
        foregroundColor: HbColors.ink,
        elevation: 0,
      ),
      body: SafeArea(
        child: Form(
          key: _form,
          child: ListView(
            keyboardDismissBehavior:
                ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(
              20, 8, 20, 32,
            ),
            children: [
              PageHeader(
                title: _editing
                    ? 'Edit patient'
                    : 'Register patient',
                subtitle:
                    'Information is saved on this device '
                    'and synchronized when online.',
              ),

              const SizedBox(height: 24),

              HbTextField(
                label: 'Full name',
                hint: 'Enter the patient’s full name',
                controller: _name,
                validator: _required,
              ),

              const SizedBox(height: 16),

              HbTextField(
                label: 'Village',
                hint: 'Enter the village',
                controller: _village,
                validator: _required,
              ),

              const SizedBox(height: 20),

              Text(
                'Sex',
                style: HbText.labelMedium,
              ),

              const SizedBox(height: 10),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChipPill(
                    label: 'Female',
                    selected: choices.sex == 'F',
                    onTap: () => controller.setSex('F'),
                  ),
                  ChoiceChipPill(
                    label: 'Male',
                    selected: choices.sex == 'M',
                    onTap: () => controller.setSex('M'),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              HbTextField(
                label: 'Age (years)',
                hint: 'Estimated age (optional)',
                controller: _age,
                keyboardType: TextInputType.number,
                validator: validateAge,
              ),

              const SizedBox(height: 16),

              HbTextField(
                label: 'Phone number',
                hint: 'Optional phone number',
                controller: _phone,
                keyboardType: TextInputType.phone,
              ),

              if (!_editing) ...[
                const SizedBox(height: 20),
                HbCard(
                  onTap: choices.busy
                      ? null
                      : () => controller.setConsent(
                            !choices.consent,
                          ),
                  child: Row(
                    children: [
                      Checkbox(
                        value: choices.consent,
                        onChanged: choices.busy
                            ? null
                            : (value) => controller.setConsent(
                                  value ?? false,
                                ),
                      ),
                      Expanded(
                        child: Text(
                          'The patient has agreed to have '
                          'their health information recorded.',
                          style: HbText.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              HbButton.primary(
                choices.busy
                    ? 'Saving patient...'
                    : _editing
                        ? 'Save changes'
                        : 'Save patient',
                onPressed:
                    choices.busy || !choices.consent
                        ? null
                        : _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
