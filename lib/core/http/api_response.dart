class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final int code;

  ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.code = 0,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json, {T Function(dynamic)? fromData}) {
    final code = json['code'] as int? ?? -1;
    final success = code == 0;
    return ApiResponse(
      success: success,
      code: code,
      message: json['message'] as String?,
      data: success && fromData != null ? fromData(json['data']) : json['data'] as T?,
    );
  }
}
