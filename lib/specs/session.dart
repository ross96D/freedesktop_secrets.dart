// This file was generated using the following command and may be overwritten.
// dart-dbus generate-remote-object org.freedesktop.Secret.Session.xml

import "package:dbus/dbus.dart";

class OrgFreedesktopSecretsSession extends DBusRemoteObject {
  OrgFreedesktopSecretsSession(super.client, String destination, {required super.path}) : super(name: destination);

  /// Invokes org.freedesktop.Secret.Session.Close()
  Future<void> callClose({bool noAutoStart = false, bool allowInteractiveAuthorization = false}) async {
    await callMethod("org.freedesktop.Secret.Session", "Close", [], replySignature: DBusSignature(""), noAutoStart: noAutoStart, allowInteractiveAuthorization: allowInteractiveAuthorization);
  }
}
