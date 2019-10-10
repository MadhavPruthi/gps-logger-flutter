import 'dart:io';

import 'package:flutter/material.dart';

import 'pages/current_location_widget.dart';
import 'pages/location_stream_widget.dart';
import 'pages/show_maps_widget.dart';

void main() => runApp(GeoLogger(
      storage: PositionStorage(),
    ));

enum TabItem {
  singleLocation,
  singleFusedLocation,
  locationStream,
  ViewMap,
}

class GeoLogger extends StatefulWidget {
  final PositionStorage storage;

  const GeoLogger({Key key, this.storage}) : super(key: key);

  @override
  State<GeoLogger> createState() => BottomNavigationState();
}

class BottomNavigationState extends State<GeoLogger> {
  TabItem _currentItem = TabItem.singleLocation;
  final List<TabItem> _bottomTabs = [
    TabItem.singleLocation,
    TabItem.locationStream,
    TabItem.ViewMap,
  ];

  @override
  void initState() {
    super.initState();
    widget.storage.writePosition(
        "Timestamp", "Latitude", "Longitude", "Speed", FileMode.write);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: Text('Geologger'),
        ),
        body: _buildBody(),
        bottomNavigationBar: _buildBottomNavigationBar(),
      ),
    );
  }

  Widget _buildBody() {
    switch (_currentItem) {
      case TabItem.locationStream:
        return LocationStreamWidget(
          storage: PositionStorage(),
        );
      case TabItem.singleLocation:
        return CurrentLocationWidget(androidFusedLocation: false);
      case TabItem.ViewMap:
        return ShowMapsWidget(
          storage: PositionStorage(),
        );
      default:
        throw 'Unknown $_currentItem';
    }
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      items: _bottomTabs
          .map((tabItem) =>
              _buildBottomNavigationBarItem(_icon(tabItem), tabItem))
          .toList(),
      onTap: _onSelectTab,
    );
  }

  BottomNavigationBarItem _buildBottomNavigationBarItem(
      IconData icon, TabItem tabItem) {
    final String text = _title(tabItem);
    final Color color =
        _currentItem == tabItem ? Theme.of(context).primaryColor : Colors.grey;

    return BottomNavigationBarItem(
      icon: Icon(
        icon,
        color: color,
      ),
      title: Text(
        text,
        style: TextStyle(
          color: color,
        ),
      ),
    );
  }

  void _onSelectTab(int index) {
    TabItem selectedTabItem = _bottomTabs[index];

    setState(() {
      _currentItem = selectedTabItem;
    });
  }

  String _title(TabItem item) {
    switch (item) {
      case TabItem.singleLocation:
        return 'Live Location';
      case TabItem.singleFusedLocation:
        return 'Single (Fused)';
      case TabItem.locationStream:
        return 'Record Location';
      case TabItem.ViewMap:
        return 'View Map';
      default:
        throw 'Unknown: $item';
    }
  }

  IconData _icon(TabItem item) {
    switch (item) {
      case TabItem.singleLocation:
        return Icons.location_on;
      case TabItem.singleFusedLocation:
        return Icons.location_on;
      case TabItem.locationStream:
        return Icons.clear_all;
      case TabItem.ViewMap:
        return Icons.map;
      default:
        throw 'Unknown: $item';
    }
  }
}
