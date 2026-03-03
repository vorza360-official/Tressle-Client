import 'package:latlong2/latlong.dart';

class BarberShop {
  final int id;
  final String name;
  final double rating;
  final int reviews;
  final String description;
  final String address;
  final LatLng location;

  BarberShop({
    required this.id,
    required this.name,
    required this.rating,
    required this.reviews,
    required this.description,
    required this.address,
    required this.location,
  });
}