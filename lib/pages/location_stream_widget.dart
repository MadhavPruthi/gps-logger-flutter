import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path_provider/path_provider.dart';

import '../common_widgets/placeholder_widget.dart';

class LocationStreamWidget extends StatefulWidget {
  final PositionStorage storage;

  const LocationStreamWidget({Key key, this.storage}) : super(key: key);

  @override
  State<LocationStreamWidget> createState() => LocationStreamState();
}

class PositionStorage {
  Future<String> get externalLocalPath async {
    final directory = await getExternalStorageDirectory();
    return directory.path;
  }

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await externalLocalPath;
    return File('$path/loggerfile.csv');
  }

  Future<File> writePosition(String timestamp, String latitude,
      String longitude, String speed, FileMode fileMode) async {
    final file = await _localFile;
    return file.writeAsString('$timestamp,$latitude,$longitude,$speed\n',
        mode: fileMode);
  }

  Future<File> writeCounter(int counter) async {
    final location = await _localPath;
    final file = File('$location/counter.txt');
    // Write the file
    return file.writeAsString('$counter');
  }

  Future<int> readCounter() async {
    try {
      final location = await _localPath;

      final file = File('$location/counter.txt');
      // Read the file
      String contents = await file.readAsString();

      return int.parse(contents);
    } catch (e) {
      // If encountering an error, return 0
      return 0;
    }
  }
}

class LocationStreamState extends State<LocationStreamWidget> {
  StreamSubscription<Position> _positionStreamSubscription;
  final List<Position> _positions = <Position>[];

  void _toggleListening() {
    if (_positionStreamSubscription == null) {
      const LocationOptions locationOptions =
          LocationOptions(accuracy: LocationAccuracy.best, distanceFilter: 10);
      final Stream<Position> positionStream =
          Geolocator().getPositionStream(locationOptions);
      _positionStreamSubscription =
          positionStream.listen((Position position) => setState(() {
                _positions.add(position);
                widget.storage.writePosition(
                    position.timestamp.toString(),
                    position.latitude.toString(),
                    position.longitude.toString(),
                    position.speed.toString(),
                    FileMode.append);
              }));
      _positionStreamSubscription.pause();
    }

    setState(() {
      if (_positionStreamSubscription.isPaused) {
        _positionStreamSubscription.resume();
      } else {
        _positionStreamSubscription.pause();
      }
    });
  }

  @override
  void dispose() {
    if (_positionStreamSubscription != null) {
      _positionStreamSubscription.cancel();
      _positionStreamSubscription = null;
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<GeolocationStatus>(
        future: Geolocator().checkGeolocationPermissionStatus(),
        builder:
            (BuildContext context, AsyncSnapshot<GeolocationStatus> snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.data == GeolocationStatus.denied) {
            return PlaceholderWidget('Location services disabled',
                'Enable location services for this App using the device settings.');
          }

          return _buildListView();
        });
  }

  Widget _buildListView() {
    final List<Widget> listItems = <Widget>[
      ListTile(
        title: RaisedButton(
          child: _buildButtonText(),
          color: _determineButtonColor(),
          padding: const EdgeInsets.all(8.0),
          onPressed: _toggleListening,
        ),
      ),
    ];

    listItems.addAll(_positions
        .map((Position position) => PositionListItem(position))
        .toList());

    return ListView(
      children: listItems,
    );
  }

  bool _isListening() => !(_positionStreamSubscription == null ||
      _positionStreamSubscription.isPaused);

  Widget _buildButtonText() {
    return Text(_isListening() ? 'Stop listening' : 'Start listening');
  }

  Color _determineButtonColor() {
    return _isListening() ? Colors.red : Colors.green;
  }
}

class PositionListItem extends StatefulWidget {
  const PositionListItem(this._position);

  final Position _position;

  @override
  State<PositionListItem> createState() => PositionListItemState(_position);
}

class PositionListItemState extends State<PositionListItem> {
  PositionListItemState(this._position);

  final Position _position;
  String _address = '';

  @override
  Widget build(BuildContext context) {
    final Row row = Row(
      children: <Widget>[
        Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Text(
                'Lat: ${_position.latitude}',
                style: const TextStyle(fontSize: 16.0, color: Colors.black),
              ),
              Text(
                'Lon: ${_position.longitude}',
                style: const TextStyle(fontSize: 16.0, color: Colors.black),
              ),
            ]),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Text(
                  _position.timestamp.toLocal().toString(),
                  style: const TextStyle(fontSize: 14.0, color: Colors.grey),
                )
              ]),
        ),
      ],
    );

    return ListTile(
      onTap: _onTap,
      title: row,
      subtitle: Text(_address),
    );
  }

  Future<void> _onTap() async {
    String address = 'unknown';
    final List<Placemark> placemarks = await Geolocator()
        .placemarkFromCoordinates(_position.latitude, _position.longitude);

    if (placemarks != null && placemarks.isNotEmpty) {
      address = _buildAddressString(placemarks.first);
    }

    setState(() {
      _address = '$address';
    });
  }

  static String _buildAddressString(Placemark placemark) {
    final String name = placemark.name ?? '';
    final String city = placemark.locality ?? '';
    final String state = placemark.administrativeArea ?? '';
    final String country = placemark.country ?? '';

    return '$name, $city, $state, $country';
  }
}
