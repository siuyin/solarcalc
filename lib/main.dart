import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';

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
        textTheme: Theme.of(context).textTheme.copyWith(
              bodyMedium: const TextStyle(fontSize: 16),
            ),
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

class EnergyBudget extends StatefulWidget {
  const EnergyBudget({super.key});

  @override
  State<EnergyBudget> createState() => _EnergyBudgetState();
}

class _EnergyBudgetState extends State<EnergyBudget> {
  int numPanels = 1;
  double panelPower = 100;
  double panelOCV = 22.1;
  double totalPanelPower() {
    return numPanels * panelPower;
  }

  double totalPanelVolts() {
    return numPanels * panelOCV;
  }

  double solarChargerMinVolts = 30.0;
  double solarChargerMaxVolts = 100.0;

  static const peakSolarHoursPerDay = 4.2;
  double wattHoursPerDay() {
    return numPanels * panelPower * peakSolarHoursPerDay;
  }

  int numCells = 4;
  double ampHoursPerCell = 100.0;
  static const voltsPerCell = 3.2;
  double battAmpHours() {
    return ampHoursPerCell;
  }

  double battWattHours() {
    return numCells * ampHoursPerCell * voltsPerCell;
  }

  final panelPowerController = TextEditingController();
  final numPanelsController = TextEditingController();

  final panelOCVController = TextEditingController();
  final solarChargerMinVoltsController = TextEditingController();
  final solarChargerMaxVoltsController = TextEditingController();
  var openCircuitVoltageConfig = const Text('OK');

  final numCellsController = TextEditingController();
  final cellCapacityController = TextEditingController();

  dynamic box;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 0),
      child: Column(
        children: [
          const Heading(title: 'Energy Budget'),
          panelPowerCalc(),
          panelVoltageCalc(),
          batteryCapacityCalc(),
          computeBtn(),
        ],
      ),
    );
  }

  Padding computeBtn() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ElevatedButton(
        onPressed: compute,
        child: const Text('compute'),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _init();
  }

  _init() async {
    await Hive.initFlutter();
    box = await Hive.openBox('solar');

    setIfEmpty('panelPower', panelPower);
    panelPower = box.get('panelPower');
    panelPowerController.text = box.get('panelPower').toString();

    setIfEmpty('numPanels', numPanels);
    numPanels = box.get('numPanels');
    numPanelsController.text = box.get('numPanels').toString();

    setIfEmpty('panelOCV', panelOCV);
    panelOCV = box.get('panelOCV');
    panelOCVController.text = box.get('panelOCV').toString();

    setIfEmpty('solarChargerMinVolts', solarChargerMinVolts);
    solarChargerMinVolts = box.get('solarChargerMinVolts');
    solarChargerMinVoltsController.text =
        box.get('solarChargerMinVolts').toString();

    setIfEmpty('solarChargerMaxVolts', solarChargerMaxVolts);
    solarChargerMaxVolts = box.get('solarChargerMaxVolts');
    solarChargerMaxVoltsController.text =
        box.get('solarChargerMaxVolts').toString();

    setIfEmpty('numCells', numCells);
    numCells = box.get('numCells');
    numCellsController.text = box.get('numCells').toString();

    setIfEmpty('ampHoursPerCell', ampHoursPerCell);
    ampHoursPerCell = box.get('ampHoursPerCell');
    cellCapacityController.text = box.get('ampHoursPerCell').toString();

    compute();
  }

  setIfEmpty(String key, dynamic value) {
    if (box.get(key) != null) return;
    box.put(key, value);
    debugPrint('set $key to $value');
  }

  compute() {
    checkOpenCircuitVoltage();
    updatePowerCalc();
    updateBatteryCalc();
  }

  Text batteryInfo = const Text('batt info');

  double battMaxPower() {
    return ampHoursPerCell * voltsPerCell * numCells;
  }

  double battMaxAmps() {
    return ampHoursPerCell * 1.0; // 1.0C
  }

  double totalBatteryVolts() {
    return voltsPerCell * numCells;
  }

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
      box.put('battMaxAmps', battMaxAmps());

      batteryInfo = Text(
        '${totalBatteryVolts()}V ${battAmpHours()}Ah, ${battWattHours()}Wh,'
        '\nPmax: ${battMaxPower() / 1000}kW '
        'Chg: ${(battWattHours() / wattHoursPerDay()).toStringAsPrecision(2)}d',
        textAlign: TextAlign.left,
      );
    });

    box.put('numCells', numCells);
    box.put('ampHoursPerCell', ampHoursPerCell);
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
      box.put('panelOCV', panelOCV);
      numPanels = n;
      box.put('numPanels', numPanels);
      solarChargerMinVolts = min;
      box.put('solarChargerMinVolts', solarChargerMinVolts);
      solarChargerMaxVolts = max;
      box.put('solarChargerMaxVolts', solarChargerMaxVolts);
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
      numPanels = int.tryParse(numPanelsController.text) ?? 1;
      box.put('numPanels', numPanels);
      panelPower = double.tryParse(panelPowerController.text) ?? 0.0;
      box.put('panelPower', panelPower);
    });
  }

  Padding batteryCapacityCalc() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
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
    );
  }

  Padding panelVoltageCalc() {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Row(children: [
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
      ]),
    );
  }

  Padding panelPowerCalc() {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Row(
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
      ),
    );
  }
}

