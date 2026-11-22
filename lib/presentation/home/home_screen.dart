import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';
import '../../data/db.dart';
import '../../data/models.dart';
import '../../data/providers.dart';
import '../patients/patient_profile_screen.dart';
import '../shell/app_shell.dart';
import '../sync/sync_status_screen.dart';
import '../view_models.dart';

const _weekdays = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

