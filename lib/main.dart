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
  int _counter = 0;
  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  void _decrementCounter() {
    setState(() {
      _counter--;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: ListView(
        children: const [
          Budget(),
          Solar(),
          Utility(),
        ],
      ),
      // body: oldMainColoumn(context),
      // floatingActionButton: fab(context),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: _incrementCounter,
      //   tooltip: 'Increment',
      //   child: const Icon(Icons.remove),
      // ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  Column oldMainColoumn(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        mainRow(context),
      ],
    );
  }

  Row fab(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        IconButton(
          onPressed: _incrementCounter,
          icon: const Icon(Icons.add),
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith(
              (state) {
                return Theme.of(context).colorScheme.primaryContainer;
              },
            ),
          ),
        ),
        IconButton(
          onPressed: _decrementCounter,
          icon: const Icon(Icons.remove),
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith(
              (state) {
                return Theme.of(context).colorScheme.inversePrimary;
              },
            ),
          ),
        ),
      ],
    );
  }

  Row mainRow(BuildContext context) {
    var infoText = Expanded(
      flex: 5,
      child: Text(
        'You have pushed the button this many times:',
        style: Theme.of(context).textTheme.headlineSmall,
      ),
    );
    var count = Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Text(
        '$_counter',
        style: Theme.of(context).textTheme.headlineMedium,
      ),
    );
    var rightText = Expanded(
      flex: 1,
      child: Text(
        'more text',
        style: Theme.of(context).textTheme.headlineSmall,
      ),
    );
    return Row(
      children: [
        infoText,
        count,
        rightText,
      ],
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
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: TextField(
              controller: panelPowerController,
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
          ElevatedButton(
            onPressed: updatePowerCalc,
            child: const Text('compute'),
          ),
        ],
      ),
    );
  }
}

hiveDemo() async {}
