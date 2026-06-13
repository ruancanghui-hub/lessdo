import 'package:flutter/material.dart';

enum ListKind { standard, grocery }

class TaskList {
  const TaskList({
    required this.id,
    required this.name,
    required this.colorValue,
    this.kind = ListKind.standard,
    this.sortOrder = 0,
  });

  final String id;
  final String name;
  final int colorValue;
  final ListKind kind;
  final int sortOrder;

  Color get color => Color(colorValue);

  TaskList copyWith({
    String? name,
    int? colorValue,
    ListKind? kind,
    int? sortOrder,
  }) {
    return TaskList(
      id: id,
      name: name ?? this.name,
      colorValue: colorValue ?? this.colorValue,
      kind: kind ?? this.kind,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'colorValue': colorValue,
    'kind': kind.name,
    'sortOrder': sortOrder,
  };

  factory TaskList.fromJson(Map<String, Object?> json) {
    return TaskList(
      id: json['id']! as String,
      name: json['name']! as String,
      colorValue: json['colorValue']! as int,
      kind: ListKind.values.byName(
        (json['kind'] as String?) ?? ListKind.standard.name,
      ),
      sortOrder: (json['sortOrder'] as int?) ?? 0,
    );
  }
}
