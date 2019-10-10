import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'location_stream_widget.dart';

class ShowMapsWidget extends StatefulWidget {
  final PositionStorage storage;

  const ShowMapsWidget({Key key, this.storage}) : super(key: key);

  @override
  _ShowMapsState createState() => _ShowMapsState();
}

class _ShowMapsState extends State<ShowMapsWidget> {
  GoogleMapController mapController;
  LatLng _center = const LatLng(30.768088, 76.786227);
  final Set<Marker> _markers = Set();
  List<FileSystemEntity> files = null;
  String _path = 'One';
  bool _filePicked = false;
  String _fileName = "Choose File";
  List<String> fileNames;

  _dropDownCallback() async {
    setState(() {
      _filePicked = true;
      _markers.clear();
      _fileName = _getFileName(_path);
    });

    try {
      markPlaces(); // Placing Markers on the Screen
    } catch (Exception) {
      print("Exception Occurred: " + Exception.toString());
    }
  }

  _removeFile() async {
    setState(() {
      _filePicked = false;
      _fileName = "Choose File";
      _path = "-";
      _markers.clear();
    });
    _shiftToCurrentPosition();
  }

  @override
  initState() {
    super.initState();
    _listOfFiles();
  }

  void _listOfFiles() async {
    final directory = await widget.storage.externalLocalPath;
    setState(() {
      files = Directory("$directory/").listSync();
      fileNames = files.map((file) => file.path).toList();
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    _shiftToCurrentPosition();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: <Widget>[
      GoogleMap(
        onMapCreated: _onMapCreated,
        markers: _markers,
        initialCameraPosition: CameraPosition(
          target: _center,
          zoom: 11.0,
        ),
      ),
      Positioned(
        top: 20,
        right: 15,
        left: 15,
        height: 60,
        child: Container(
          color: Colors.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              IconButton(
                splashColor: Colors.green,
                icon: Icon(_filePicked ? Icons.check : Icons.insert_drive_file),
                color: Colors.green,
                onPressed: () {},
              ),
              Text(_fileName),
              _filePicked == false
                  ? Padding(
                      padding: EdgeInsets.only(left: 5),
                      child: files == null
                          ? CircularProgressIndicator()
                          : _dropDownWidget(),
                    )
                  : Container(),
              _filePicked
                  ? IconButton(
                      icon: Icon(Icons.clear),
                      color: Colors.blueGrey,
                      tooltip: "Remove selected file",
                      onPressed: () => _removeFile(),
                    )
                  : Container(),
            ],
          ),
        ),
      ),
      _filePicked == false
          ? Padding(
              padding: const EdgeInsets.all(27.0),
              child: Align(
                alignment: Alignment.bottomRight,
                child: FloatingActionButton(
                  onPressed: () => _shiftToCurrentPosition(),
                  materialTapTargetSize: MaterialTapTargetSize.padded,
                  backgroundColor: Colors.blueAccent,
                  child: const Icon(Icons.my_location, size: 25.0),
                ),
              ),
            )
          : Container(),
    ]);
  }

  void _shiftToCurrentPosition() async {
    Position position = await currentLocation();
    double currentLatitude = position.latitude;
    double currentLongitude = position.longitude;

    mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          bearing: 270.0,
          target: LatLng(currentLatitude, currentLongitude),
          zoom: 17.0,
        ),
      ),
    );
    setState(() {
      _markers.clear();
      _markers.add(
        Marker(
            markerId: MarkerId('Current-Location'),
            position: LatLng(currentLatitude, currentLongitude),
            infoWindow: InfoWindow(
              title: 'Current Location',
              snippet: 'This shows your current location',
            )),
      );
    });
  }

  Future<Position> currentLocation() async {
    Position position = await Geolocator().getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation);
    return position;
  }

  Widget _dropDownWidget() {
    return DropdownButton<String>(
      iconSize: 24,
      elevation: 16,
      hint: Text("CSV Files"),
      style: TextStyle(color: Colors.green),
      onChanged: (String newValue) {
        setState(() {
          _path = newValue;
          _dropDownCallback();
        });
      },
      items: fileNames.map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(_getFileName(value)),
        );
      }).toList(),
    );
  }

  String _getFileName(String result) {
    final listSplit = result.split('/');
    return listSplit[listSplit.length - 1];
  }

  markPlaces() async {
    final file = File(_path);
    // Read the file
    String contents = await file.readAsString();

    List<String> listOfStrings = contents.split('\n');
    for (String string in listOfStrings) {
      List<String> latLong = string.split(',');
      print(latLong);
      if (latLong.length <= 1 || latLong[1] == 'Latitude')
        continue;
      else {
        setState(() {
          _markers.add(Marker(
            markerId: MarkerId("$string"),
            position:
                LatLng(double.parse(latLong[1]), double.parse(latLong[2])),
          ));
        });

        if (_markers.length >= 2)
          setState(() {
            mapController.animateCamera(CameraUpdate.newLatLngBounds(
                LatLngBounds(
                    southwest: _markers.elementAt(_markers.length - 1).position,
                    northeast: _markers.elementAt(0).position),
                100.0));
          });
      }
    }
  }
}
