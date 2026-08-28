/// Thrown when a production/store build is misconfigured.
///
/// This is intentional: production must fail closed instead of silently
/// falling back to the on-device demo backend.
class ProductionConfigException implements Exception {
  const ProductionConfigException(this.message);

  final String message;

  @override
  String toString() => 'ProductionConfigException: $message';
}
