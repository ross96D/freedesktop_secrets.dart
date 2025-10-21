import 'dart:math';
import 'dart:typed_data';

import 'package:dbus/dbus.dart';
import 'package:freedesktop_secrets/src/session.dart';

sealed class FreedesktopSecret {
  final FreedesktopSecretsSessionSecure session;

  /// Encoded secret value
  final Uint8List value;

  /// The content type of the secret. For example: 'text/plain; charset=utf8'
  String contentType;

  FreedesktopSecret({required this.session, required this.value, required this.contentType});
}

class FreedesktopSecretEncrypted extends FreedesktopSecret {
  /// Algorithm dependent parameters for secret value encoding.
  final Uint8List initVec;

  FreedesktopSecretEncrypted({
    required super.session,
    required super.value,
    required super.contentType,
    required this.initVec,
  });

  factory FreedesktopSecretEncrypted.from(
    FreedesktopSecretsSessionSecure session,
    List<DBusValue> secret,
  ) {
    return FreedesktopSecretEncrypted(
      session: session,
      initVec: Uint8List.fromList(secret[1].asByteArray().toList()),
      value: Uint8List.fromList(secret[2].asByteArray().toList()),
      contentType: secret[3].asString(),
    );
  }

  List<DBusValue> toDBus() {
    return [session.path, DBusArray.byte(initVec), DBusArray.byte(value), DBusString(contentType)];
  }

  FreedesktopSecretDecrypted decrypt() {
    return FreedesktopSecretDecrypted(
      session: session,
      value: session.decrypt(value, initVec),
      contentType: contentType,
    );
  }
}

class FreedesktopSecretDecrypted extends FreedesktopSecret {
  FreedesktopSecretDecrypted({
    required super.session,
    required super.value,
    super.contentType = "text/plain",
  });

  FreedesktopSecretEncrypted encrypt() {
    final random = Random.secure();
    final initVec = Uint8List.fromList(List.generate(16, (_) => random.nextInt(255)));
    final encValue = session.encrypt(value, initVec);

    return FreedesktopSecretEncrypted(
      session: session,
      initVec: initVec,
      contentType: contentType,
      value: encValue,
    );
  }
}
