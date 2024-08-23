import 'package:flutter/material.dart';
import 'energy_budget.dart';
import 'solar_cable.dart';
import 'battery_cable.dart';

void main() {
  runApp(const SolarCalcApp());
}

/// SolarCalcApp computes energy budget, solar and battery cable losses.
class SolarCalcApp extends StatelessWidget {
  const SolarCalcApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Solar Power',
      theme: ThemeData(
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
        textTheme: Theme.of(context).textTheme.copyWith(
              bodyMedium: const TextStyle(fontSize: 16),
            ),
      ),
      home: const SolarCalcHome(title: "Solar Power calculations"),
    );
  }
}

class SolarCalcHome extends StatefulWidget {
  const SolarCalcHome({super.key, required this.title});

  final String title;

  @override
  State<SolarCalcHome> createState() => _SolarCalcHomeState();
}

class _SolarCalcHomeState extends State<SolarCalcHome> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: ListView(
        children: const [
          EnergyBudget(),
          SolarCable(),
          BatteryCable(),
        ],
      ),
    );
  }
}