class SolarCable extends StatefulWidget {
  const SolarCable({super.key});

  @override
  State<SolarCable> createState() => _SolarCableState();
}

class _SolarCableState extends State<SolarCable> {
  dynamic box;
  String outputText = '';

  @override
  void initState() {
    super.initState();
    _init();
  }

  setIfEmpty(String key, dynamic value) {
    if (box.get(key) != null) return;
    box.put(key, value);
    debugPrint('set $key to $value');
  }

  _init() async {
    await Hive.initFlutter();
    box = await Hive.openBox('solar');
    setIfEmpty('cableCrossSection', 2.5);
    setState(() {
      cableCrossSection = box.get('cableCrossSection');
    });

    setIfEmpty('cableLength', cableLength);
    cableLengthController.text = box.get('cableLength').toString();

    setIfEmpty('cableTemp', cableTemp);
    cableTempController.text = box.get('cableTemp').toString();

    setIfEmpty('numConductors', numConductors);
    numConductorsController.text = box.get('numConductors').toString();

    setIfEmpty('iSC', iSC);
    iSCController.text = box.get('iSC').toString();

    box.put('gerbau', 'terpau');
  }

  static final list = <(String, double)>[
    ('1mm²', 1.0),
    ('1.5mm²', 1.5),
    ('2.5mm²', 2.5),
    ('4mm²', 4.0),
    ('16AWG', 1.31),
    ('14AWG', 2.08),
    ('12AWG', 3.31),
    ('10AWG', 5.26),
  ];
  double cableCrossSection = list.first.$2;
  double cableTemp = 30.0;
  double cableLength = 10.0;
  int numConductors = 2;
  double iSC = 5.5;

  final cableTempController = TextEditingController();
  final cableLengthController = TextEditingController();
  final numConductorsController = TextEditingController();
  final iSCController = TextEditingController();

  double temperatureCorrectedCopperResistivity() {
    return 17.24e-9 * (1 + 3.93e-3 * (cableTemp - 20.0));
  }

