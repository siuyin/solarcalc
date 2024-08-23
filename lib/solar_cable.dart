import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'common_widgets.dart';

/// SolarCable computes solar cable losses given cable length, temperature and panel short-circuit current.
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
    ('6mm²', 6.0),
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