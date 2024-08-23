import 'package:hive_flutter/hive_flutter.dart';

 mixin HivePersistence {
  dynamic box;

  init() async{
    await Hive.initFlutter();
    box = await Hive.openBox('solar');
  }

  setIfEmpty(String key, dynamic value) {
    if (box.get(key) != null) return;
    box.put(key, value);
  }
}