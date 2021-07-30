// This is a utility file that simplifies the management of workers. It's not necessary, but it's useful and much cleaner.

import 'dart:async';
import 'dart:html';

import 'package:flutter/widgets.dart';

const String WORKERJS = 'worker.dart.js';

const String KEY = '__key__';
const String ACTION = '__action__';
const String OBJECT = '__object__';

class ManagedWorker {
  ManagedWorker(this.name);

  final Worker _worker = Worker(WORKERJS);

  Worker get worker => _worker;

  final String name;

  Future<dynamic> post(String actionName,
      [dynamic data, List<Object>? transfer]) {
    final uniqueKey = UniqueKey();
    _worker.onMessage.listen(null);
    // ignore: omit_local_variable_types
    final Future<dynamic> future =
        _worker.onMessage.firstWhere((MessageEvent event) {
      try {
        return event.data[KEY] == uniqueKey.toString();
      } on Error {
        return false;
      }
    }).then<dynamic>((MessageEvent event) {
      return event.data[OBJECT];
    });

    final dynamic msg = <dynamic, dynamic>{
      KEY: uniqueKey.toString(),
      ACTION: actionName,
      OBJECT: data,
    };

    _worker.postMessage(msg, transfer);
    return future;
  }
}

class WorkerPool {
  WorkerPool._privateConstructor();

  final Map<String, ManagedWorker> _pool = <String, ManagedWorker>{};

  static final WorkerPool _instance = WorkerPool._privateConstructor();

  static WorkerPool get instance {
    return _instance;
  }

  Map<String, ManagedWorker> get pool => _pool;

  ManagedWorker? get(String name) => _pool[name];

  ManagedWorker createWorker(String name) {
    if (_pool.containsKey(name)) {
      throw Exception('Worker with name $name already exists');
    }

    final ManagedWorker worker = ManagedWorker(name);

    _pool[name] = worker;

    return worker;
  }
}
