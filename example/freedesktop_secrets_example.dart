import 'dart:convert';

import 'package:freedesktop_secrets/freedesktop_secrets.dart';

void main() async {
  var client = FreedesktopSecretsClient();
  await client.open();

  final collections = await client.collections();
  // var awesome = Awesome();
  print('collections: $collections');

  print('items ${await collections[1].items}');

  print(
    'secret ${utf8.decode((await (await collections[0].items)[0].getSecret(client.session)).decrypt().value)}',
  );

  var (collection, prompt) = await client.createCollection(label: "test");
  print("collection: $collection prompt: $prompt");
  if (prompt != null) {
    collection = await prompt.complete(FreedesktopSecretsCollection.new);
    if (collection == null) {
      return;
    }
  }

  var (item, prompt2) = await collection!.createItem(
    FreedesktopSecretDecrypted(session: client.session, value: utf8.encode("Some password")),
    FreedesktopSecretsCreateItemProps("test", {}),
    true,
  );

  if (prompt2 != null) {
    item = await prompt2.complete(FreedesktopSecretsItem.new);
    if (item == null) {
      return;
    }
  }

  (await collection.delete())?.complete<void>((_, _) {});

  await client.close();
}
