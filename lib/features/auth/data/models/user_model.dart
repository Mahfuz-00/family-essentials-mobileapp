import '../../domain/entities/membership.dart';
import '../../domain/entities/tenant.dart';
import '../../domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.name,
    required super.email,
    required super.emailVerified,
    required super.phoneVerified,
    super.phone,
    super.isPlatformAdmin,
    super.voiceOptIn,
    super.locationNotificationsOptIn,
    super.activeTenantId,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      emailVerified: json['email_verified'] as bool? ?? false,
      phoneVerified: json['phone_verified'] as bool? ?? false,
      isPlatformAdmin: json['is_platform_admin'] as bool? ?? false,
      voiceOptIn: json['voice_opt_in'] as bool? ?? false,
      locationNotificationsOptIn:
          json['location_notifications_opt_in'] as bool? ?? false,
      activeTenantId: json['active_tenant_id'] as int?,
    );
  }
}

class TenantModel extends Tenant {
  const TenantModel({
    required super.id,
    required super.name,
    required super.slug,
    required super.status,
    required super.subscriptionTier,
  });

  factory TenantModel.fromJson(Map<String, dynamic> json) {
    return TenantModel(
      id: json['id'] as int,
      name: json['name'] as String,
      slug: json['slug'] as String? ?? '',
      status: json['status'] as String? ?? 'active',
      subscriptionTier: json['subscription_tier'] as String? ?? 'pilot',
    );
  }
}

class MembershipModel extends Membership {
  const MembershipModel({
    required super.tenant,
    required super.role,
    required super.isActive,
  });

  factory MembershipModel.fromJson(Map<String, dynamic> json) {
    return MembershipModel(
      tenant: TenantModel.fromJson(
        (json['tenant'] as Map).cast<String, dynamic>(),
      ),
      role: json['role'] as String? ?? 'member',
      isActive: json['is_active'] as bool? ?? false,
    );
  }
}

class AuthResult {
  const AuthResult({required this.token, required this.user});

  final String token;
  final UserModel user;

  factory AuthResult.fromJson(Map<String, dynamic> json) {
    return AuthResult(
      token: json['token'] as String,
      user: UserModel.fromJson((json['user'] as Map).cast<String, dynamic>()),
    );
  }
}
