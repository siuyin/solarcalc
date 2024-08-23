import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:solar/hive_persistence.dart';
import 'common_widgets.dart';

/// EnergyBudget budgets for daily energy availability given a panel, inverter and battery configuration.
class EnergyBudget extends StatefulWidget {
  const EnergyBudget({super.key});

  @override
  State<EnergyBudget> createState() => _EnergyBudgetState();
}

class _EnergyBudgetState extends State<EnergyBudget> with HivePersistence {
  @override
  void initState() {
    super.initState();
    _init();
  }

  _init() async {
    await hiveInit();

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

  Padding panelPowerCalc() {
    var panelPower = Expanded(
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
    );
    var numPanels = Expanded(
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
          );
    var panelSummary = Expanded(
            flex: 4,
            child: Text(
              '${totalPanelPower()} W-peak.'
              '\nEst. ${(wattHoursPerDay() / 1000).toStringAsPrecision(floatPrecision)} kWh/day',
              textAlign: TextAlign.left,
            ),
          );
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Row(
        children: [
          panelPower,
          const Text(' W-peak x '),
          numPanels,
          panelSummary,
        ],
      ),
    );
  }

  Padding panelVoltageCalc() {
    var panelOpenCircuitVolts = Expanded(
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
        );
    var solarInverterMinVolts = Expanded(
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
        );
    var solarInverterMaxVolts = Expanded(
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
        );
    var voltageCompatibilitySummary = Expanded(
          flex: 1,
          child: openCircuitVoltageConfig,
        );
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Row(children: [
        panelOpenCircuitVolts,
        solarInverterMinVolts,
        solarInverterMaxVolts,
        voltageCompatibilitySummary,
      ]),
    );
  }

  Padding batteryCapacityCalc() {
    var numCells = Expanded(
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
          );
    var cellCapacity = Expanded(
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
          );
    var battInfoSummary = Expanded(
            flex: 2,
            child: batteryInfo,
          );
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          numCells,
          cellCapacity,
          battInfoSummary,
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

  compute() {
    checkOpenCircuitVoltage();
    updatePowerCalc();
    updateBatteryCalc();
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
}
