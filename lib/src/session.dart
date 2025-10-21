import 'dart:typed_data';

import 'package:dbus/dbus.dart';
import 'package:diffie_hellman/diffie_hellman.dart';
import 'package:freedesktop_secrets/specs/service.dart';
import 'package:freedesktop_secrets/specs/session.dart';
import 'package:pointycastle/export.dart';

class FreedesktopSecretsSessionSecure {
  final OrgFreedesktopSecrets service;
  late final OrgFreedesktopSecretsSession session;

  DBusObjectPath get path => session.path;

  final DhPkcs3Engine _dhEngine;
  late BigInt _sharedSecret;
  late Uint8List _aesKey;

  FreedesktopSecretsSessionSecure(this.service) : _dhEngine = DhPkcs3Engine.fromGroup(DhGroup.g2) {
    _dhEngine.generateKeyPair();
  }

  Future<void> open() async {
    final sessionResponse = await service.callOpenSession(
      "dh-ietf1024-sha256-aes128-cbc-pkcs7",
      DBusArray.byte((_dhEngine.publicKey!.value.toBytes())),
    );
    session = OrgFreedesktopSecretsSession(
      service.client,
      "org.freedesktop.secrets",
      path: sessionResponse[1] as DBusObjectPath,
    );
    final servicePublicKey = Uint8List.fromList(
      sessionResponse[0].asVariant().asByteArray().toList(),
    );
    _sharedSecret = _dhEngine.computeSecretKey(servicePublicKey.toBigInt());

    final derivator = HKDFKeyDerivator(SHA256Digest());
    derivator.init(HkdfParameters(_sharedSecret.toBytes(), 16));

    _aesKey = derivator.process(Uint8List.fromList([]));
  }

  Future<void> close() async {
    await session.callClose();
  }

  Uint8List decrypt(Uint8List message, Uint8List initVec) {
    final cipher = PaddedBlockCipherImpl(PKCS7Padding(), CBCBlockCipher(AESEngine()));

    cipher.init(
      false,
      PaddedBlockCipherParameters(ParametersWithIV(KeyParameter(_aesKey), initVec), null),
    );

    return cipher.process(message);
  }

  Uint8List encrypt(Uint8List message, Uint8List initVec) {
    final cipher = PaddedBlockCipherImpl(PKCS7Padding(), CBCBlockCipher(AESEngine()));

    cipher.init(
      true,
      PaddedBlockCipherParameters(ParametersWithIV(KeyParameter(_aesKey), initVec), null),
    );

    return cipher.process(message);
  }
}

extension on BigInt {
  Uint8List toBytes() {
    BigInt number = this;
    int bytes = (number.bitLength + 7) >> 3;
    var b256 = BigInt.from(256);
    var result = Uint8List(bytes);
    for (int i = 0; i < bytes; i++) {
      result[bytes - i - 1] = number.remainder(b256).toInt();
      number = number >> 8;
    }
    return result;
  }
}

extension on Uint8List {
  BigInt toBigInt() {
    BigInt result = BigInt.zero;
    for (int i = 0; i < length; i++) {
      result = (result << 8) | BigInt.from(this[i]);
    }
    return result;
  }
}
