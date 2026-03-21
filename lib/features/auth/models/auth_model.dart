// To parse this JSON data, do
//
//     final authModel = authModelFromJson(jsonString);

import 'dart:convert';

AuthModel authModelFromJson(String str) => AuthModel.fromJson(json.decode(str));

String authModelToJson(AuthModel data) => json.encode(data.toJson());

class AuthModel {
  AuthUser? user;
  String? accessToken;
  String? refreshToken;
  String? tokenType;

  AuthModel({this.user, this.accessToken, this.refreshToken, this.tokenType});

  factory AuthModel.fromJson(Map<String, dynamic> json) => AuthModel(
    user: json["user"] == null ? null : AuthUser.fromJson(json["user"]),
    accessToken: json["access_token"],
    refreshToken: json["refresh_token"],
    tokenType: json["token_type"],
  );

  Map<String, dynamic> toJson() => {
    "user": user?.toJson(),
    "access_token": accessToken,
    "refresh_token": refreshToken,
    "token_type": tokenType,
  };
}

class AuthUser {
  String? email;

  AuthUser({this.email});

  factory AuthUser.fromJson(Map<String, dynamic> json) =>
      AuthUser(email: json["email"]);

  Map<String, dynamic> toJson() => {"email": email};
}
