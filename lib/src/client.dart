import 'dart:async';

import 'package:dbus/dbus.dart';
import 'package:freedesktop_secrets/specs/collection.dart';
import 'package:freedesktop_secrets/specs/item.dart';
import 'package:freedesktop_secrets/specs/prompt.dart';
import 'package:freedesktop_secrets/specs/service.dart';
import 'package:freedesktop_secrets/src/secret.dart';
import 'package:freedesktop_secrets/src/session.dart';

class FreedesktopSecretsClient {
  static const destination = "org.freedesktop.secrets";

  final DBusClient client;
  late final OrgFreedesktopSecrets _secrets = OrgFreedesktopSecrets(client, destination);
  late final FreedesktopSecretsSessionSecure session = FreedesktopSecretsSessionSecure(_secrets);

  FreedesktopSecretsClient([DBusClient? client]) : client = client ?? DBusClient.session();

  Future<List<FreedesktopSecretsCollection>> collections() async {
    return (await _secrets.getCollections())
        .map((e) => FreedesktopSecretsCollection(client, e))
        .toList();
  }

  Future<void> open() async {
    await session.open();
  }

  Future<void> close() async {
    await session.close();
    await client.close();
  }

  Future<FreedesktopSecretsCollection?> defaultCollection() {
    return getAlias("default");
  }

  Future<(FreedesktopSecretsCollection?, FreedesktopSecretsPrompt<DBusObjectPath>?)>
  createCollection({String? alias, String? label}) async {
    final resp = await _secrets.callCreateCollection({
      if (label != null) "org.freedesktop.Secret.Collection.Label": DBusString(label),
    }, alias ?? "");
    if (resp[0].asObjectPath().value != "/") {
      return (FreedesktopSecretsCollection(client, resp[0].asObjectPath()), null);
    } else {
      return (null, FreedesktopSecretsPrompt<DBusObjectPath>(client, resp[1].asObjectPath()));
    }
  }

  Future<Map<DBusObjectPath, FreedesktopSecretEncrypted>> getSecrets(
    List<FreedesktopSecretsItem> items,
  ) {
    return _secrets
        .callGetSecrets(items.map((e) => e.path).toList(growable: false), session.path)
        .then((v) {
          return v.map((k, v) => MapEntry(k, FreedesktopSecretEncrypted.from(session, v)));
        });
  }

  Future<FreedesktopSecretsCollection?> getAlias(String alias) async {
    final path = await _secrets.callReadAlias(alias);
    if (path.value == "/") {
      return null;
    }
    return FreedesktopSecretsCollection(client, await _secrets.callReadAlias(alias));
  }

  Future<void> setAlias(String alias, FreedesktopSecretsCollection collection) async {
    return await _secrets.callSetAlias(alias, collection.path);
  }

  Future<({List<FreedesktopSecretsItem> unlocked, List<FreedesktopSecretsItem> locked})>
  searchItems(Map<String, String> attributes) async {
    final response = await _secrets.callSearchItems(attributes);
    return (
      unlocked: response[0]
          .asObjectPathArray()
          .map((e) => FreedesktopSecretsItem(client, e))
          .toList(growable: false),
      locked: response[1]
          .asObjectPathArray()
          .map((e) => FreedesktopSecretsItem(client, e))
          .toList(growable: false),
    );
  }

  Future<void> lock(List<FreedesktopSecretsCollection> collections) async {
    await _secrets.callLock(collections.map((e) => e.path).toList(growable: false));
  }

  Future<void> unlock(List<FreedesktopSecretsCollection> collections) async {
    await _secrets.callUnlock(collections.map((e) => e.path).toList(growable: false));
  }
}

class FreedesktopSecretsCreateItemProps {
  final String label;
  final Map<String, String> attributes;

  FreedesktopSecretsCreateItemProps(this.label, this.attributes);

  Map<String, DBusValue> toDBus() {
    return {
      "org.freedesktop.Secret.Item.Label": DBusString(label),
      "org.freedesktop.Secret.Item.Attributes": DBusDict(
        DBusSignature.string,
        DBusSignature.string,
        {for (final entry in attributes.entries) DBusString(entry.key): DBusString(entry.value)},
      ),
    };
  }
}

class FreedesktopSecretsCollection {
  final OrgFreedesktopSecretsCollection _collection;

  DBusObjectPath get path => _collection.path;

