import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:solar/hive_persistence.dart';
import 'common_widgets.dart';

class BatteryCable extends StatefulWidget {
  const BatteryCable({super.key});

  @override
  State<BatteryCable> createState() => _BatteryCableState();
}

class _BatteryCableState extends State<BatteryCable> with HivePersistence {
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

  _init() async {
    await hiveInit();
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