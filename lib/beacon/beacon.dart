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
          proximity: _stringToProximity(json['proximity'] as String),
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
  static Proximity _stringToProximity(String proximity) {
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

  /// Parsing dynamic proximity into enum [Proximity].
  static String _proximityToString(Proximity proximity) {
    if (proximity == Proximity.unknown) {
      return 'unknown';
    }

    if (proximity == Proximity.immediate) {
      return 'immediate';
    }

    if (proximity == Proximity.near) {
      return 'near';
    }

    if (proximity == Proximity.far) {
      return 'far';
    }

    return null;
  }

  /// Parsing array of [Map] into [List] of [Beacon].
  static List<Beacon> beaconFromArray(
      dynamic beacons, List<String> macAddresses, List<Proximity> proximities) {
    if (beacons is List) {
      return beacons.map((json) {
        Proximity thisProximity;
        if (proximities.isNotEmpty) {
          if (json['proximity'] != null) {
            thisProximity = _stringToProximity(json['proximity'] as String);
          } else if (json['accuracy'] != null) {
            thisProximity = _accuracyToProximity(
                double.tryParse(json['accuracy'] as String));
          } else {
            thisProximity = Proximity.unknown;
          }
        }
        if ((macAddresses == null ||
                macAddresses.isEmpty ||
                macAddresses.contains(json['macAddress'] as String)) &&
            (proximities.isEmpty || proximities.contains(thisProximity)))
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
      'proximity': proximity.toString().split('.').last,
    };

    if (Platform.isAndroid) {
      map['txPower'] = txPower ?? -1;
      map['macAddress'] = macAddress ?? "";
    }

    return map;
  }

  /// - `accuracy == 0.0` : [Proximity.unknown]
  /// - `accuracy > 0 && accuracy <= 1.0` : [Proximity.immediate]
  /// - `accuracy > 1.0 && accuracy < 10.0` : [Proximity.near]
  /// - `accuracy > 10.0` : [Proximity.far]
  static Proximity _accuracyToProximity(double accuracy) {
    if (accuracy == null) {
      return Proximity.unknown;
    }

    if (accuracy == 0.0) {
      return Proximity.unknown;
    }

    if (accuracy <= 1.0) {
      return Proximity.immediate;
    }

    if (accuracy < 10.0) {
      return Proximity.near;
    }

    return Proximity.unknown;
  }

  /// Return [Proximity] of beacon.
  ///
  /// iOS will always set proximity by default, but Android is not
  /// so we manage it by filtering the accuracy like bellow :
  Proximity get proximity {
    if (_proximity != null) {
      return _proximity;
    }

    return _accuracyToProximity(accuracy);
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