  FreedesktopSecretsCollection(DBusClient client, DBusObjectPath path)
    : _collection = OrgFreedesktopSecretsCollection(
        client,
        FreedesktopSecretsClient.destination,
        path: path,
      );

  /// The unix time when the collection was created.
  Future<int> get created => _collection.getCreated();

  /// The unix time when the collection was last modified.
  Future<int> get modified => _collection.getModified();

  /// Whether the collection is locked and must be authenticated by the client application
  Future<bool> get locked => _collection.getLocked();

  /// The displayable label of this collection
  Future<String> get label => _collection.getLabel();
  set label(String label) {
    _collection.setLabel(label);
  }

  Future<List<FreedesktopSecretsItem>> get items {
    return _collection.getItems().then((paths) {
      return paths
          .map((path) => FreedesktopSecretsItem(_collection.client, path))
          .toList(growable: false);
    });
  }

  Future<(FreedesktopSecretsItem?, FreedesktopSecretsPrompt<DBusObjectPath>?)> createItem(
    FreedesktopSecret secret,
    FreedesktopSecretsCreateItemProps properties,
    bool replace,
  ) async {
    final response = await _collection.callCreateItem(properties.toDBus(), switch (secret) {
      FreedesktopSecretEncrypted() => secret.toDBus(),
      FreedesktopSecretDecrypted() => secret.encrypt().toDBus(),
    }, replace);

    if ((response[0] as DBusObjectPath).value != "/") {
      return (FreedesktopSecretsItem(_collection.client, response[0] as DBusObjectPath), null);
    } else {
      return (
        null,
        FreedesktopSecretsPrompt<DBusObjectPath>(_collection.client, response[1] as DBusObjectPath),
      );
    }
  }

  Future<FreedesktopSecretsPrompt<DBusObjectPath>?> delete() async {
    final prompt = await _collection.callDelete();
    if (prompt.value == "/") {
      return null;
    } else {
      return FreedesktopSecretsPrompt(_collection.client, prompt);
    }
  }

  Future<List<FreedesktopSecretsItem>> search(Map<String, String> attributes) async {
    return _collection.callSearchItems(attributes).then((itemsPath) {
      return itemsPath
          .map((path) => FreedesktopSecretsItem(_collection.client, path))
          .toList(growable: false);
    });
  }

  @override
  String toString() => path.value;
}

class FreedesktopSecretsItem {
  final OrgFreedesktopSecretsItem _item;

  DBusObjectPath get path => _item.path;

  FreedesktopSecretsItem(DBusClient client, DBusObjectPath path)
    : _item = OrgFreedesktopSecretsItem(client, FreedesktopSecretsClient.destination, path: path);

  Future<FreedesktopSecretsPrompt<DBusObjectPath>?> delete() async {
    final path = await _item.callDelete();
    if (path.value == "/") {
      return null;
    }
    return FreedesktopSecretsPrompt(_item.client, path);
  }

  Future<FreedesktopSecretEncrypted> getSecret(FreedesktopSecretsSessionSecure session) async {
    final secret = await _item.callGetSecret(session.path);
    return FreedesktopSecretEncrypted.from(session, secret);
  }

  Future<void> setSecret(FreedesktopSecretDecrypted secret) async {
    await _item.callSetSecret(secret.encrypt().toDBus());
  }

  @override
  String toString() => path.value;
}

class FreedesktopSecretsPrompt<T extends DBusValue> {
  final OrgFreedesktopSecretsPrompts _prompt;

  DBusObjectPath get path => _prompt.path;

  final Completer<({bool dismissed, T result})> _completer;

  Future<({bool dismissed, T result})> get wait => _completer.future;

  FreedesktopSecretsPrompt(DBusClient client, DBusObjectPath path)
    : _prompt = OrgFreedesktopSecretsPrompts(
        client,
        FreedesktopSecretsClient.destination,
        path: path,
      ),
      _completer = Completer() {
    _prompt.completed.first.then(
      (v) => _completer.complete((dismissed: v.dismissed, result: v.result as T)),
    );
  }

  Future<void> prompt(String windowId) async {
    return _prompt.callPrompt(windowId);
  }

  Future<void> dismiss() async {
    return _prompt.callDismiss();
  }

  Future<R?> complete<R>(R Function(DBusClient, T) constructor, [String windowId = ""]) async {
    await prompt("");
    final waitedResult = await wait;
    if (waitedResult.dismissed) {
      return null;
    }
    return constructor(_prompt.client, waitedResult.result);
  }

  @override
  String toString() => path.value;
}
