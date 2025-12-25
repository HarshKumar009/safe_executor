import 'package:flutter/material.dart';
import 'package:safe_executor/safe_executor.dart';

class NetworkError {
  final String message;
  NetworkError(this.message);

  @override
  String toString() => 'NetworkError: $message';
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SafeExecutor Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0D47A1),
          primary: const Color(0xFF0D47A1),
          secondary: const Color(0xFF1976D2),
        ),
        useMaterial3: true,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      home: const SafeExecutorDemo(),
    );
  }
}

class SafeExecutorDemo extends StatefulWidget {
  const SafeExecutorDemo({super.key});

  @override
  State<SafeExecutorDemo> createState() => _SafeExecutorDemoState();
}

enum ResultState { initial, loading, success, failure }

class _SafeExecutorDemoState extends State<SafeExecutorDemo> {
  ResultState _resultState = ResultState.initial;
  String _resultMessage = 'Press a button to see the result';

  int _retryCounter = 0;

  void _resetResult() {
    setState(() {
      _resultState = ResultState.initial;
      _resultMessage = 'Press a button to see the result';
    });
  }

  void _updateResult(bool isSuccess, String message) {
    setState(() {
      _resultState = isSuccess ? ResultState.success : ResultState.failure;
      _resultMessage = message;
    });
    print('${isSuccess ? "SUCCESS" : "FAILURE"}: $message');
  }

  void _setLoading() {
    setState(() {
      _resultState = ResultState.loading;
      _resultMessage = 'Executing...';
    });
  }

  Widget _buildResultCard() {
    Color accentColor;
    IconData icon;
    Color iconColor;

    switch (_resultState) {
      case ResultState.initial:
        accentColor = const Color(0xFF1976D2);
        icon = Icons.info_outline;
        iconColor = const Color(0xFF1976D2);
        break;
      case ResultState.loading:
        accentColor = Colors.orange.shade700;
        icon = Icons.hourglass_empty;
        iconColor = Colors.orange.shade700;
        break;
      case ResultState.success:
        accentColor = Colors.green.shade700;
        icon = Icons.check_circle;
        iconColor = Colors.green.shade700;
        break;
      case ResultState.failure:
        accentColor = Colors.red.shade700;
        icon = Icons.error;
        iconColor = Colors.red.shade700;
        break;
    }

    return Container(
      key: ValueKey<ResultState>(_resultState),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: accentColor, width: 4),
        ),
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            if (_resultState == ResultState.loading)
              Column(
                children: [
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(iconColor),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _resultMessage,
                    style: TextStyle(
                      fontSize: 16,
                      color: iconColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              )
            else
              Row(
                children: [
                  Icon(
                    icon,
                    color: iconColor,
                    size: 36,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      _resultMessage,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _runSuccessCase() async {
    _setLoading();

    final result = await SafeExecutor.run(
      functionToExecute: () async {
        await Future.delayed(const Duration(seconds: 1));
        return 'Data fetched successfully!';
      },
    );

    switch (result) {
      case Success(value: final data):
        _updateResult(true, data);
      case Failure(value: final error):
        _updateResult(false, error.toString());
    }
  }

  Future<void> _runFailureCase() async {
    _setLoading();

    final result = await SafeExecutor.run(
      functionToExecute: () async {
        await Future.delayed(const Duration(seconds: 1));
        throw Exception('Failed to fetch data.');
      },
    );

    switch (result) {
      case Success(value: final data):
        _updateResult(true, data);
      case Failure(value: final error):
        _updateResult(false, error.toString());
    }
  }

  Future<void> _runWithRetries() async {
    _setLoading();
    _retryCounter = 0;

    final result = await SafeExecutor.run(
      functionToExecute: () async {
        await Future.delayed(const Duration(milliseconds: 500));
        _retryCounter++;
        print('Attempt #$_retryCounter');

        if (_retryCounter < 3) {
          throw Exception('Attempt $_retryCounter failed');
        }

        return 'Success after $_retryCounter attempts!';
      },
      retries: 2,
      retryDelay: const Duration(seconds: 1),
    );

    switch (result) {
      case Success(value: final data):
        _updateResult(true, data);
      case Failure(value: final error):
        _updateResult(false, error.toString());
    }
  }

  Future<void> _runWithTimeout() async {
    _setLoading();

    final result = await SafeExecutor.run(
      functionToExecute: () async {
        await Future.delayed(const Duration(seconds: 3));
        return 'This should not be returned';
      },
      timeout: const Duration(seconds: 2),
    );

    switch (result) {
      case Success(value: final data):
        _updateResult(true, data);
      case Failure(value: final error):
        _updateResult(false, 'Operation timed out after 2 seconds');
    }
  }

  Future<void> _runWithErrorMapper() async {
    _setLoading();

    final result = await SafeExecutor.run<String, NetworkError>(
      functionToExecute: () async {
        await Future.delayed(const Duration(seconds: 1));
        throw Exception('Generic network exception');
      },
      errorMapper: (error) => NetworkError('Could not connect to server.'),
    );

    switch (result) {
      case Success(value: final data):
        _updateResult(true, data);
      case Failure(value: final error):
        _updateResult(false, error.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isLoading = _resultState == ResultState.loading;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        title: const Text(
          'SafeExecutor Demo',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetResult,
            tooltip: 'Reset',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary,
              Colors.grey.shade50,
            ],
            stops: const [0.0, 0.3],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(
                        scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                          CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOutCubic,
                          ),
                        ),
                        child: child,
                      ),
                    );
                  },
                  child: _buildResultCard(),
                ),
                const SizedBox(height: 36),

                ElevatedButton.icon(
                  onPressed: isLoading ? null : _runSuccessCase,
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Run Success Case'),
                ),
                const SizedBox(height: 12),

                OutlinedButton.icon(
                  onPressed: isLoading ? null : _runFailureCase,
                  icon: const Icon(Icons.error),
                  label: const Text('Run Failure Case'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade700,
                    side: BorderSide(color: Colors.red.shade700, width: 1.5),
                  ),
                ),
                const SizedBox(height: 12),

                ElevatedButton.icon(
                  onPressed: isLoading ? null : _runWithRetries,
                  icon: const Icon(Icons.replay),
                  label: const Text('Run With Retries (Succeeds on 3rd try)'),
                ),
                const SizedBox(height: 12),

                OutlinedButton.icon(
                  onPressed: isLoading ? null : _runWithTimeout,
                  icon: const Icon(Icons.timer_off),
                  label: const Text('Run With Timeout (Will Fail)'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade700,
                    side: BorderSide(color: Colors.red.shade700, width: 1.5),
                  ),
                ),
                const SizedBox(height: 12),

                ElevatedButton.icon(
                  onPressed: isLoading ? null : _runWithErrorMapper,
                  icon: const Icon(Icons.transform),
                  label: const Text('Run With Error Mapper'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}