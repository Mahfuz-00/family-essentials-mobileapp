import 'package:equatable/equatable.dart';

class Tenant extends Equatable {
  const Tenant({
    required this.id,
    required this.name,
    required this.slug,
    required this.status,
    required this.subscriptionTier,
  });

  final int id;
  final String name;
  final String slug;
  final String status;
  final String subscriptionTier;

  @override
  List<Object?> get props => [id, name, slug, status, subscriptionTier];
}
