import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';

class MapPickerScreen extends StatefulWidget {
  final LatLng initialLocation;
  final Function(LatLng, String) onLocationSelected;

  MapPickerScreen({required this.initialLocation, required this.onLocationSelected});

  @override
  _MapPickerScreenState createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  late GoogleMapController mapController;
  LatLng selectedLocation = LatLng(0, 0);
  String selectedAddress = "Searching...";

  @override
  void initState() {
    super.initState();
    selectedLocation = widget.initialLocation;
    _getAddress(selectedLocation);
  }

  void _getAddress(LatLng location) async {
    List<Placemark> placemarks = await placemarkFromCoordinates(
      location.latitude,
      location.longitude,
    );

    if (placemarks.isNotEmpty) {
      Placemark place = placemarks.first;
      setState(() {
        selectedAddress = "${place.name}, ${place.locality}";
      });
    }
  }

  void _onMapTap(LatLng newLocation) {
    setState(() {
      selectedLocation = newLocation;
      _getAddress(newLocation);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Select Location")),
      body: Column(
        children: [
          Expanded(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: widget.initialLocation,
                zoom: 15,
              ),
              onMapCreated: (GoogleMapController controller) {
                mapController = controller;
              },
              markers: {
                Marker(markerId: MarkerId("selected"), position: selectedLocation),
              },
              onTap: _onMapTap,
            ),
          ),
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Column(
              children: [
                Text(selectedAddress, style: TextStyle(fontSize: 16)),
                ElevatedButton(
                  onPressed: () {
                    widget.onLocationSelected(selectedLocation, selectedAddress);
                    Navigator.pop(context);
                  },
                  child: Text("Save Location"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
