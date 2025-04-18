import 'package:cloud_firestore/cloud_firestore.dart';

class WeightEntry {
  final String? id; // Firestore document ID
  final double weight; // kg
  final Timestamp timestamp;

  WeightEntry({this.id, required this.weight, required this.timestamp});

  factory WeightEntry.fromSnapshot(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return WeightEntry(
      id: doc.id,
      weight: (data['weight'] ?? 0.0).toDouble(),
      timestamp: data['timestamp'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'weight': weight, 'timestamp': timestamp};
  }
}
