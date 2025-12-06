import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:swifttransit_bus/models/route_models.dart';

class RouteStorage {
  static const _tokenKey = 'bus_jwt';
  static const _routeIdKey = 'route_id';
  static const _busIdKey = 'bus_identifier';
  static const _busCredentialIdKey = 'bus_credential_id';
  static const _variantKey = 'route_variant';
  static const _routeCacheKey = 'route_cache';

  Future<void> saveAuth({
    required String token,
    required int routeId,
    required String busId,
    required int busCredentialId,
    required String variant,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setInt(_routeIdKey, routeId);
    await prefs.setString(_busIdKey, busId);
    await prefs.setInt(_busCredentialIdKey, busCredentialId);
    await prefs.setString(_variantKey, variant);
  }

  Future<void> saveRoute(BusRoute route) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_routeCacheKey, route.toCache());
  }

  Future<String?> get token async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<int?> get routeId async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_routeIdKey);
  }

  Future<int?> get busCredentialId async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_busCredentialIdKey);
  }

  Future<String?> get busId async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_busIdKey);
  }

  Future<String?> get variant async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_variantKey);
  }

  Future<BusRoute?> get cachedRoute async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_routeCacheKey);
    if (raw == null) return null;
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return BusRoute.fromJson(json);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_routeIdKey);
    await prefs.remove(_routeCacheKey);
    await prefs.remove(_busIdKey);
    await prefs.remove(_busCredentialIdKey);
    await prefs.remove(_variantKey);
  }
}
