import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
      ),
      home: const MyHomePage(title: "Solar Power calculations"),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: ListView(
        children: const [
          Budget(),
          Solar(),
          Utility(),
        ],
      ),
    );
  }

}

class Utility extends StatefulWidget {
  const Utility({super.key});

  @override
  State<Utility> createState() => _UtilityState();
}

class _UtilityState extends State<Utility> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 32),
      child: const Text('Utility'),
    );
  }
}

class Solar extends StatefulWidget {
  const Solar({super.key});

  @override
  State<Solar> createState() => _SolarState();
}

class _SolarState extends State<Solar> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 32),
      child: const Text('Solar'),
    );
  }
}

class Budget extends StatefulWidget {
  const Budget({super.key});

  @override
  State<Budget> createState() => _BudgetState();
}

class _BudgetState extends State<Budget> {
  int numPanels = 1;
  double panelPower = 0;
  double totalPanelPower = 0;
  static const peakSolarHoursPerDay = 4.2;

  double wattHoursPerDay() {
    return numPanels * panelPower * peakSolarHoursPerDay;
  }

  int numCells = 0;
  double ampHoursPerCell = 0;
  static const voltsPerCell = 3.2;

  double battWattHours(int n, double ah) {
    return n * ah * voltsPerCell;
  }

  final panelPowerController = TextEditingController(text: '100');
  final numPanelsController = TextEditingController(text: '1');

  final panelOCVController = TextEditingController(text: '20');
  final solarChargerMinVoltsController = TextEditingController(text: '30.0');
  final solarChargerMaxVoltsController = TextEditingController(text: '110.0');
  var openCircuitVoltageConfig = const Text('OK');

  bool checkOpenCircuitVoltage() {
    final pv = double.tryParse(panelOCVController.text);
    final n = double.tryParse(numPanelsController.text);
    final min = double.tryParse(solarChargerMinVoltsController.text);
    final max = double.tryParse(solarChargerMaxVoltsController.text);
    if (pv == null || n == null || min == null || max == null) {
      setState(() {
        openCircuitVoltageConfig = const Text('INVALID Config',
            style: TextStyle(
              color: Colors.red,
            ));
      });
      return false;
    }
    if (pv * n > min && pv * n < max) {
      setState(() {
        openCircuitVoltageConfig = const Text('OK',
            style: TextStyle(
              color: Colors.green,
            ));
      });
      return true;
    }

    setState(() {
      openCircuitVoltageConfig = const Text('Under or Over Voltage',
          style: TextStyle(
            color: Colors.red,
          ));
    });
    return false;
  }

  updatePowerCalc() {
    setState(() {
      try {
        numPanels = int.parse(numPanelsController.text);
      } catch (err) {
        numPanels = 1;
      }
      try {
        panelPower = double.parse(panelPowerController.text);
      } catch (err) {
        panelPower = 0;
      }
      totalPanelPower = numPanels * panelPower;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 0),
      child: Column(
        children: [
          panelPowerCalc(),
          const Divider(),
          Row(children: [
            Expanded(
              flex: 1,
              child: TextField(
                onSubmitted: (_) => checkOpenCircuitVoltage(),
                controller: panelOCVController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                      RegExp(r'[+-]?([0-9]+([.][0-9]*)?|[.][0-9]+)'))
                ],
                decoration: const InputDecoration(
                  labelText: 'Panel Open Circuit Voltage',
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: TextField(
                onSubmitted: (_) => checkOpenCircuitVoltage(),
                controller: solarChargerMinVoltsController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                      RegExp(r'[+-]?([0-9]+([.][0-9]*)?|[.][0-9]+)'))
                ],
                decoration: const InputDecoration(
                  labelText: 'minV',
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: TextField(
                onSubmitted: (_) => checkOpenCircuitVoltage(),
                controller: solarChargerMaxVoltsController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                      RegExp(r'[+-]?([0-9]+([.][0-9]*)?|[.][0-9]+)'))
                ],
                decoration: const InputDecoration(
                  labelText: 'maxV',
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: openCircuitVoltageConfig,
            ),
          ]),
        ],
      ),
    );
  }

  Row panelPowerCalc() {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: TextField(
            onSubmitted: (_) => updatePowerCalc(),
            controller: panelPowerController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'Panel power',
            ),
          ),
        ),
        const Text(' W-peak x '),
        Expanded(
          flex: 1,
          child: TextField(
            controller: numPanelsController,
            onSubmitted: (_) => updatePowerCalc(),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'n',
            ),
          ),
        ),
        Expanded(
          flex: 4,
          child: Text(
              '= $totalPanelPower W-peak. Est. ${wattHoursPerDay()} Wh/day'),
        ),
      ],
    );
  }
}

hiveDemo() async {}