  double singleConductorResistance() {
    return temperatureCorrectedCopperResistivity() *
        cableLength /
        cableCrossSection *
        1e6;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Divider(),
        const Heading(title: 'Solar Cable'),
        Padding(
          padding: const EdgeInsets.all(4.0),
          child: Row(
            // crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              cableSelection(),
              cableLengthInput(),
              cableTempInput(),
              numConductorsInput(),
              iSCInput(),
            ],
          ),
        ),
        solarSummary(),
        computeBtn(),
      ],
    );
  }

  Padding computeBtn() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ElevatedButton(
        onPressed: compute,
        child: const Text('compute'),
      ),
    );
  }

  Row solarSummary() {
    return Row(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(outputText),
          ),
        ),
      ],
    );
  }

  SizedBox iSCInput() {
    return SizedBox(
      width: 64,
      child: TextField(
        controller: iSCController,
        onSubmitted: (_) => compute(),
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.allow(
            RegExp(r'[+-]?([0-9]+([.][0-9]*)?|[.][0-9]+)'),
          )
        ],
        decoration: const InputDecoration(
          labelText: 'Isc',
          hintText: 'Panel sort-circuit current',
        ),
      ),
    );
  }

  SizedBox numConductorsInput() {
    return SizedBox(
      width: 32,
      child: TextField(
        controller: numConductorsController,
        onSubmitted: (_) => compute(),
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: const InputDecoration(
          labelText: 'num.',
        ),
      ),
    );
  }

  SizedBox cableTempInput() {
    return SizedBox(
      width: 64,
      child: TextField(
        controller: cableTempController,
        onSubmitted: (_) => compute(),
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: const InputDecoration(
          labelText: '°C',
        ),
      ),
    );
  }

  SizedBox cableLengthInput() {
    return SizedBox(
      width: 64,
      child: TextField(
        controller: cableLengthController,
        onSubmitted: (_) => compute(),
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: const InputDecoration(
          labelText: 'Length (m)',
        ),
      ),
    );
  }

  DropdownButton<dynamic> cableSelection() {
    return DropdownButton(
      value: cableCrossSection,
      items: list.map<DropdownMenuItem>((val) {
        return DropdownMenuItem(
          value: val.$2,
          child: Text(val.$1),
        );
      }).toList(),
      onChanged: (val) {
        setState(() {
          cableCrossSection = val!;
          compute();
        });
      },
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
    );
  }

  double powerLoss(double i, double r, int n) {
    return i * i * r * n;
  }

  compute() {
    setState(() {
      box.put('cableCrossSection', cableCrossSection);

      cableLength = double.tryParse(cableLengthController.text) ?? cableLength;
      box.put('cableLength', cableLength);

      cableTemp = double.tryParse(cableTempController.text) ?? cableTemp;
      box.put('cableTemp', cableTemp);

      numConductors =
          int.tryParse(numConductorsController.text) ?? numConductors;
      box.put('numConductors', numConductors);

      iSC = double.tryParse(iSCController.text) ?? iSC;
      box.put('iSC', iSC);

      outputText =
          'Single ${cableLength}m conductor resistance:  ${singleConductorResistance().toStringAsPrecision(3)}Ω'
          '\nGiven panel Isc: ${iSC}A, power loss for $numConductors conductors: ${powerLoss(box.get('iSC'), singleConductorResistance(), numConductors).toStringAsFixed(1)}W';
    });
  }
}

class Heading extends StatelessWidget {
  const Heading({
    super.key,
    required this.title,
  });
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.headlineSmall,
    );
  }
}

class BatteryCable extends StatefulWidget {
  const BatteryCable({super.key});

  @override
  State<BatteryCable> createState() => _BatteryCableState();
}

