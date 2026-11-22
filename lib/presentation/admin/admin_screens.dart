
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/auth/auth_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';
import '../../data/providers.dart';
import '../../domain/entities/supervision.dart';
import '../auth/login_controller.dart';
import '../patients/patients_screen.dart';
import '../view_models.dart';

final resetRequestsProvider =
    FutureProvider.autoDispose<List<ResetRequest>>(
  (ref) => ref.watch(adminRepositoryProvider).resetRequests(),
);

final centresProvider =
    FutureProvider.autoDispose<List<HealthCentre>>(
  (ref) => ref.watch(adminRepositoryProvider).centres(),
);

class ResetRequestsScreen extends ConsumerStatefulWidget {
  const ResetRequestsScreen({super.key});

  @override
  ConsumerState<ResetRequestsScreen> createState() =>
      _ResetRequestsScreenState();
}

class _ResetRequestsScreenState
    extends ConsumerState<ResetRequestsScreen> {
  final Set<String> _approving = {};

  Future<void> _approve(ResetRequest request) async {
    if (_approving.contains(request.id)) return;

    setState(() => _approving.add(request.id));

    try {
      await ref
          .read(adminRepositoryProvider)
          .approve(request.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Code sent to '
            '${request.name ?? request.phone ?? 'the user'}.',
          ),
        ),
      );

      ref.invalidate(resetRequestsProvider);
    } on ApiException catch (error) {
      if (!mounted) return;

      final message = error.code == 'sms_failed'
          ? 'The SMS could not be sent. Try again.'
          : 'Could not approve the request. '
              'Check your connection.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not approve the request.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _approving.remove(request.id));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final requests = ref.watch(resetRequestsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        await ref.refresh(resetRequestsProvider.future);
      },
      child: PageBody(
        children: [
          const PageHeader(
            title: 'Reset requests',
            subtitle:
                'Approving a request sends a one-time code '
                'to the account holder.',
          ),

          ...requests.when(
            loading: () => [
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ],
            error: (_, _) => [
              Text(
                'Could not load reset requests. '
                'Check your connection and refresh.',
                style: HbText.bodySmall.copyWith(
                  color: HbColors.red,
                ),
              ),
            ],
            data: (list) => [
              if (list.isEmpty)
                Text(
                  'There are no pending reset requests.',
                  style: HbText.bodySmall,
                ),

              for (final request in list)
                HbCard(
                  child: Row(
                    children: [
                      HbAvatar(request.name ?? '?'),
                      const SizedBox(width: 12),

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              request.name ?? 'Unknown user',
                              style: HbText.headingSmall,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              [
                                if (request.role != null)
                                  request.role!.toUpperCase(),
                                if (request.phone != null)
                                  request.phone!,
                                if (request.createdAt != null)
                                  '${relativeDay(request.createdAt!)} '
                                      '${clock(request.createdAt!)}',
                              ].join(' · '),
                              style: HbText.bodySmall,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 8),

                      FilledButton(
                        onPressed:
                            _approving.contains(request.id)
                                ? null
                                : () => _approve(request),
                        style: FilledButton.styleFrom(
                          backgroundColor: HbColors.ink,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(48, 48),
                          shape: const StadiumBorder(),
                        ),
                        child: Text(
                          _approving.contains(request.id)
                              ? 'Sending'
                              : 'Approve',
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class NewAccountState {
  const NewAccountState({
    this.role = 'chw',
    this.chwRole = 'asm',
    this.centreId,
    this.busy = false,
  });

  final String role;
  final String chwRole;
  final String? centreId;
  final bool busy;

  NewAccountState copyWith({
    String? role,
    String? chwRole,
    String? Function()? centreId,
    bool? busy,
  }) {
    return NewAccountState(
      role: role ?? this.role,
      chwRole: chwRole ?? this.chwRole,
      centreId:
          centreId != null ? centreId() : this.centreId,
      busy: busy ?? this.busy,
    );
  }
}

class NewAccountController extends Notifier<NewAccountState> {
  @override
  NewAccountState build() => const NewAccountState();

  void setRole(String role) {
    if (state.busy) return;
    if (role != 'chw' && role != 'supervisor') return;

    state = state.copyWith(role: role);
  }

  void setChwRole(String role) {
    if (state.busy) return;
    if (role != 'asm' && role != 'binome') return;

    state = state.copyWith(chwRole: role);
  }

  void setCentre(String id) {
    if (state.busy) return;

    state = state.copyWith(
      centreId: () => id,
    );
  }

  Future<String?> create(
    Map<String, Object?> fields,
  ) async {
    if (state.busy) {
      return 'An account is already being created.';
    }

    if (state.centreId == null) {
      return 'Choose a health centre.';
    }

    state = state.copyWith(busy: true);

    try {
      final smsSent = await ref
          .read(adminRepositoryProvider)
          .createUser({
        ...fields,
        'role': state.role,
        'healthCenterId': state.centreId,
        if (state.role == 'chw')
          'chwRole': state.chwRole,
      });

      return smsSent
          ? null
          : 'Account created, but the SMS with the '
              'sign-in details was not sent. '
              'The user can request a credential reset.';
    } on ApiException catch (error) {
      return switch (error.code) {
        'phone_or_email_taken' =>
          'That phone number or email already has an account.',
        'unknown_health_center' =>
          'Choose a valid health centre.',
        'invalid_request' =>
          'Check the account details and try again.',
        _ =>
          'Could not create the account. '
              'Check your connection.',
      };
    } catch (_) {
      return 'Could not create the account. Please try again.';
    } finally {
      if (ref.mounted) {
        state = state.copyWith(busy: false);
      }
    }
  }
}

final newAccountProvider =
    NotifierProvider.autoDispose<
      NewAccountController,
      NewAccountState
    >(
      NewAccountController.new,
    );

class NewAccountScreen extends ConsumerStatefulWidget {
  const NewAccountScreen({super.key});

  @override
  ConsumerState<NewAccountScreen> createState() =>
      _NewAccountScreenState();
}

class _NewAccountScreenState
    extends ConsumerState<NewAccountScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _village = TextEditingController();
  final _email = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _village.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _create(NewAccountState state) async {
    if (state.busy) return;
    if (!(_form.currentState?.validate() ?? false)) {
      return;
    }

    FocusScope.of(context).unfocus();

    final isChw = state.role == 'chw';

    final error = await ref
        .read(newAccountProvider.notifier)
        .create({
      'fullName': _name.text.trim(),
      'phone': normalizePhone(_phone.text),
      if (isChw) 'village': _village.text.trim(),
      if (_email.text.trim().isNotEmpty)
        'email': _email.text.trim(),
    });

    if (!mounted) return;

    if (error == null ||
        error.startsWith('Account created')) {
      _name.clear();
      _phone.clear();
      _village.clear();
      _email.clear();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error ??
              'Account created. Sign-in details '
                  'were sent by SMS.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(newAccountProvider);
    final controller =
        ref.read(newAccountProvider.notifier);
    final centres = ref.watch(centresProvider);
    final isChw = state.role == 'chw';

    return Form(
      key: _form,
      child: PageBody(
        children: [
          const PageHeader(
            title: 'New account',
            subtitle:
                'The user receives temporary credentials '
                'and must change them after signing in.',
          ),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChipPill(
                label: 'CHW',
                selected: isChw,
                onTap: () => controller.setRole('chw'),
              ),
              ChoiceChipPill(
                label: 'Supervisor',
                selected: !isChw,
                onTap: () =>
                    controller.setRole('supervisor'),
              ),
            ],
          ),

          centres.when(
            loading: () =>
                const LinearProgressIndicator(),
            error: (_, _) => Text(
              'Could not load health centres.',
              style: HbText.bodySmall.copyWith(
                color: HbColors.red,
              ),
            ),
            data: (list) =>
                DropdownButtonFormField<String>(
              initialValue: list.any(
                (centre) => centre.id == state.centreId,
              )
                  ? state.centreId
                  : null,
              decoration: const InputDecoration(
                labelText: 'Health centre',
              ),
              items: [
                for (final centre in list)
                  DropdownMenuItem<String>(
                    value: centre.id,
                    child: Text(centre.name),
                  ),
              ],
              onChanged: state.busy
                  ? null
                  : (value) {
                      if (value != null) {
                        controller.setCentre(value);
                      }
                    },
              validator: (value) =>
                  value == null
                      ? 'Choose a health centre.'
                      : null,
            ),
          ),

          HbTextField(
            label: 'Full name',
            hint: 'Name',
            controller: _name,
            validator: requiredField,
          ),

          HbTextField(
            label: 'Phone number',
            hint: 'e.g. 0788 123 456',
            controller: _phone,
            keyboardType: TextInputType.phone,
            validator: validatePhone,
          ),

          if (isChw) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChipPill(
                  label: 'ASM',
                  selected: state.chwRole == 'asm',
                  onTap: () =>
                      controller.setChwRole('asm'),
                ),
                ChoiceChipPill(
                  label: 'Binome',
                  selected:
                      state.chwRole == 'binome',
                  onTap: () =>
                      controller.setChwRole('binome'),
                ),
              ],
            ),

            HbTextField(
              label: 'Village',
              hint: 'Village',
              controller: _village,
              validator: requiredField,
            ),
          ],

          HbTextField(
            label: isChw ? 'Email (optional)' : 'Email',
            hint: 'you@example.org',
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (isChw &&
                  (value == null ||
                      value.trim().isEmpty)) {
                return null;
              }

              return validateEmail(value);
            },
          ),

          HbButton.primary(
            state.busy
                ? 'Creating account...'
                : 'Create account',
            onPressed: state.busy
                ? null
                : () => _create(state),
          ),
        ],
      ),
    );
  }
}

class NewCentreController extends Notifier<bool> {
  @override
  bool build() => false;

  Future<String?> create({
    required String name,
    required String district,
    required String sector,
    String? callNumber,
  }) async {
    if (state) {
      return 'A health centre is already being saved.';
    }

    state = true;

    try {
      await ref
          .read(adminRepositoryProvider)
          .createCentre(
        name: name.trim(),
        district: district.trim(),
        sector: sector.trim(),
        callNumber: callNumber,
      );

      if (ref.mounted) {
        ref.invalidate(centresProvider);
      }

      return null;
    } on ApiException catch (error) {
      return error.code == 'invalid_request'
          ? 'Check the fields and try again.'
          : 'Could not save the health centre. '
              'Check your connection.';
    } catch (_) {
      return 'Could not save the health centre. '
          'Please try again.';
    } finally {
      if (ref.mounted) {
        state = false;
      }
    }
  }
}

final newCentreProvider =
    NotifierProvider.autoDispose<NewCentreController, bool>(
      NewCentreController.new,
    );

class CentresScreen extends ConsumerStatefulWidget {
  const CentresScreen({super.key});

  @override
  ConsumerState<CentresScreen> createState() =>
      _CentresScreenState();
}

class _CentresScreenState extends ConsumerState<CentresScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _district = TextEditingController();
  final _sector = TextEditingController();
  final _call = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _district.dispose();
    _sector.dispose();
    _call.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (!(_form.currentState?.validate() ?? false)) {
      return;
    }

    if (ref.read(newCentreProvider)) return;

    FocusScope.of(context).unfocus();

    final call = _call.text.trim();

    final error = await ref
        .read(newCentreProvider.notifier)
        .create(
      name: _name.text,
      district: _district.text,
      sector: _sector.text,
      callNumber:
          call.isEmpty ? null : normalizePhone(call),
    );

    if (!mounted) return;

    if (error == null) {
      _name.clear();
      _district.clear();
      _sector.clear();
      _call.clear();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error ?? 'Health centre added successfully.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final busy = ref.watch(newCentreProvider);
    final centres = ref.watch(centresProvider);

    return Form(
      key: _form,
      child: PageBody(
        children: [
          const PageHeader(
            title: 'Health centres',
            subtitle:
                'Manage the health centres assigned to users.',
          ),

          ...centres.when(
            loading: () => [
              const LinearProgressIndicator(),
            ],
            error: (_, _) => [
              Text(
                'Could not load health centres.',
                style: HbText.bodySmall.copyWith(
                  color: HbColors.red,
                ),
              ),
            ],
            data: (list) => [
              if (list.isEmpty)
                Text(
                  'No health centres have been added.',
                  style: HbText.bodySmall,
                ),

              if (list.isNotEmpty)
                HbCard(
                  padding:
                      const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    children: [
                      for (final (index, centre)
                          in list.indexed) ...[
                        if (index > 0)
                          const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 18,
                            ),
                            child: HbDivider(),
                          ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 14,
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.local_hospital_outlined,
                                color: HbColors.brand,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  centre.name,
                                  style: HbText.headingSmall,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          ),

          const SectionHeading('New health centre'),

          HbTextField(
            label: 'Name',
            hint: 'e.g. Nyamata Health Centre',
            controller: _name,
            validator: (value) {
              final missing = requiredField(value);
              if (missing != null) return missing;

              return value!.trim().length < 2
                  ? 'Enter at least 2 characters.'
                  : null;
            },
          ),

          HbTextField(
            label: 'District',
            hint: 'District',
            controller: _district,
            validator: requiredField,
          ),

          HbTextField(
            label: 'Sector',
            hint: 'Sector',
            controller: _sector,
            validator: requiredField,
          ),

          HbTextField(
            label: 'Call number (optional)',
            hint: 'For urgent-case calls',
            controller: _call,
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null ||
                  value.trim().isEmpty) {
                return null;
              }

              return validatePhone(value);
            },
          ),

          HbButton.primary(
            busy ? 'Saving...' : 'Add health centre',
            onPressed: busy ? null : _create,
          ),
        ],
      ),
    );
  }
}
