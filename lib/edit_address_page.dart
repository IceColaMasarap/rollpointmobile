import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;

class EditAddressPage extends StatefulWidget {
  final Map<String, dynamic>? currentAddress;
  
  const EditAddressPage({super.key, this.currentAddress});

  @override
  State<EditAddressPage> createState() => _EditAddressPageState();
}

// Human-friendly region labels (PSGC "name" → UI label)
final Map<String, String> _regionLabels = {
  "ILOCOS REGION": "Region I (Ilocos Region)",
  "CAGAYAN VALLEY": "Region II (Cagayan Valley)",
  "CENTRAL LUZON": "Region III (Central Luzon)",
  "CALABARZON": "Region IV-A (CALABARZON)",
  "MIMAROPA REGION": "Region IV-B (MIMAROPA)",
  "BICOL REGION": "Region V (Bicol Region)",
  "WESTERN VISAYAS": "Region VI (Western Visayas)",
  "CENTRAL VISAYAS": "Region VII (Central Visayas)",
  "EASTERN VISAYAS": "Region VIII (Eastern Visayas)",
  "ZAMBOANGA PENINSULA": "Region IX (Zamboanga Peninsula)",
  "NORTHERN MINDANAO": "Region X (Northern Mindanao)",
  "DAVAO REGION": "Region XI (Davao Region)",
  "SOCCSKSARGEN": "Region XII (SOCCSKSARGEN)",
  "CARAGA": "Region XIII (Caraga)",
  "NCR": "National Capital Region (NCR)",
  "CAR": "Cordillera Administrative Region (CAR)",
  "BARMM": "Bangsamoro Autonomous Region in Muslim Mindanao (BARMM)",
};

// Natural region order (for dropdowns)
final Map<String, int> _regionOrder = {
  "ILOCOS REGION": 1,
  "CAGAYAN VALLEY": 2,
  "CENTRAL LUZON": 3,
  "CALABARZON": 4,
  "MIMAROPA REGION": 5,
  "BICOL REGION": 6,
  "WESTERN VISAYAS": 7,
  "CENTRAL VISAYAS": 8,
  "EASTERN VISAYAS": 9,
  "ZAMBOANGA PENINSULA": 10,
  "NORTHERN MINDANAO": 11,
  "DAVAO REGION": 12,
  "SOCCSKSARGEN": 13,
  "CARAGA": 14,
  "NCR": 15,
  "CAR": 16,
  "BARMM": 17,
};

String _displayRegionName(String officialName) {
  return _regionLabels[officialName.toUpperCase()] ?? officialName;
}

class _EditAddressPageState extends State<EditAddressPage> {
  bool _isLoading = false;
  String? _errorMessage;

  // ---- Address Data ----
  String? _selectedRegionCode, _selectedRegionName;
  String? _selectedProvinceCode, _selectedProvinceName;
  String? _selectedCityCode, _selectedCityName;
  String? _selectedBarangayCode, _selectedBarangayName;

  List<Map<String, String>> _regions = [];
  List<Map<String, String>> _provinces = [];
  List<Map<String, String>> _cities = [];
  List<Map<String, String>> _barangays = [];

  bool _isLoadingRegions = false;
  bool _isLoadingProvinces = false;
  bool _isLoadingCities = false;
  bool _isLoadingBarangays = false;

  final _streetController = TextEditingController();

