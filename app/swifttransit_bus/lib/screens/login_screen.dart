import 'package:flutter/material.dart';
import 'package:swifttransit_bus/models/route_models.dart';
import 'package:swifttransit_bus/screens/home_screen.dart';
import 'package:swifttransit_bus/services/api_service.dart';
import 'package:swifttransit_bus/services/location_service.dart';
import 'package:swifttransit_bus/services/route_storage.dart';
import 'package:swifttransit_bus/services/socket_service.dart';
import 'package:swifttransit_bus/main.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.apiService,
    required this.storage,
    required this.locationService,
    required this.socketService,
  });

  final ApiService apiService;
  final RouteStorage storage;
  final LocationService locationService;
  final SocketService socketService;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _busIdController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _busIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final login = await widget.apiService.login(
        busIdentifier: _busIdController.text.trim(),
        password: _passwordController.text,
      );

      final route = await widget.apiService.fetchRoute(
        routeId: login.routeId,
        token: login.token,
      );

      await widget.storage.saveAuth(
        token: login.token,
        routeId: login.routeId,
        busId: login.busId,
      );
      await widget.storage.saveRoute(route);

      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => HomeScreen(
          apiService: widget.apiService,
          session: SessionData(
            token: login.token,
            routeId: login.routeId,
            busId: login.busId,
          ),
          route: route,
          storage: widget.storage,
          locationService: widget.locationService,
          socketService: widget.socketService,
        ),
      ));
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Bus Login',
                      style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _busIdController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Bus ID',
                    ),
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Password',
                    ),
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  if (_error != null)
                    Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _handleLogin,
                      icon: _isLoading
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.login),
                      label: Text(_isLoading ? 'Logging in...' : 'Login'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
