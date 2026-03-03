// shop_location_map_screen.dart
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';

class ShopLocationMapScreen extends StatefulWidget {
  final String shopName;
  final String shopAddress;
  final String? latitude;
  final String? longitude;
  final String phoneNumber;

  const ShopLocationMapScreen({
    Key? key,
    required this.shopName,
    required this.shopAddress,
    this.latitude,
    this.longitude,
    required this.phoneNumber,
  }) : super(key: key);

  @override
  _ShopLocationMapScreenState createState() => _ShopLocationMapScreenState();
}

class _ShopLocationMapScreenState extends State<ShopLocationMapScreen> {
  Completer<GoogleMapController> _controller = Completer();
  LatLng? _shopLocation;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _getShopLocation();
    print('Latitude: ${widget.latitude}');
    print('Longitude: ${widget.longitude}');
  }

  Future<void> _getShopLocation() async {
    try {
      // Try to get coordinates from shop data
      if (widget.latitude != null && widget.longitude != null) {
        double lat = double.tryParse(widget.latitude!) ?? 0.0;
        double lng = double.tryParse(widget.longitude!) ?? 0.0;

        if (lat != 0.0 && lng != 0.0) {
          setState(() {
            _shopLocation = LatLng(lat, lng);
            _isLoading = false; // FIX: Set loading to false
          });
        } else {
          // Geocode address if coordinates are invalid
          await _geocodeAddress();
        }
      } else {
        // Geocode address if no coordinates provided
        await _geocodeAddress();
      }
    } catch (e) {
      print('Error getting location: $e');
      setState(() {
        _errorMessage = 'Could not load location';
        _isLoading = false;
      });
    }
  }

  Future<void> _geocodeAddress() async {
    try {
      List<Location> locations = await locationFromAddress(widget.shopAddress);
      if (locations.isNotEmpty) {
        setState(() {
          _shopLocation = LatLng(
            locations.first.latitude,
            locations.first.longitude,
          );
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Address not found';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Geocoding error: $e');
      // Fallback to a default location (Islamabad, Pakistan)
      setState(() {
        _shopLocation = LatLng(33.6844, 73.0479);
        _isLoading = false;
      });
    }
  }

  Future<void> _makePhoneCall() async {
    final phoneNumber = widget.phoneNumber;

    // Clean the phone number
    String cleanedNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

    // Check if number starts with country code, add if not
    if (!cleanedNumber.startsWith('+')) {
      cleanedNumber = '+92${cleanedNumber.replaceAll('+', '')}';
    }

    final Uri telUri = Uri(scheme: 'tel', path: cleanedNumber);

    try {
      if (await canLaunchUrl(telUri)) {
        await launchUrl(telUri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not launch phone app'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error launching phone: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error making call'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Shop Location'),
        backgroundColor: Colors.teal[700],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.call),
            onPressed: _makePhoneCall,
            tooltip: 'Call Shop',
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading map...'),
                ],
              ),
            )
          : _errorMessage.isNotEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 50),
                  SizedBox(height: 16),
                  Text(
                    _errorMessage,
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 8),
                  Text(
                    widget.shopAddress,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            )
          : _shopLocation == null
          ? Center(child: Text('Unable to load location'))
          : Column(
              children: [
                // Shop Info Section
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.shopName,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: Colors.teal[700],
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.shopAddress,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.phone, color: Colors.teal[700], size: 20),
                          SizedBox(width: 8),
                          GestureDetector(
                            onTap: _makePhoneCall,
                            child: Text(
                              widget.phoneNumber,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Map Section
                Expanded(
                  child: GoogleMap(
                    onMapCreated: (GoogleMapController controller) {
                      if (!_controller.isCompleted) {
                        _controller.complete(controller);
                      }
                    },
                    initialCameraPosition: CameraPosition(
                      target: _shopLocation!,
                      zoom: 15,
                    ),
                    markers: {
                      Marker(
                        markerId: MarkerId('shop_location'),
                        position: _shopLocation!,
                        infoWindow: InfoWindow(
                          title: widget.shopName,
                          snippet: widget.shopAddress,
                        ),
                        icon: BitmapDescriptor.defaultMarker,
                      ),
                    },
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    zoomControlsEnabled: false,
                  ),
                ),
              ],
            ),
      floatingActionButton: _shopLocation != null && !_isLoading
          ? FloatingActionButton(
              onPressed: () async {
                if (_controller.isCompleted) {
                  final GoogleMapController controller =
                      await _controller.future;
                  controller.animateCamera(
                    CameraUpdate.newLatLngZoom(_shopLocation!, 16),
                  );
                }
              },
              backgroundColor: Colors.teal[700],
              child: Icon(Icons.location_searching, color: Colors.white),
              tooltip: 'Focus on Shop',
            )
          : null,
    );
  }
}
