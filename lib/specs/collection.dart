// This file was generated using the following command and may be overwritten.
// dart-dbus generate-remote-object org.freedesktop.Secret.Collection.xml

import "package:dbus/dbus.dart";

/// Signal data for org.freedesktop.Secret.Collection.ItemCreated.
class FreedesktopSecretsCollectionItemCreated extends DBusSignal {
  DBusObjectPath get item => values[0].asObjectPath();

  FreedesktopSecretsCollectionItemCreated(DBusSignal signal) : super(sender: signal.sender, path: signal.path, interface: signal.interface, name: signal.name, values: signal.values);
}

/// Signal data for org.freedesktop.Secret.Collection.ItemDeleted.
class FreedesktopSecretsCollectionItemDeleted extends DBusSignal {
  DBusObjectPath get item => values[0].asObjectPath();

  FreedesktopSecretsCollectionItemDeleted(DBusSignal signal) : super(sender: signal.sender, path: signal.path, interface: signal.interface, name: signal.name, values: signal.values);
}

/// Signal data for org.freedesktop.Secret.Collection.ItemChanged.
class FreedesktopSecretsCollectionItemChanged extends DBusSignal {
  DBusObjectPath get item => values[0].asObjectPath();

  FreedesktopSecretsCollectionItemChanged(DBusSignal signal) : super(sender: signal.sender, path: signal.path, interface: signal.interface, name: signal.name, values: signal.values);
}

class OrgFreedesktopSecretsCollection extends DBusRemoteObject {
  /// Stream of org.freedesktop.Secret.Collection.ItemCreated signals.
  late final Stream<FreedesktopSecretsCollectionItemCreated> itemCreated;

  /// Stream of org.freedesktop.Secret.Collection.ItemDeleted signals.
  late final Stream<FreedesktopSecretsCollectionItemDeleted> itemDeleted;

  /// Stream of org.freedesktop.Secret.Collection.ItemChanged signals.
  late final Stream<FreedesktopSecretsCollectionItemChanged> itemChanged;

  OrgFreedesktopSecretsCollection(super.client, String destination, {required super.path}) : super(name: destination) {
    itemCreated = DBusRemoteObjectSignalStream(object: this, interface: "org.freedesktop.Secret.Collection", name: "ItemCreated", signature: DBusSignature("o")).asBroadcastStream().map((signal) => FreedesktopSecretsCollectionItemCreated(signal));

    itemDeleted = DBusRemoteObjectSignalStream(object: this, interface: "org.freedesktop.Secret.Collection", name: "ItemDeleted", signature: DBusSignature("o")).asBroadcastStream().map((signal) => FreedesktopSecretsCollectionItemDeleted(signal));

    itemChanged = DBusRemoteObjectSignalStream(object: this, interface: "org.freedesktop.Secret.Collection", name: "ItemChanged", signature: DBusSignature("o")).asBroadcastStream().map((signal) => FreedesktopSecretsCollectionItemChanged(signal));
  }

  /// Gets org.freedesktop.Secret.Collection.Items
  Future<List<DBusObjectPath>> getItems() async {
    var value = await getProperty("org.freedesktop.Secret.Collection", "Items", signature: DBusSignature("ao"));
    return value.asObjectPathArray().toList();
  }

  /// Gets org.freedesktop.Secret.Collection.Label
  Future<String> getLabel() async {
    var value = await getProperty("org.freedesktop.Secret.Collection", "Label", signature: DBusSignature("s"));
    return value.asString();
  }

  /// Sets org.freedesktop.Secret.Collection.Label
  Future<void> setLabel (String value) async {
    await setProperty("org.freedesktop.Secret.Collection", "Label", DBusString(value));
  }

  /// Gets org.freedesktop.Secret.Collection.Locked
  Future<bool> getLocked() async {
    var value = await getProperty("org.freedesktop.Secret.Collection", "Locked", signature: DBusSignature("b"));
    return value.asBoolean();
  }

  /// Gets org.freedesktop.Secret.Collection.Created
  Future<int> getCreated() async {
    var value = await getProperty("org.freedesktop.Secret.Collection", "Created", signature: DBusSignature("t"));
    return value.asUint64();
  }

  /// Gets org.freedesktop.Secret.Collection.Modified
  Future<int> getModified() async {
    var value = await getProperty("org.freedesktop.Secret.Collection", "Modified", signature: DBusSignature("t"));
    return value.asUint64();
  }

  /// Invokes org.freedesktop.Secret.Collection.Delete()
  Future<DBusObjectPath> callDelete({bool noAutoStart = false, bool allowInteractiveAuthorization = false}) async {
    var result = await callMethod("org.freedesktop.Secret.Collection", "Delete", [], replySignature: DBusSignature("o"), noAutoStart: noAutoStart, allowInteractiveAuthorization: allowInteractiveAuthorization);
    return result.returnValues[0].asObjectPath();
  }

  /// Invokes org.freedesktop.Secret.Collection.SearchItems()
  Future<List<DBusObjectPath>> callSearchItems(Map<String, String> attributes, {bool noAutoStart = false, bool allowInteractiveAuthorization = false}) async {
    var result = await callMethod("org.freedesktop.Secret.Collection", "SearchItems", [DBusDict(DBusSignature("s"), DBusSignature("s"), attributes.map((key, value) => MapEntry(DBusString(key), DBusString(value))))], replySignature: DBusSignature("ao"), noAutoStart: noAutoStart, allowInteractiveAuthorization: allowInteractiveAuthorization);
    return result.returnValues[0].asObjectPathArray().toList();
  }

  /// Invokes org.freedesktop.Secret.Collection.CreateItem()
  Future<List<DBusValue>> callCreateItem(Map<String, DBusValue> properties, List<DBusValue> secret, bool replace, {bool noAutoStart = false, bool allowInteractiveAuthorization = false}) async {
    var result = await callMethod("org.freedesktop.Secret.Collection", "CreateItem", [DBusDict.stringVariant(properties), DBusStruct(secret), DBusBoolean(replace)], replySignature: DBusSignature("oo"), noAutoStart: noAutoStart, allowInteractiveAuthorization: allowInteractiveAuthorization);
    return result.returnValues;
  }
}
