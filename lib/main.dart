import 'package:flutter/material.dart';

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
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
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
      body: const Column(
        children: [
          Text('a'),
          Text('b'),
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

class StatefulColumn extends StatefulWidget {
  const StatefulColumn({super.key});

  @override
  State<StatefulColumn> createState() => _StatefulColumnState();
}

class _StatefulColumnState extends State<StatefulColumn> {
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    throw UnimplementedError();
  }
}

hiveDemo() async {}