  SupabaseClient get _supabase => Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _initializeCurrentAddress();
    _fetchRegions();
  }

  void _initializeCurrentAddress() {
    if (widget.currentAddress != null) {
      _selectedRegionName = widget.currentAddress!['region'];
      _selectedProvinceName = widget.currentAddress!['province'];
      _selectedCityName = widget.currentAddress!['city'];
      _selectedBarangayName = widget.currentAddress!['barangay'];
      _streetController.text = widget.currentAddress!['street'] ?? '';
    }
  }

  @override
  void dispose() {
    _streetController.dispose();
    super.dispose();
  }

  // ---------------- PSGC FETCHERS ----------------

  static const _psgcBase = 'https://psgc.gitlab.io/api';

  Future<List<dynamic>> _getJsonList(String url) async {
    final res = await http
        .get(Uri.parse(url))
        .timeout(const Duration(seconds: 20));
    if (res.statusCode != 200) {
      throw Exception('HTTP ${res.statusCode} – ${res.reasonPhrase}');
    }
    final data = json.decode(res.body);
    if (data is! List) throw Exception('Unexpected response');
    return data;
  }

  Future<void> _fetchRegions() async {
    setState(() => _isLoadingRegions = true);
    try {
      final data = await _getJsonList('$_psgcBase/regions/');
      setState(() {
        _regions =
            data
                .map<Map<String, String>>(
                  (r) => {
                    'code': (r['code'] ?? '').toString(),
                    'name': (r['name'] ?? '').toString(),
                  },
                )
                .where((m) => m['code']!.isNotEmpty && m['name']!.isNotEmpty)
                .toList()
              ..sort((a, b) {
                final orderA = _regionOrder[a['name']!.toUpperCase()] ?? 999;
                final orderB = _regionOrder[b['name']!.toUpperCase()] ?? 999;
                return orderA.compareTo(orderB);
              });
      });

      // If we have a current region, find its code and fetch provinces
      if (_selectedRegionName != null) {
        final region = _regions.firstWhereOrNull(
          (r) => r['name']!.toUpperCase() == _selectedRegionName!.toUpperCase(),
        );
        if (region != null) {
          _selectedRegionCode = region['code'];
          await _fetchProvinces(region['code']!);
        }
      }
    } catch (e) {
      _showErrorSnackBar('Failed to load regions. Please try again.');
    } finally {
      setState(() => _isLoadingRegions = false);
    }
  }

  Future<void> _fetchProvinces(String regionCode) async {
    setState(() => _isLoadingProvinces = true);
    try {
      final list = await _getJsonList(
        '$_psgcBase/regions/$regionCode/provinces/',
      );
      setState(() {
        _provinces =
            list
                .map<Map<String, String>>(
                  (p) => {
                    'code': (p['code'] ?? '').toString(),
                    'name': (p['name'] ?? '').toString(),
                  },
                )
                .where((m) => m['code']!.isNotEmpty && m['name']!.isNotEmpty)
                .toList()
              ..sort((a, b) => a['name']!.compareTo(b['name']!));
      });

      // Special handling: if no provinces (e.g., NCR), fetch cities directly from region
      if (_provinces.isEmpty) {
        await _fetchCitiesByRegion(regionCode);
      } else if (_selectedProvinceName != null) {
        // If we have a current province, find its code and fetch cities
        final province = _provinces.firstWhereOrNull(
          (p) => p['name']!.toUpperCase() == _selectedProvinceName!.toUpperCase(),
        );
        if (province != null) {
          _selectedProvinceCode = province['code'];
          await _fetchCities(province['code']!);
        }
      }
    } catch (e) {
      _showErrorSnackBar('Failed to load provinces. Please try again.');
    } finally {
      setState(() => _isLoadingProvinces = false);
    }
  }

  Future<void> _fetchCities(String provinceCode) async {
    setState(() => _isLoadingCities = true);
    try {
      final list = await _getJsonList(
        '$_psgcBase/provinces/$provinceCode/cities-municipalities/',
      );
      setState(() {
        _cities =
            list
                .map<Map<String, String>>(
                  (c) => {
                    'code': (c['code'] ?? '').toString(),
                    'name': (c['name'] ?? '').toString(),
                  },
                )
                .where((m) => m['code']!.isNotEmpty && m['name']!.isNotEmpty)
                .toList()
              ..sort((a, b) => a['name']!.compareTo(b['name']!));
      });

      // If we have a current city, find its code and fetch barangays
      if (_selectedCityName != null) {
        final city = _cities.firstWhereOrNull(
          (c) => c['name']!.toUpperCase() == _selectedCityName!.toUpperCase(),
        );
        if (city != null) {
          _selectedCityCode = city['code'];
          await _fetchBarangays(city['code']!);
        }
      }
    } catch (e) {
      _showErrorSnackBar('Failed to load cities/municipalities.');
    } finally {
      setState(() => _isLoadingCities = false);
    }
  }

  Future<void> _fetchCitiesByRegion(String regionCode) async {
    setState(() => _isLoadingCities = true);
    try {
      final list = await _getJsonList(
        '$_psgcBase/regions/$regionCode/cities-municipalities/',
      );
      setState(() {
        _cities =
            list
                .map<Map<String, String>>(
                  (c) => {
                    'code': (c['code'] ?? '').toString(),
                    'name': (c['name'] ?? '').toString(),
                  },
                )
                .where((m) => m['code']!.isNotEmpty && m['name']!.isNotEmpty)
                .toList()
              ..sort((a, b) => a['name']!.compareTo(b['name']!));
      });

      // If we have a current city, find its code and fetch barangays
      if (_selectedCityName != null) {
        final city = _cities.firstWhereOrNull(
          (c) => c['name']!.toUpperCase() == _selectedCityName!.toUpperCase(),
        );
        if (city != null) {
          _selectedCityCode = city['code'];
          await _fetchBarangays(city['code']!);
        }
      }
    } catch (e) {
      _showErrorSnackBar('Failed to load cities/municipalities.');
    } finally {
      setState(() => _isLoadingCities = false);
    }
  }

  Future<void> _fetchBarangays(String cityOrMunCode) async {
    setState(() => _isLoadingBarangays = true);
    try {
      final list = await _getJsonList(
        '$_psgcBase/cities-municipalities/$cityOrMunCode/barangays/',
      );
      setState(() {
        _barangays =
            list
                .map<Map<String, String>>(
                  (b) => {
                    'code': (b['code'] ?? '').toString(),
                    'name': (b['name'] ?? '').toString(),
                  },
                )
                .where((m) => m['code']!.isNotEmpty && m['name']!.isNotEmpty)
                .toList()
              ..sort((a, b) => a['name']!.compareTo(b['name']!));
      });
    } catch (e) {
      _showErrorSnackBar('Failed to load barangays.');
    } finally {
      setState(() => _isLoadingBarangays = false);
    }
  }

  // ---------------- END PSGC FETCHERS ----------------

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  bool _validateAddress() {
    if (_selectedRegionName == null) {
      _showErrorSnackBar('Region is required');
      return false;
    }

    // If region has provinces, province is required
    final regionHasProvinces = _provinces.isNotEmpty;
    if (regionHasProvinces && _selectedProvinceName == null) {
      _showErrorSnackBar('Province is required');
      return false;
    }

    if (_selectedCityName == null) {
      _showErrorSnackBar('City/Municipality is required');
      return false;
    }
    if (_selectedBarangayName == null) {
      _showErrorSnackBar('Barangay is required');
      return false;
    }
    return true;
  }

  Future<void> _saveAddress() async {
    if (!_validateAddress()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('No authenticated user found');
      }

      await _supabase.from('addresses').update({
        'region': _selectedRegionName,
        'province': _selectedProvinceName,
        'city': _selectedCityName,
        'barangay': _selectedBarangayName,
        'street': _streetController.text.trim().isEmpty 
            ? null 
            : _streetController.text.trim(),
      }).eq('id', user.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Address updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (error) {
      setState(() {
        _errorMessage = 'Failed to save address: $error';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF059669),
        foregroundColor: Colors.white,
        title: const Text(
          'Edit Address',
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        elevation: 0,
        
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_errorMessage != null)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red.shade700),
                    textAlign: TextAlign.center,
                  ),
                ),

              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Address Information",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF059669),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Region
                      _buildDropdown(
                        value: _selectedRegionName == null
                            ? null
                            : _displayRegionName(_selectedRegionName!),
                        items: _regions
                            .map((r) => _displayRegionName(r['name']!))
                            .toList(),
                        hint: _isLoadingRegions ? "Loading regions..." : "Region *",
                        icon: Icons.map,
                        onChanged: (_isLoadingRegions)
                            ? null
                            : (value) {
                                final region = _regions.firstWhere(
                                  (r) => _displayRegionName(r['name']!) == value,
                                );
                                setState(() {
                                  _selectedRegionCode = region['code'];
                                  _selectedRegionName = region['name'];

                                  // Reset dependents
                                  _selectedProvinceCode = null;
                                  _selectedProvinceName = null;
                                  _selectedCityCode = null;
                                  _selectedCityName = null;
                                  _selectedBarangayCode = null;
                                  _selectedBarangayName = null;
                                  _provinces.clear();
                                  _cities.clear();
                                  _barangays.clear();
                                });
                                _fetchProvinces(region['code']!);
                              },
                        required: true,
                        isLoading: _isLoadingRegions,
                        enabled: _regions.isNotEmpty,
                      ),

                      const SizedBox(height: 15),

                      // Province
                      _buildDropdown(
                        value: _selectedProvinceName,
                        items: _provinces.map((p) => p['name']!).toList(),
                        hint: _selectedRegionName == null
                            ? "Select a region first"
                            : (_isLoadingProvinces
                                  ? "Loading provinces..."
                                  : (_provinces.isEmpty
                                        ? "No provinces (skip)"
                                        : "Province *")),
                        icon: Icons.location_city,
                        onChanged: (_isLoadingProvinces || _provinces.isEmpty)
                            ? null
                            : (value) {
                                final province = _provinces.firstWhere(
                                  (p) => p['name'] == value,
                                );
                                setState(() {
                                  _selectedProvinceCode = province['code'];
                                  _selectedProvinceName = province['name'];

                                  // Reset dependents
                                  _selectedCityCode = null;
                                  _selectedCityName = null;
                                  _selectedBarangayCode = null;
                                  _selectedBarangayName = null;
                                  _cities.clear();
                                  _barangays.clear();
                                });
                                _fetchCities(province['code']!);
                              },
                        required: _provinces.isNotEmpty,
                        isLoading: _isLoadingProvinces,
                        enabled: _selectedRegionName != null && _provinces.isNotEmpty,
                      ),
                      const SizedBox(height: 15),

                      // City / Municipality
                      _buildDropdown(
                        value: _selectedCityName,
                        items: _cities.map((c) => c['name']!).toList(),
                        hint: (_selectedRegionName == null)
                            ? "Select a region first"
                            : (_isLoadingCities
                                  ? "Loading cities/municipalities..."
                                  : (_cities.isEmpty
                                        ? "Select a province first"
                                        : "City/Municipality *")),
                        icon: Icons.location_on,
                        onChanged: (_isLoadingCities || _cities.isEmpty)
                            ? null
                            : (value) {
                                final city = _cities.firstWhere(
                                  (c) => c['name'] == value,
                                );
                                setState(() {
                                  _selectedCityCode = city['code'];
                                  _selectedCityName = city['name'];

                                  // Reset dependents
                                  _selectedBarangayCode = null;
                                  _selectedBarangayName = null;
                                  _barangays.clear();
                                });
                                _fetchBarangays(city['code']!);
                              },
                        required: true,
                        isLoading: _isLoadingCities,
                        enabled: _cities.isNotEmpty,
                      ),
                      const SizedBox(height: 15),

                      // Barangay
                      _buildDropdown(
                        value: _selectedBarangayName,
                        items: _barangays.map((b) => b['name']!).toList(),
                        hint: (_selectedCityName == null)
                            ? "Select city/municipality first"
                            : (_isLoadingBarangays
                                  ? "Loading barangays..."
                                  : "Barangay *"),
                        icon: Icons.home,
                        onChanged: (_isLoadingBarangays || _barangays.isEmpty)
                            ? null
                            : (value) {
                                final brgy = _barangays.firstWhere(
                                  (b) => b['name'] == value,
                                );
                                setState(() {
                                  _selectedBarangayCode = brgy['code'];
                                  _selectedBarangayName = brgy['name'];
                                });
                              },
                        required: true,
                        isLoading: _isLoadingBarangays,
                        enabled: _barangays.isNotEmpty,
                      ),

                      const SizedBox(height: 15),

                      // Street (Optional - Manual input)
                      TextField(
                        controller: _streetController,
                        decoration: InputDecoration(
                          labelText: "Street (Optional)",
                          prefixIcon: const Icon(Icons.home_outlined, color: Color(0xFF059669)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: Color(0xFF059669),
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveAddress,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "Save Address",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required List<String> items,
    required String hint,
    required IconData icon,
    required ValueChanged<String?>? onChanged,
    bool required = false,
    bool isLoading = false,
    bool enabled = true,
  }) {
    final showSpinner = isLoading;
    return DropdownButtonFormField<String>(
      value: items.contains(value) ? value : null,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF059669)),
        suffixIcon: showSpinner
            ? const Padding(
                padding: EdgeInsets.only(right: 12),
                child: SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: required && value == null
                ? Colors.red
                : const Color(0xFF059669),
            width: 2,
          ),
        ),
        filled: true,
        fillColor: enabled ? Colors.grey[50] : Colors.grey[200],
      ),
      items: items.map((item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(item, overflow: TextOverflow.ellipsis),
        );
      }).toList(),
      onChanged: enabled ? onChanged : null,
    );
  }
}

// Extension to help with null safety
extension ListExtensions<T> on List<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (T element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}