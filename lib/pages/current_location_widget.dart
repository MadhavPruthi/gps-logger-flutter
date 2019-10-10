import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../common_widgets/placeholder_widget.dart';

class CurrentLocationWidget extends StatefulWidget {
  const CurrentLocationWidget({
    Key key,

    /// If set, enable the FusedLocationProvider on Android
    @required this.androidFusedLocation,
  }) : super(key: key);

  final bool androidFusedLocation;

  @override
  _LocationState createState() => _LocationState();
}

class _LocationState extends State<CurrentLocationWidget> {
  Position _currentPosition;

  @override
  void initState() {
    super.initState();

    _initCurrentLocation();
  }

  @override
  void didUpdateWidget(Widget oldWidget) {
    super.didUpdateWidget(oldWidget);

    setState(() {
      _currentPosition = null;
    });

    _initCurrentLocation();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  _initCurrentLocation() {
    Geolocator()
      ..forceAndroidLocationManager = !widget.androidFusedLocation
      ..getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      ).then((position) {
        if (mounted) {
          setState(() => _currentPosition = position);
        }
      }).catchError((e) {
        //
      });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<GeolocationStatus>(
        future: Geolocator().checkGeolocationPermissionStatus(),
        builder:
            (BuildContext context, AsyncSnapshot<GeolocationStatus> snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data == GeolocationStatus.denied) {
            return const PlaceholderWidget('Access to location denied',
                'Allow access to the location services for this App');
          }

          return Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  child: Text(
                    _fusedLocationNote(),
                    style: TextStyle(
                      fontSize: 30.0,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
//                PlaceholderWidget(
//                    'Last known location:', _lastKnownPosition.toString()),
                _currentPosition == null
                    ? CircularProgressIndicator()
                    : PlaceholderWidget(
                        'Current location:', _currentPosition.toString()),
                Container(
                  height: 10,
                ),
                _currentPosition == null
                    ? CircularProgressIndicator()
                    : PlaceholderWidget(
                        'Speed:',
                        _currentPosition.speed.toString(),
                      )
              ],
            ),
          );
        });
  }

  String _fusedLocationNote() {
    return 'Coordinates';
  }
}
