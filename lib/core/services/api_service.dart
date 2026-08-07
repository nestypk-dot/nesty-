import 'package:hooks_riverpod/hooks_riverpod.dart';

// This would typically use Dio or Http
class ApiService {
  Future<dynamic> get(String path) async {
    // Implement API call logic
    return {};
  }

  Future<dynamic> post(String path, dynamic data) async {
    // Implement API call logic
    return {};
  }
}

final apiServiceProvider = Provider((ref) => ApiService());
