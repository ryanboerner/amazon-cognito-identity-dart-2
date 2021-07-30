// This is the main worker file. Its major drawback is it has to be manually compiled into js whenever a change is made to it.
// What is does basically is keep the auth big number crunching separate from the main code, and pass the results back
// so the main code can update its auth state with the results.

// Manual compilation should be done using the following command:
// ${FLUTTER_BIN}/cache/dart-sdk/bin/dart2js --libraries-spec=${FLUTTER_BIN}/cache/flutter_web_sdk/libraries.json -o web/worker.dart.js workers/worker.dart --no-sound-null-safety
// where `${FLUTTER_BIN}` should be replaced by your local path to the Flutter `bin` directory. (sound null safety can probably be added now)

@JS()
library workers;

import 'dart:html';

import 'package:amazon_cognito_identity_dart_2/cognito.dart';
import 'package:js/js.dart';

// ================================================================= //

@JS('self')
external DedicatedWorkerGlobalScope get self;

const String KEY = '__key__';
const String ACTION = '__action__';
const String OBJECT = '__object__';

AuthenticationHelper? authHelper;

void postBack(String key, dynamic data) {
  final dynamic msg = <dynamic, dynamic>{
    KEY: key,
    OBJECT: data,
  };

  self.postMessage(msg);
}

void parseEvent(MessageEvent e) {
  final String _key = e.data[KEY] as String;
  final String _action = e.data[ACTION] as String;

  switch (_action) {
    case 'setPool':
      {
        try {
          final String poolName = e.data[OBJECT] as String;
          authHelper ??= AuthenticationHelper(poolName);
          postBack(_key, true);
        } on Error catch (e) {
          postBack(_key, e.toString());
        }
        break;
      }
    case 'getLargeAValue':
      {
        final BigInt largeA = authHelper?.getLargeAValue() ?? BigInt.zero;
        postBack(_key, largeA.toString());
        break;
      }
    case 'getPasswordAuthenticationKey':
      {
        final dynamic params = e.data[OBJECT];
        final String username = params['username'] as String;
        final String password = params['password'] as String;
        final BigInt serverBValue =
            BigInt.parse(params['serverBValue'] as String);
        final BigInt salt = BigInt.parse(params['salt'] as String);

        final List<int> authKey = authHelper?.getPasswordAuthenticationKey(
                username, password, serverBValue, salt) ??
            <int>[];
        postBack(_key, authKey);
        break;
      }
  }
}

void main() {
  self.onMessage.listen(parseEvent);
}
