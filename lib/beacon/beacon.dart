//  Copyright (c) 2018 Eyro Labs.
//  Licensed under Apache License v2.0 that can be
//  found in the LICENSE file.

part of flutter_beacon;

/// Enum for defining proximity.
enum Proximity { unknown, immediate, near, far }

/// Class for managing Beacon object.
class Beacon {
  /// The type of beacon
  final String type;

  /// The proximity UUID of beacon (altbeacon/iBeacon).
  final String proximityUUID;

  /// The mac address of beacon.
  ///
  /// From iOS this value will be null
  final String macAddress;

  /// The major value of beacon (altbeacon/iBeacon).
  final int major;

  /// The minor value of beacon (altbeacon/iBeacon).
  final int minor;

  /// The namespaceId of the beacon (eddystone).
  final String namespaceId;

  /// The instanceId of the beacon (eddystone).
  final String instanceId;

  /// The rssi value of beacon.
  final int rssi;

  /// The transmission power of beacon.
  ///
  /// From iOS this value will be null
  final int txPower;

  /// The accuracy of distance of beacon in meter.
  final double accuracy;

  /// The proximity of beacon.
  final Proximity _proximity;

  /// Create beacon object.
  const Beacon({
    this.type,
    this.proximityUUID,
    this.macAddress,
    this.major,
    this.minor,
    this.namespaceId,
    this.instanceId,
    this.rssi,
    this.txPower,
    this.accuracy,
    Proximity proximity,
  }) : this._proximity = proximity;

  /// Create beacon object from json.
  Beacon.fromJson(dynamic json)
      : this(
          type: json['type'],
          proximityUUID: json['proximityUUID'],
          macAddress: json['macAddress'],
          major: json['major'],
          minor: json['minor'],
          namespaceId: json['namespaceId'],
          instanceId: json['instanceId'],
          rssi: _parseInt(json['rssi']),
          txPower: _parseInt(json['txPower']),
          accuracy: _parseDouble(json['accuracy']),
          proximity: _parseProximity(json['proximity']),
        );

  /// Parsing dynamic data into double.
  static double _parseDouble(dynamic data) {
    if (data is num) {
      return data;
    } else if (data is String) {
      return double.tryParse(data) ?? 0.0;
    }

    return 0.0;
  }

  /// Parsing dynamic data into integer.
  static int _parseInt(dynamic data) {
    if (data is num) {
      return data;
    } else if (data is String) {
      return int.tryParse(data) ?? 0;
    }

    return 0;
  }

  /// Parsing dynamic proximity into enum [Proximity].
  static dynamic _parseProximity(dynamic proximity) {
    if (proximity == 'unknown') {
      return Proximity.unknown;
    }

    if (proximity == 'immediate') {
      return Proximity.immediate;
    }

    if (proximity == 'near') {
      return Proximity.near;
    }

    if (proximity == 'far') {
      return Proximity.far;
    }

    return null;
  }

  /// Parsing array of [Map] into [List] of [Beacon].
  static List<Beacon> beaconFromArray(
      dynamic beacons, List<String> macAddresses, List<Proximity> proximities) {
    if (beacons is List) {
      List<String> _proximityList = <String>[];
      proximities.map((Proximity entry) => entry.toString).toList();
      return beacons.map((json) {
        if ((macAddresses == null ||
                macAddresses.isEmpty ||
                macAddresses.contains(json['macAddress'])) &&
            (_proximityList.isEmpty ||
                _proximityList.contains(_parseProximity(json['proximity']))))
          return Beacon.fromJson(json);
      }).toList();
    }

    return null;
  }

  /// Parsing [List] of [Beacon] into array of [Map].
  static dynamic beaconArrayToJson(List<Beacon> beacons) {
    return beacons.map((beacon) {
      return beacon.toJson;
    }).toList();
  }

  /// Serialize current instance object into [Map].
  dynamic get toJson {
    final map = <String, dynamic>{
      'type': type,
      'proximityUUID': proximityUUID,
      'major': major,
      'minor': minor,
      'namespaceId': namespaceId,
      'instanceId': instanceId,
      'rssi': rssi ?? -1,
      'accuracy': accuracy,
      'proximity': proximity.toString().split('.').last
    };

    if (Platform.isAndroid) {
      map['txPower'] = txPower ?? -1;
      map['macAddress'] = macAddress ?? "";
    }

    return map;
  }

  /// Return [Proximity] of beacon.
  ///
  /// iOS will always set proximity by default, but Android is not
  /// so we manage it by filtering the accuracy like bellow :
  /// - `accuracy == 0.0` : [Proximity.unknown]
  /// - `accuracy > 0 && accuracy <= 0.5` : [Proximity.immediate]
  /// - `accuracy > 0.5 && accuracy < 3.0` : [Proximity.near]
  /// - `accuracy > 3.0` : [Proximity.far]
  Proximity get proximity {
    if (_proximity != null) {
      return _proximity;
    }

    if (accuracy == 0.0) {
      return Proximity.unknown;
    }

    if (accuracy <= 0.5) {
      return Proximity.immediate;
    }

    if (accuracy < 3.0) {
      return Proximity.near;
    }

    return Proximity.far;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Beacon &&
          type == 'altbeacon' &&
          runtimeType == other.runtimeType &&
          proximityUUID == other.proximityUUID &&
          major == other.major &&
          minor == other.minor &&
          (Platform.isAndroid ? macAddress == other.macAddress : true) ||
      other is Beacon &&
          type == 'eddystone' &&
          runtimeType == other.runtimeType &&
          namespaceId == other.namespaceId &&
          instanceId == other.instanceId &&
          (Platform.isAndroid ? macAddress == other.macAddress : true);

  @override
  int get hashCode {
    int hashCode = -1;
    if (type == 'eddystone') {
      hashCode = namespaceId.hashCode ^ instanceId.hashCode;
    } else {
      hashCode = proximityUUID.hashCode ^ major.hashCode ^ minor.hashCode;
    }
    if (Platform.isAndroid) {
      hashCode = hashCode ^ macAddress.hashCode;
    }

    return hashCode;
  }

  @override
  String toString() {
    return json.encode(toJson);
  }
}
