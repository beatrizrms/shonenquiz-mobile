class AuthTokens {
  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final int expiresIn;

  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.expiresIn,
  });

  factory AuthTokens.fromJson(Map<String, dynamic> json) => AuthTokens(
    accessToken:  json['accessToken']  as String,
    refreshToken: json['refreshToken'] as String,
    tokenType:    json['tokenType']    as String,
    expiresIn:    json['expiresIn']    as int,
  );
}