class _BatteryCableState extends State<BatteryCable> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Divider(),
        const Heading(title: 'Battery Cable'),
        Padding(
          padding: const EdgeInsets.all(4.0),
          child: Row(
            children: [
              cableSelection(),
              cableLengthInput(),
              cableTempInput(),
              iMaxInput(),
            ],
          ),
        ),
        battSummary(),
        computeBtn(),
      ],
    );
  }

  DropdownButton<dynamic> cableSelection() {
    return DropdownButton(
      value: battCableCrossSection,
      items: list.map<DropdownMenuItem>((val) {
        return DropdownMenuItem(
          value: val.$2,
          child: Text(val.$1),
        );
      }).toList(),
      onChanged: (val) {
        setState(() {
          battCableCrossSection = val!;
          compute();
        });
      },
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
    );
  }

  static final list = <(String, double)>[
    ('4mm²', 4.0),
    ('6mm²', 6.0),
    ('10mm²', 10.0),
    ('16mm²', 16.0),
    ('25mm²', 25.0),
    ('35mm²', 35.0),
    ('50mm²', 50.0),
    ('70mm²', 70.0),
    ('95mm²', 95.0),
    ('120mm²', 120.0),
    ('12AWG', 3.31),
    ('10AWG', 5.26),
    ('8AWG', 8.37),
    ('6AWG', 13.3),
    ('4AWG', 21.15),
    ('2AWG', 33.63),
    ('0AWG', 53.48),
    ('000AWG', 85.03),
    ('0000AWG', 107.22),
  ];
  double battCableCrossSection = list.first.$2;
  double battCableLength = 0.3;
  final battCableLengthController = TextEditingController();
  double battCableTemp = 40;
  final battCableTempController = TextEditingController();
  double battIMax = 100;
  final battIMaxController = TextEditingController();
  String outputText = '';

  compute() {
    setState(() {
      box.put('battCableCrossSection', battCableCrossSection);

      battCableLength =
          double.tryParse(battCableLengthController.text) ?? battCableLength;
      box.put('battCableLength', battCableLength);

      battCableTemp =
          double.tryParse(battCableTempController.text) ?? battCableTemp;
      box.put('battCableTemp', battCableTemp);

      battIMax = double.tryParse(battIMaxController.text) ?? battIMax;
      box.put('battIMax', battIMax);

      outputText =
          'Single ${battCableLength}m conductor resistance:  ${singleConductorResistance().toStringAsPrecision(3)}Ω'
          '\nGiven max batt current: ${battIMax}A, power loss for 2 conductors: ${powerLoss(box.get('battIMax'), singleConductorResistance(), 2).toStringAsFixed(1)}W';
    });
  }

  dynamic box;

  _init() async {
    await Hive.initFlutter();
    box = await Hive.openBox('solar');
    setIfEmpty('battCableCrossSection', 25.0);
    setState(() {
      battCableCrossSection = box.get('battCableCrossSection');
    });

    setIfEmpty('battCableLength', battCableLength);
    battCableLengthController.text = box.get('battCableLength').toString();

    setIfEmpty('battCableTemp', battCableTemp);
    battCableTempController.text = box.get('battCableTemp').toString();

    setIfEmpty('battIMax', battIMax);
    battIMaxController.text = box.get('battIMax').toString();
  }

  @override
  void initState() {
    super.initState();
    _init();
  }

  setIfEmpty(String key, dynamic value) {
    if (box.get(key) != null) return;
    box.put(key, value);
    debugPrint('set $key to $value');
  }

  double temperatureCorrectedCopperResistivity() {
    return 17.24e-9 * (1 + 3.93e-3 * (battCableTemp - 20.0));
  }

  double singleConductorResistance() {
    return temperatureCorrectedCopperResistivity() *
        battCableLength /
        battCableCrossSection *
        1e6;
  }

  double powerLoss(double i, double r, int n) {
    return i * i * r * n;
  }

  SizedBox cableLengthInput() {
    return SizedBox(
      width: 64,
      child: TextField(
        controller: battCableLengthController,
        onSubmitted: (_) => compute(),
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.allow(
            RegExp(r'[+-]?([0-9]+([.][0-9]*)?|[.][0-9]+)'),
          )
        ],
        decoration: const InputDecoration(
          labelText: 'Length (m)',
        ),
      ),
    );
  }

  SizedBox cableTempInput() {
    return SizedBox(
      width: 64,
      child: TextField(
        controller: battCableTempController,
        onSubmitted: (_) => compute(),
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: const InputDecoration(
          labelText: '°C',
        ),
      ),
    );
  }

  SizedBox iMaxInput() {
    return SizedBox(
      width: 64,
      child: TextField(
        controller: battIMaxController,
        onSubmitted: (_) => compute(),
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.allow(
            RegExp(r'[+-]?([0-9]+([.][0-9]*)?|[.][0-9]+)'),
          )
        ],
        decoration: const InputDecoration(
          labelText: 'IMax',
        ),
      ),
    );
  }

  Row battSummary() {
    return Row(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(outputText),
          ),
        ),
      ],
    );
  }

  Padding computeBtn() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ElevatedButton(
        onPressed: compute,
        child: const Text('compute'),
      ),
    );
  }
}
