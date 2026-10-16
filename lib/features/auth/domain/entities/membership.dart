import 'package:equatable/equatable.dart';

import 'tenant.dart';

class Membership extends Equatable {
  const Membership({
    required this.tenant,
    required this.role,
    required this.isActive,
  });

  final Tenant tenant;
  final String role;
  final bool isActive;

  @override
  List<Object?> get props => [tenant, role, isActive];
}
