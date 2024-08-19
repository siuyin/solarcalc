import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const floatPrecision = 4;

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
  late int numPanels;
  late double panelPower;
  late double panelOCV;
  double totalPanelPower() {
    return numPanels * panelPower;
  }

  double totalPanelVolts() {
    return numPanels * panelOCV;
  }

  late double solarChargerMinVolts;
  late double solarChargerMaxVolts;

  static const peakSolarHoursPerDay = 4.2;
  double wattHoursPerDay() {
    return numPanels * panelPower * peakSolarHoursPerDay;
  }

  late int numCells;
  late double ampHoursPerCell;
  static const voltsPerCell = 3.2;
  double battAmpHours() {
    return numCells * ampHoursPerCell;
  }

  double battWattHours() {
    return numCells * ampHoursPerCell * voltsPerCell;
  }

  final panelPowerController = TextEditingController(text: '100');
  final numPanelsController = TextEditingController(text: '1');

  final panelOCVController = TextEditingController(text: '22.1');
  final solarChargerMinVoltsController = TextEditingController(text: '30.0');
  final solarChargerMaxVoltsController = TextEditingController(text: '110.0');
  var openCircuitVoltageConfig = const Text('OK');

  final numCellsController = TextEditingController(text: '8');
  final cellCapacityController = TextEditingController(text: '100');

  @override
  void initState() {
    compute();
    super.initState();
  }

  compute() {
    checkOpenCircuitVoltage();
    updatePowerCalc();
    updateBatteryCalc();
  }

  Text batteryInfo = const Text('');

  bool updateBatteryCalc() {
    final nc = int.tryParse(numCellsController.text);
    final cc = double.tryParse(cellCapacityController.text);
    if (nc == null || cc == null) {
      setState(() {
        batteryInfo = const Text('INVALID Config',
            style: TextStyle(
              color: Colors.red,
            ));
      });
      return false;
    }

    setState(() {
      numCells = nc;
      ampHoursPerCell = cc;
      batteryInfo = Text(
        '${battAmpHours()}Ah, ${battWattHours()}Wh,'
        '\nPmax: ${ampHoursPerCell * voltsPerCell * numCells / 1000}kW '
        'Chg: ${(battWattHours() / wattHoursPerDay()).toStringAsPrecision(2)}d',
        textAlign: TextAlign.left,
      );
    });
    return true;
  }

  bool checkOpenCircuitVoltage() {
    final pv = double.tryParse(panelOCVController.text);
    final n = int.tryParse(numPanelsController.text);
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

    setState(() {
      panelOCV = pv;
      numPanels = n;
      solarChargerMinVolts = min;
      solarChargerMaxVolts = max;
    });

    if (totalPanelVolts() > solarChargerMinVolts &&
        totalPanelVolts() < solarChargerMaxVolts) {
      setState(() {
        openCircuitVoltageConfig = Text(
            'OK. Vp: ${totalPanelVolts().toStringAsPrecision(floatPrecision)}',
            style: const TextStyle(
              color: Colors.green,
            ));
      });
      return true;
    }
    if (totalPanelVolts() < solarChargerMinVolts) {
      setState(() {
        openCircuitVoltageConfig = Text(
            'Vp: ${totalPanelVolts().toStringAsPrecision(floatPrecision)} < $solarChargerMinVolts',
            style: const TextStyle(
              color: Colors.red,
            ));
      });
      return false;
    }

    if (totalPanelVolts() > solarChargerMaxVolts) {
      setState(() {
        openCircuitVoltageConfig = Text(
            'Vp: ${totalPanelVolts().toStringAsPrecision(floatPrecision)} > $solarChargerMaxVolts',
            style: const TextStyle(
              color: Colors.red,
            ));
      });
      return false;
    }

    setState(() {
      openCircuitVoltageConfig = const Text('Unknown Error',
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
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 0),
      child: Column(
        children: [
          Text(
            'Energy Budget',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          panelPowerCalc(),
          const Divider(),
          panelVoltageCalc(),
          const Divider(),
          Row(
            children: [
              Expanded(
                flex: 1,
                child: TextField(
                  controller: numCellsController,
                  onSubmitted: (_) => compute(),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'num cells',
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: TextField(
                  controller: cellCapacityController,
                  keyboardType: TextInputType.number,
                  onSubmitted: (_) => compute(),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'[+-]?([0-9]+([.][0-9]*)?|[.][0-9]+)'))
                  ],
                  decoration: const InputDecoration(
                    labelText: 'cell capacity',
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: batteryInfo,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Row panelVoltageCalc() {
    return Row(children: [
      Expanded(
        flex: 1,
        child: TextField(
          onSubmitted: (_) => compute(),
          controller: panelOCVController,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.allow(
                RegExp(r'[+-]?([0-9]+([.][0-9]*)?|[.][0-9]+)'))
          ],
          decoration: const InputDecoration(
            labelText: 'Panel Voc',
          ),
        ),
      ),
      Expanded(
        flex: 1,
        child: TextField(
          onSubmitted: (_) => compute(),
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
    ]);
  }

  Row panelPowerCalc() {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: TextField(
            onSubmitted: (_) => compute(),
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
            onSubmitted: (_) => compute(),
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
            '${totalPanelPower()} W-peak.'
            '\nEst. ${(wattHoursPerDay() / 1000).toStringAsPrecision(floatPrecision)} kWh/day',
            textAlign: TextAlign.left,
          ),
        ),
      ],
    );
  }
}

hiveDemo() async {}
