// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $HabitsTable extends Habits with TableInfo<$HabitsTable, HabitRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HabitsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _iconKeyMeta = const VerificationMeta(
    'iconKey',
  );
  @override
  late final GeneratedColumn<String> iconKey = GeneratedColumn<String>(
    'icon_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scheduleTypeMeta = const VerificationMeta(
    'scheduleType',
  );
  @override
  late final GeneratedColumn<int> scheduleType = GeneratedColumn<int>(
    'schedule_type',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _scheduleValueMeta = const VerificationMeta(
    'scheduleValue',
  );
  @override
  late final GeneratedColumn<int> scheduleValue = GeneratedColumn<int>(
    'schedule_value',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _weekdaysMaskMeta = const VerificationMeta(
    'weekdaysMask',
  );
  @override
  late final GeneratedColumn<int> weekdaysMask = GeneratedColumn<int>(
    'weekdays_mask',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(127),
  );
  static const VerificationMeta _goalDaysMeta = const VerificationMeta(
    'goalDays',
  );
  @override
  late final GeneratedColumn<int> goalDays = GeneratedColumn<int>(
    'goal_days',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _startDateMeta = const VerificationMeta(
    'startDate',
  );
  @override
  late final GeneratedColumn<String> startDate = GeneratedColumn<String>(
    'start_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mottoMeta = const VerificationMeta('motto');
  @override
  late final GeneratedColumn<String> motto = GeneratedColumn<String>(
    'motto',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _enableScoreMeta = const VerificationMeta(
    'enableScore',
  );
  @override
  late final GeneratedColumn<bool> enableScore = GeneratedColumn<bool>(
    'enable_score',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("enable_score" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _enableMoodMeta = const VerificationMeta(
    'enableMood',
  );
  @override
  late final GeneratedColumn<bool> enableMood = GeneratedColumn<bool>(
    'enable_mood',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("enable_mood" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _dailyTargetMeta = const VerificationMeta(
    'dailyTarget',
  );
  @override
  late final GeneratedColumn<int> dailyTarget = GeneratedColumn<int>(
    'daily_target',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    iconKey,
    scheduleType,
    scheduleValue,
    weekdaysMask,
    goalDays,
    startDate,
    motto,
    enableScore,
    enableMood,
    dailyTarget,
    isActive,
    sortOrder,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'habits';
  @override
  VerificationContext validateIntegrity(
    Insertable<HabitRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('icon_key')) {
      context.handle(
        _iconKeyMeta,
        iconKey.isAcceptableOrUnknown(data['icon_key']!, _iconKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_iconKeyMeta);
    }
    if (data.containsKey('schedule_type')) {
      context.handle(
        _scheduleTypeMeta,
        scheduleType.isAcceptableOrUnknown(
          data['schedule_type']!,
          _scheduleTypeMeta,
        ),
      );
    }
    if (data.containsKey('schedule_value')) {
      context.handle(
        _scheduleValueMeta,
        scheduleValue.isAcceptableOrUnknown(
          data['schedule_value']!,
          _scheduleValueMeta,
        ),
      );
    }
    if (data.containsKey('weekdays_mask')) {
      context.handle(
        _weekdaysMaskMeta,
        weekdaysMask.isAcceptableOrUnknown(
          data['weekdays_mask']!,
          _weekdaysMaskMeta,
        ),
      );
    }
    if (data.containsKey('goal_days')) {
      context.handle(
        _goalDaysMeta,
        goalDays.isAcceptableOrUnknown(data['goal_days']!, _goalDaysMeta),
      );
    }
    if (data.containsKey('start_date')) {
      context.handle(
        _startDateMeta,
        startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta),
      );
    } else if (isInserting) {
      context.missing(_startDateMeta);
    }
    if (data.containsKey('motto')) {
      context.handle(
        _mottoMeta,
        motto.isAcceptableOrUnknown(data['motto']!, _mottoMeta),
      );
    }
    if (data.containsKey('enable_score')) {
      context.handle(
        _enableScoreMeta,
        enableScore.isAcceptableOrUnknown(
          data['enable_score']!,
          _enableScoreMeta,
        ),
      );
    }
    if (data.containsKey('enable_mood')) {
      context.handle(
        _enableMoodMeta,
        enableMood.isAcceptableOrUnknown(data['enable_mood']!, _enableMoodMeta),
      );
    }
    if (data.containsKey('daily_target')) {
      context.handle(
        _dailyTargetMeta,
        dailyTarget.isAcceptableOrUnknown(
          data['daily_target']!,
          _dailyTargetMeta,
        ),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  HabitRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HabitRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      iconKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon_key'],
      )!,
      scheduleType: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}schedule_type'],
      )!,
      scheduleValue: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}schedule_value'],
      )!,
      weekdaysMask: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}weekdays_mask'],
      )!,
      goalDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}goal_days'],
      ),
      startDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}start_date'],
      )!,
      motto: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}motto'],
      )!,
      enableScore: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}enable_score'],
      )!,
      enableMood: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}enable_mood'],
      )!,
      dailyTarget: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}daily_target'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $HabitsTable createAlias(String alias) {
    return $HabitsTable(attachedDatabase, alias);
  }
}

class HabitRow extends DataClass implements Insertable<HabitRow> {
  final int id;
  final String name;
  final String iconKey;
  final int scheduleType;
  final int scheduleValue;
  final int weekdaysMask;
  final int? goalDays;
  final String startDate;
  final String motto;
  final bool enableScore;
  final bool enableMood;
  final int dailyTarget;
  final bool isActive;
  final int sortOrder;
  final int createdAt;
  const HabitRow({
    required this.id,
    required this.name,
    required this.iconKey,
    required this.scheduleType,
    required this.scheduleValue,
    required this.weekdaysMask,
    this.goalDays,
    required this.startDate,
    required this.motto,
    required this.enableScore,
    required this.enableMood,
    required this.dailyTarget,
    required this.isActive,
    required this.sortOrder,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['icon_key'] = Variable<String>(iconKey);
    map['schedule_type'] = Variable<int>(scheduleType);
    map['schedule_value'] = Variable<int>(scheduleValue);
    map['weekdays_mask'] = Variable<int>(weekdaysMask);
    if (!nullToAbsent || goalDays != null) {
      map['goal_days'] = Variable<int>(goalDays);
    }
    map['start_date'] = Variable<String>(startDate);
    map['motto'] = Variable<String>(motto);
    map['enable_score'] = Variable<bool>(enableScore);
    map['enable_mood'] = Variable<bool>(enableMood);
    map['daily_target'] = Variable<int>(dailyTarget);
    map['is_active'] = Variable<bool>(isActive);
    map['sort_order'] = Variable<int>(sortOrder);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  HabitsCompanion toCompanion(bool nullToAbsent) {
    return HabitsCompanion(
      id: Value(id),
      name: Value(name),
      iconKey: Value(iconKey),
      scheduleType: Value(scheduleType),
      scheduleValue: Value(scheduleValue),
      weekdaysMask: Value(weekdaysMask),
      goalDays: goalDays == null && nullToAbsent
          ? const Value.absent()
          : Value(goalDays),
      startDate: Value(startDate),
      motto: Value(motto),
      enableScore: Value(enableScore),
      enableMood: Value(enableMood),
      dailyTarget: Value(dailyTarget),
      isActive: Value(isActive),
      sortOrder: Value(sortOrder),
      createdAt: Value(createdAt),
    );
  }

  factory HabitRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HabitRow(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      iconKey: serializer.fromJson<String>(json['iconKey']),
      scheduleType: serializer.fromJson<int>(json['scheduleType']),
      scheduleValue: serializer.fromJson<int>(json['scheduleValue']),
      weekdaysMask: serializer.fromJson<int>(json['weekdaysMask']),
      goalDays: serializer.fromJson<int?>(json['goalDays']),
      startDate: serializer.fromJson<String>(json['startDate']),
      motto: serializer.fromJson<String>(json['motto']),
      enableScore: serializer.fromJson<bool>(json['enableScore']),
      enableMood: serializer.fromJson<bool>(json['enableMood']),
      dailyTarget: serializer.fromJson<int>(json['dailyTarget']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'iconKey': serializer.toJson<String>(iconKey),
      'scheduleType': serializer.toJson<int>(scheduleType),
      'scheduleValue': serializer.toJson<int>(scheduleValue),
      'weekdaysMask': serializer.toJson<int>(weekdaysMask),
      'goalDays': serializer.toJson<int?>(goalDays),
      'startDate': serializer.toJson<String>(startDate),
      'motto': serializer.toJson<String>(motto),
      'enableScore': serializer.toJson<bool>(enableScore),
      'enableMood': serializer.toJson<bool>(enableMood),
      'dailyTarget': serializer.toJson<int>(dailyTarget),
      'isActive': serializer.toJson<bool>(isActive),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  HabitRow copyWith({
    int? id,
    String? name,
    String? iconKey,
    int? scheduleType,
    int? scheduleValue,
    int? weekdaysMask,
    Value<int?> goalDays = const Value.absent(),
    String? startDate,
    String? motto,
    bool? enableScore,
    bool? enableMood,
    int? dailyTarget,
    bool? isActive,
    int? sortOrder,
    int? createdAt,
  }) => HabitRow(
    id: id ?? this.id,
    name: name ?? this.name,
    iconKey: iconKey ?? this.iconKey,
    scheduleType: scheduleType ?? this.scheduleType,
    scheduleValue: scheduleValue ?? this.scheduleValue,
    weekdaysMask: weekdaysMask ?? this.weekdaysMask,
    goalDays: goalDays.present ? goalDays.value : this.goalDays,
    startDate: startDate ?? this.startDate,
    motto: motto ?? this.motto,
    enableScore: enableScore ?? this.enableScore,
    enableMood: enableMood ?? this.enableMood,
    dailyTarget: dailyTarget ?? this.dailyTarget,
    isActive: isActive ?? this.isActive,
    sortOrder: sortOrder ?? this.sortOrder,
    createdAt: createdAt ?? this.createdAt,
  );
  HabitRow copyWithCompanion(HabitsCompanion data) {
    return HabitRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      iconKey: data.iconKey.present ? data.iconKey.value : this.iconKey,
      scheduleType: data.scheduleType.present
          ? data.scheduleType.value
          : this.scheduleType,
      scheduleValue: data.scheduleValue.present
          ? data.scheduleValue.value
          : this.scheduleValue,
      weekdaysMask: data.weekdaysMask.present
          ? data.weekdaysMask.value
          : this.weekdaysMask,
      goalDays: data.goalDays.present ? data.goalDays.value : this.goalDays,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      motto: data.motto.present ? data.motto.value : this.motto,
      enableScore: data.enableScore.present
          ? data.enableScore.value
          : this.enableScore,
      enableMood: data.enableMood.present
          ? data.enableMood.value
          : this.enableMood,
      dailyTarget: data.dailyTarget.present
          ? data.dailyTarget.value
          : this.dailyTarget,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HabitRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('iconKey: $iconKey, ')
          ..write('scheduleType: $scheduleType, ')
          ..write('scheduleValue: $scheduleValue, ')
          ..write('weekdaysMask: $weekdaysMask, ')
          ..write('goalDays: $goalDays, ')
          ..write('startDate: $startDate, ')
          ..write('motto: $motto, ')
          ..write('enableScore: $enableScore, ')
          ..write('enableMood: $enableMood, ')
          ..write('dailyTarget: $dailyTarget, ')
          ..write('isActive: $isActive, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    iconKey,
    scheduleType,
    scheduleValue,
    weekdaysMask,
    goalDays,
    startDate,
    motto,
    enableScore,
    enableMood,
    dailyTarget,
    isActive,
    sortOrder,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HabitRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.iconKey == this.iconKey &&
          other.scheduleType == this.scheduleType &&
          other.scheduleValue == this.scheduleValue &&
          other.weekdaysMask == this.weekdaysMask &&
          other.goalDays == this.goalDays &&
          other.startDate == this.startDate &&
          other.motto == this.motto &&
          other.enableScore == this.enableScore &&
          other.enableMood == this.enableMood &&
          other.dailyTarget == this.dailyTarget &&
          other.isActive == this.isActive &&
          other.sortOrder == this.sortOrder &&
          other.createdAt == this.createdAt);
}

class HabitsCompanion extends UpdateCompanion<HabitRow> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> iconKey;
  final Value<int> scheduleType;
  final Value<int> scheduleValue;
  final Value<int> weekdaysMask;
  final Value<int?> goalDays;
  final Value<String> startDate;
  final Value<String> motto;
  final Value<bool> enableScore;
  final Value<bool> enableMood;
  final Value<int> dailyTarget;
  final Value<bool> isActive;
  final Value<int> sortOrder;
  final Value<int> createdAt;
  const HabitsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.iconKey = const Value.absent(),
    this.scheduleType = const Value.absent(),
    this.scheduleValue = const Value.absent(),
    this.weekdaysMask = const Value.absent(),
    this.goalDays = const Value.absent(),
    this.startDate = const Value.absent(),
    this.motto = const Value.absent(),
    this.enableScore = const Value.absent(),
    this.enableMood = const Value.absent(),
    this.dailyTarget = const Value.absent(),
    this.isActive = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  HabitsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String iconKey,
    this.scheduleType = const Value.absent(),
    this.scheduleValue = const Value.absent(),
    this.weekdaysMask = const Value.absent(),
    this.goalDays = const Value.absent(),
    required String startDate,
    this.motto = const Value.absent(),
    this.enableScore = const Value.absent(),
    this.enableMood = const Value.absent(),
    this.dailyTarget = const Value.absent(),
    this.isActive = const Value.absent(),
    this.sortOrder = const Value.absent(),
    required int createdAt,
  }) : name = Value(name),
       iconKey = Value(iconKey),
       startDate = Value(startDate),
       createdAt = Value(createdAt);
  static Insertable<HabitRow> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? iconKey,
    Expression<int>? scheduleType,
    Expression<int>? scheduleValue,
    Expression<int>? weekdaysMask,
    Expression<int>? goalDays,
    Expression<String>? startDate,
    Expression<String>? motto,
    Expression<bool>? enableScore,
    Expression<bool>? enableMood,
    Expression<int>? dailyTarget,
    Expression<bool>? isActive,
    Expression<int>? sortOrder,
    Expression<int>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (iconKey != null) 'icon_key': iconKey,
      if (scheduleType != null) 'schedule_type': scheduleType,
      if (scheduleValue != null) 'schedule_value': scheduleValue,
      if (weekdaysMask != null) 'weekdays_mask': weekdaysMask,
      if (goalDays != null) 'goal_days': goalDays,
      if (startDate != null) 'start_date': startDate,
      if (motto != null) 'motto': motto,
      if (enableScore != null) 'enable_score': enableScore,
      if (enableMood != null) 'enable_mood': enableMood,
      if (dailyTarget != null) 'daily_target': dailyTarget,
      if (isActive != null) 'is_active': isActive,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  HabitsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? iconKey,
    Value<int>? scheduleType,
    Value<int>? scheduleValue,
    Value<int>? weekdaysMask,
    Value<int?>? goalDays,
    Value<String>? startDate,
    Value<String>? motto,
    Value<bool>? enableScore,
    Value<bool>? enableMood,
    Value<int>? dailyTarget,
    Value<bool>? isActive,
    Value<int>? sortOrder,
    Value<int>? createdAt,
  }) {
    return HabitsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      iconKey: iconKey ?? this.iconKey,
      scheduleType: scheduleType ?? this.scheduleType,
      scheduleValue: scheduleValue ?? this.scheduleValue,
      weekdaysMask: weekdaysMask ?? this.weekdaysMask,
      goalDays: goalDays ?? this.goalDays,
      startDate: startDate ?? this.startDate,
      motto: motto ?? this.motto,
      enableScore: enableScore ?? this.enableScore,
      enableMood: enableMood ?? this.enableMood,
      dailyTarget: dailyTarget ?? this.dailyTarget,
      isActive: isActive ?? this.isActive,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (iconKey.present) {
      map['icon_key'] = Variable<String>(iconKey.value);
    }
    if (scheduleType.present) {
      map['schedule_type'] = Variable<int>(scheduleType.value);
    }
    if (scheduleValue.present) {
      map['schedule_value'] = Variable<int>(scheduleValue.value);
    }
    if (weekdaysMask.present) {
      map['weekdays_mask'] = Variable<int>(weekdaysMask.value);
    }
    if (goalDays.present) {
      map['goal_days'] = Variable<int>(goalDays.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<String>(startDate.value);
    }
    if (motto.present) {
      map['motto'] = Variable<String>(motto.value);
    }
    if (enableScore.present) {
      map['enable_score'] = Variable<bool>(enableScore.value);
    }
    if (enableMood.present) {
      map['enable_mood'] = Variable<bool>(enableMood.value);
    }
    if (dailyTarget.present) {
      map['daily_target'] = Variable<int>(dailyTarget.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HabitsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('iconKey: $iconKey, ')
          ..write('scheduleType: $scheduleType, ')
          ..write('scheduleValue: $scheduleValue, ')
          ..write('weekdaysMask: $weekdaysMask, ')
          ..write('goalDays: $goalDays, ')
          ..write('startDate: $startDate, ')
          ..write('motto: $motto, ')
          ..write('enableScore: $enableScore, ')
          ..write('enableMood: $enableMood, ')
          ..write('dailyTarget: $dailyTarget, ')
          ..write('isActive: $isActive, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $CheckInsTable extends CheckIns
    with TableInfo<$CheckInsTable, CheckInRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CheckInsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _habitIdMeta = const VerificationMeta(
    'habitId',
  );
  @override
  late final GeneratedColumn<int> habitId = GeneratedColumn<int>(
    'habit_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES habits (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _doneCountMeta = const VerificationMeta(
    'doneCount',
  );
  @override
  late final GeneratedColumn<int> doneCount = GeneratedColumn<int>(
    'count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _scoreMeta = const VerificationMeta('score');
  @override
  late final GeneratedColumn<int> score = GeneratedColumn<int>(
    'score',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _moodMeta = const VerificationMeta('mood');
  @override
  late final GeneratedColumn<int> mood = GeneratedColumn<int>(
    'mood',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    habitId,
    date,
    doneCount,
    score,
    mood,
    note,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'check_ins';
  @override
  VerificationContext validateIntegrity(
    Insertable<CheckInRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('habit_id')) {
      context.handle(
        _habitIdMeta,
        habitId.isAcceptableOrUnknown(data['habit_id']!, _habitIdMeta),
      );
    } else if (isInserting) {
      context.missing(_habitIdMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('count')) {
      context.handle(
        _doneCountMeta,
        doneCount.isAcceptableOrUnknown(data['count']!, _doneCountMeta),
      );
    }
    if (data.containsKey('score')) {
      context.handle(
        _scoreMeta,
        score.isAcceptableOrUnknown(data['score']!, _scoreMeta),
      );
    }
    if (data.containsKey('mood')) {
      context.handle(
        _moodMeta,
        mood.isAcceptableOrUnknown(data['mood']!, _moodMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {habitId, date},
  ];
  @override
  CheckInRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CheckInRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      habitId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}habit_id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      doneCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}count'],
      )!,
      score: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}score'],
      ),
      mood: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}mood'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $CheckInsTable createAlias(String alias) {
    return $CheckInsTable(attachedDatabase, alias);
  }
}

class CheckInRow extends DataClass implements Insertable<CheckInRow> {
  final int id;
  final int habitId;
  final String date;
  final int doneCount;
  final int? score;
  final int? mood;
  final String? note;
  final int updatedAt;
  const CheckInRow({
    required this.id,
    required this.habitId,
    required this.date,
    required this.doneCount,
    this.score,
    this.mood,
    this.note,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['habit_id'] = Variable<int>(habitId);
    map['date'] = Variable<String>(date);
    map['count'] = Variable<int>(doneCount);
    if (!nullToAbsent || score != null) {
      map['score'] = Variable<int>(score);
    }
    if (!nullToAbsent || mood != null) {
      map['mood'] = Variable<int>(mood);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  CheckInsCompanion toCompanion(bool nullToAbsent) {
    return CheckInsCompanion(
      id: Value(id),
      habitId: Value(habitId),
      date: Value(date),
      doneCount: Value(doneCount),
      score: score == null && nullToAbsent
          ? const Value.absent()
          : Value(score),
      mood: mood == null && nullToAbsent ? const Value.absent() : Value(mood),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      updatedAt: Value(updatedAt),
    );
  }

  factory CheckInRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CheckInRow(
      id: serializer.fromJson<int>(json['id']),
      habitId: serializer.fromJson<int>(json['habitId']),
      date: serializer.fromJson<String>(json['date']),
      doneCount: serializer.fromJson<int>(json['doneCount']),
      score: serializer.fromJson<int?>(json['score']),
      mood: serializer.fromJson<int?>(json['mood']),
      note: serializer.fromJson<String?>(json['note']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'habitId': serializer.toJson<int>(habitId),
      'date': serializer.toJson<String>(date),
      'doneCount': serializer.toJson<int>(doneCount),
      'score': serializer.toJson<int?>(score),
      'mood': serializer.toJson<int?>(mood),
      'note': serializer.toJson<String?>(note),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  CheckInRow copyWith({
    int? id,
    int? habitId,
    String? date,
    int? doneCount,
    Value<int?> score = const Value.absent(),
    Value<int?> mood = const Value.absent(),
    Value<String?> note = const Value.absent(),
    int? updatedAt,
  }) => CheckInRow(
    id: id ?? this.id,
    habitId: habitId ?? this.habitId,
    date: date ?? this.date,
    doneCount: doneCount ?? this.doneCount,
    score: score.present ? score.value : this.score,
    mood: mood.present ? mood.value : this.mood,
    note: note.present ? note.value : this.note,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  CheckInRow copyWithCompanion(CheckInsCompanion data) {
    return CheckInRow(
      id: data.id.present ? data.id.value : this.id,
      habitId: data.habitId.present ? data.habitId.value : this.habitId,
      date: data.date.present ? data.date.value : this.date,
      doneCount: data.doneCount.present ? data.doneCount.value : this.doneCount,
      score: data.score.present ? data.score.value : this.score,
      mood: data.mood.present ? data.mood.value : this.mood,
      note: data.note.present ? data.note.value : this.note,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CheckInRow(')
          ..write('id: $id, ')
          ..write('habitId: $habitId, ')
          ..write('date: $date, ')
          ..write('doneCount: $doneCount, ')
          ..write('score: $score, ')
          ..write('mood: $mood, ')
          ..write('note: $note, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, habitId, date, doneCount, score, mood, note, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CheckInRow &&
          other.id == this.id &&
          other.habitId == this.habitId &&
          other.date == this.date &&
          other.doneCount == this.doneCount &&
          other.score == this.score &&
          other.mood == this.mood &&
          other.note == this.note &&
          other.updatedAt == this.updatedAt);
}

class CheckInsCompanion extends UpdateCompanion<CheckInRow> {
  final Value<int> id;
  final Value<int> habitId;
  final Value<String> date;
  final Value<int> doneCount;
  final Value<int?> score;
  final Value<int?> mood;
  final Value<String?> note;
  final Value<int> updatedAt;
  const CheckInsCompanion({
    this.id = const Value.absent(),
    this.habitId = const Value.absent(),
    this.date = const Value.absent(),
    this.doneCount = const Value.absent(),
    this.score = const Value.absent(),
    this.mood = const Value.absent(),
    this.note = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  CheckInsCompanion.insert({
    this.id = const Value.absent(),
    required int habitId,
    required String date,
    this.doneCount = const Value.absent(),
    this.score = const Value.absent(),
    this.mood = const Value.absent(),
    this.note = const Value.absent(),
    required int updatedAt,
  }) : habitId = Value(habitId),
       date = Value(date),
       updatedAt = Value(updatedAt);
  static Insertable<CheckInRow> custom({
    Expression<int>? id,
    Expression<int>? habitId,
    Expression<String>? date,
    Expression<int>? doneCount,
    Expression<int>? score,
    Expression<int>? mood,
    Expression<String>? note,
    Expression<int>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (habitId != null) 'habit_id': habitId,
      if (date != null) 'date': date,
      if (doneCount != null) 'count': doneCount,
      if (score != null) 'score': score,
      if (mood != null) 'mood': mood,
      if (note != null) 'note': note,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  CheckInsCompanion copyWith({
    Value<int>? id,
    Value<int>? habitId,
    Value<String>? date,
    Value<int>? doneCount,
    Value<int?>? score,
    Value<int?>? mood,
    Value<String?>? note,
    Value<int>? updatedAt,
  }) {
    return CheckInsCompanion(
      id: id ?? this.id,
      habitId: habitId ?? this.habitId,
      date: date ?? this.date,
      doneCount: doneCount ?? this.doneCount,
      score: score ?? this.score,
      mood: mood ?? this.mood,
      note: note ?? this.note,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (habitId.present) {
      map['habit_id'] = Variable<int>(habitId.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (doneCount.present) {
      map['count'] = Variable<int>(doneCount.value);
    }
    if (score.present) {
      map['score'] = Variable<int>(score.value);
    }
    if (mood.present) {
      map['mood'] = Variable<int>(mood.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CheckInsCompanion(')
          ..write('id: $id, ')
          ..write('habitId: $habitId, ')
          ..write('date: $date, ')
          ..write('doneCount: $doneCount, ')
          ..write('score: $score, ')
          ..write('mood: $mood, ')
          ..write('note: $note, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $RemindersTable extends Reminders
    with TableInfo<$RemindersTable, ReminderRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RemindersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _habitIdMeta = const VerificationMeta(
    'habitId',
  );
  @override
  late final GeneratedColumn<int> habitId = GeneratedColumn<int>(
    'habit_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES habits (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _minutesOfDayMeta = const VerificationMeta(
    'minutesOfDay',
  );
  @override
  late final GeneratedColumn<int> minutesOfDay = GeneratedColumn<int>(
    'minutes_of_day',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _weekdaysMaskMeta = const VerificationMeta(
    'weekdaysMask',
  );
  @override
  late final GeneratedColumn<int> weekdaysMask = GeneratedColumn<int>(
    'weekdays_mask',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(127),
  );
  static const VerificationMeta _enabledMeta = const VerificationMeta(
    'enabled',
  );
  @override
  late final GeneratedColumn<bool> enabled = GeneratedColumn<bool>(
    'enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    habitId,
    minutesOfDay,
    weekdaysMask,
    enabled,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reminders';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReminderRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('habit_id')) {
      context.handle(
        _habitIdMeta,
        habitId.isAcceptableOrUnknown(data['habit_id']!, _habitIdMeta),
      );
    } else if (isInserting) {
      context.missing(_habitIdMeta);
    }
    if (data.containsKey('minutes_of_day')) {
      context.handle(
        _minutesOfDayMeta,
        minutesOfDay.isAcceptableOrUnknown(
          data['minutes_of_day']!,
          _minutesOfDayMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_minutesOfDayMeta);
    }
    if (data.containsKey('weekdays_mask')) {
      context.handle(
        _weekdaysMaskMeta,
        weekdaysMask.isAcceptableOrUnknown(
          data['weekdays_mask']!,
          _weekdaysMaskMeta,
        ),
      );
    }
    if (data.containsKey('enabled')) {
      context.handle(
        _enabledMeta,
        enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReminderRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReminderRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      habitId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}habit_id'],
      )!,
      minutesOfDay: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}minutes_of_day'],
      )!,
      weekdaysMask: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}weekdays_mask'],
      )!,
      enabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}enabled'],
      )!,
    );
  }

  @override
  $RemindersTable createAlias(String alias) {
    return $RemindersTable(attachedDatabase, alias);
  }
}

class ReminderRow extends DataClass implements Insertable<ReminderRow> {
  final int id;
  final int habitId;
  final int minutesOfDay;
  final int weekdaysMask;
  final bool enabled;
  const ReminderRow({
    required this.id,
    required this.habitId,
    required this.minutesOfDay,
    required this.weekdaysMask,
    required this.enabled,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['habit_id'] = Variable<int>(habitId);
    map['minutes_of_day'] = Variable<int>(minutesOfDay);
    map['weekdays_mask'] = Variable<int>(weekdaysMask);
    map['enabled'] = Variable<bool>(enabled);
    return map;
  }

  RemindersCompanion toCompanion(bool nullToAbsent) {
    return RemindersCompanion(
      id: Value(id),
      habitId: Value(habitId),
      minutesOfDay: Value(minutesOfDay),
      weekdaysMask: Value(weekdaysMask),
      enabled: Value(enabled),
    );
  }

  factory ReminderRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReminderRow(
      id: serializer.fromJson<int>(json['id']),
      habitId: serializer.fromJson<int>(json['habitId']),
      minutesOfDay: serializer.fromJson<int>(json['minutesOfDay']),
      weekdaysMask: serializer.fromJson<int>(json['weekdaysMask']),
      enabled: serializer.fromJson<bool>(json['enabled']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'habitId': serializer.toJson<int>(habitId),
      'minutesOfDay': serializer.toJson<int>(minutesOfDay),
      'weekdaysMask': serializer.toJson<int>(weekdaysMask),
      'enabled': serializer.toJson<bool>(enabled),
    };
  }

  ReminderRow copyWith({
    int? id,
    int? habitId,
    int? minutesOfDay,
    int? weekdaysMask,
    bool? enabled,
  }) => ReminderRow(
    id: id ?? this.id,
    habitId: habitId ?? this.habitId,
    minutesOfDay: minutesOfDay ?? this.minutesOfDay,
    weekdaysMask: weekdaysMask ?? this.weekdaysMask,
    enabled: enabled ?? this.enabled,
  );
  ReminderRow copyWithCompanion(RemindersCompanion data) {
    return ReminderRow(
      id: data.id.present ? data.id.value : this.id,
      habitId: data.habitId.present ? data.habitId.value : this.habitId,
      minutesOfDay: data.minutesOfDay.present
          ? data.minutesOfDay.value
          : this.minutesOfDay,
      weekdaysMask: data.weekdaysMask.present
          ? data.weekdaysMask.value
          : this.weekdaysMask,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReminderRow(')
          ..write('id: $id, ')
          ..write('habitId: $habitId, ')
          ..write('minutesOfDay: $minutesOfDay, ')
          ..write('weekdaysMask: $weekdaysMask, ')
          ..write('enabled: $enabled')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, habitId, minutesOfDay, weekdaysMask, enabled);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReminderRow &&
          other.id == this.id &&
          other.habitId == this.habitId &&
          other.minutesOfDay == this.minutesOfDay &&
          other.weekdaysMask == this.weekdaysMask &&
          other.enabled == this.enabled);
}

class RemindersCompanion extends UpdateCompanion<ReminderRow> {
  final Value<int> id;
  final Value<int> habitId;
  final Value<int> minutesOfDay;
  final Value<int> weekdaysMask;
  final Value<bool> enabled;
  const RemindersCompanion({
    this.id = const Value.absent(),
    this.habitId = const Value.absent(),
    this.minutesOfDay = const Value.absent(),
    this.weekdaysMask = const Value.absent(),
    this.enabled = const Value.absent(),
  });
  RemindersCompanion.insert({
    this.id = const Value.absent(),
    required int habitId,
    required int minutesOfDay,
    this.weekdaysMask = const Value.absent(),
    this.enabled = const Value.absent(),
  }) : habitId = Value(habitId),
       minutesOfDay = Value(minutesOfDay);
  static Insertable<ReminderRow> custom({
    Expression<int>? id,
    Expression<int>? habitId,
    Expression<int>? minutesOfDay,
    Expression<int>? weekdaysMask,
    Expression<bool>? enabled,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (habitId != null) 'habit_id': habitId,
      if (minutesOfDay != null) 'minutes_of_day': minutesOfDay,
      if (weekdaysMask != null) 'weekdays_mask': weekdaysMask,
      if (enabled != null) 'enabled': enabled,
    });
  }

  RemindersCompanion copyWith({
    Value<int>? id,
    Value<int>? habitId,
    Value<int>? minutesOfDay,
    Value<int>? weekdaysMask,
    Value<bool>? enabled,
  }) {
    return RemindersCompanion(
      id: id ?? this.id,
      habitId: habitId ?? this.habitId,
      minutesOfDay: minutesOfDay ?? this.minutesOfDay,
      weekdaysMask: weekdaysMask ?? this.weekdaysMask,
      enabled: enabled ?? this.enabled,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (habitId.present) {
      map['habit_id'] = Variable<int>(habitId.value);
    }
    if (minutesOfDay.present) {
      map['minutes_of_day'] = Variable<int>(minutesOfDay.value);
    }
    if (weekdaysMask.present) {
      map['weekdays_mask'] = Variable<int>(weekdaysMask.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RemindersCompanion(')
          ..write('id: $id, ')
          ..write('habitId: $habitId, ')
          ..write('minutesOfDay: $minutesOfDay, ')
          ..write('weekdaysMask: $weekdaysMask, ')
          ..write('enabled: $enabled')
          ..write(')'))
        .toString();
  }
}

class $AgendaItemsTable extends AgendaItems
    with TableInfo<$AgendaItemsTable, AgendaRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AgendaItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _minutesOfDayMeta = const VerificationMeta(
    'minutesOfDay',
  );
  @override
  late final GeneratedColumn<int> minutesOfDay = GeneratedColumn<int>(
    'minutes_of_day',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('日程'),
  );
  static const VerificationMeta _originMeta = const VerificationMeta('origin');
  @override
  late final GeneratedColumn<String> origin = GeneratedColumn<String>(
    'origin',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _isDoneMeta = const VerificationMeta('isDone');
  @override
  late final GeneratedColumn<bool> isDone = GeneratedColumn<bool>(
    'is_done',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_done" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<int> source = GeneratedColumn<int>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _clientIdMeta = const VerificationMeta(
    'clientId',
  );
  @override
  late final GeneratedColumn<String> clientId = GeneratedColumn<String>(
    'client_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _remoteIdMeta = const VerificationMeta(
    'remoteId',
  );
  @override
  late final GeneratedColumn<String> remoteId = GeneratedColumn<String>(
    'remote_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _syncToRemoteMeta = const VerificationMeta(
    'syncToRemote',
  );
  @override
  late final GeneratedColumn<bool> syncToRemote = GeneratedColumn<bool>(
    'sync_to_remote',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("sync_to_remote" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _dirtyMeta = const VerificationMeta('dirty');
  @override
  late final GeneratedColumn<bool> dirty = GeneratedColumn<bool>(
    'dirty',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("dirty" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isHiddenMeta = const VerificationMeta(
    'isHidden',
  );
  @override
  late final GeneratedColumn<bool> isHidden = GeneratedColumn<bool>(
    'is_hidden',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_hidden" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    date,
    minutesOfDay,
    title,
    note,
    category,
    origin,
    isDone,
    source,
    clientId,
    remoteId,
    syncToRemote,
    dirty,
    isHidden,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'agenda_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<AgendaRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('minutes_of_day')) {
      context.handle(
        _minutesOfDayMeta,
        minutesOfDay.isAcceptableOrUnknown(
          data['minutes_of_day']!,
          _minutesOfDayMeta,
        ),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    }
    if (data.containsKey('origin')) {
      context.handle(
        _originMeta,
        origin.isAcceptableOrUnknown(data['origin']!, _originMeta),
      );
    }
    if (data.containsKey('is_done')) {
      context.handle(
        _isDoneMeta,
        isDone.isAcceptableOrUnknown(data['is_done']!, _isDoneMeta),
      );
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    }
    if (data.containsKey('client_id')) {
      context.handle(
        _clientIdMeta,
        clientId.isAcceptableOrUnknown(data['client_id']!, _clientIdMeta),
      );
    } else if (isInserting) {
      context.missing(_clientIdMeta);
    }
    if (data.containsKey('remote_id')) {
      context.handle(
        _remoteIdMeta,
        remoteId.isAcceptableOrUnknown(data['remote_id']!, _remoteIdMeta),
      );
    }
    if (data.containsKey('sync_to_remote')) {
      context.handle(
        _syncToRemoteMeta,
        syncToRemote.isAcceptableOrUnknown(
          data['sync_to_remote']!,
          _syncToRemoteMeta,
        ),
      );
    }
    if (data.containsKey('dirty')) {
      context.handle(
        _dirtyMeta,
        dirty.isAcceptableOrUnknown(data['dirty']!, _dirtyMeta),
      );
    }
    if (data.containsKey('is_hidden')) {
      context.handle(
        _isHiddenMeta,
        isHidden.isAcceptableOrUnknown(data['is_hidden']!, _isHiddenMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AgendaRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AgendaRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      minutesOfDay: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}minutes_of_day'],
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      origin: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origin'],
      )!,
      isDone: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_done'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}source'],
      )!,
      clientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_id'],
      )!,
      remoteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_id'],
      ),
      syncToRemote: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}sync_to_remote'],
      )!,
      dirty: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}dirty'],
      )!,
      isHidden: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_hidden'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $AgendaItemsTable createAlias(String alias) {
    return $AgendaItemsTable(attachedDatabase, alias);
  }
}

class AgendaRow extends DataClass implements Insertable<AgendaRow> {
  final int id;
  final String date;
  final int? minutesOfDay;
  final String title;
  final String note;
  final String category;
  final String origin;
  final bool isDone;

  /// 0 = iBetter 本地新建，1 = 来自轻松日程。
  final int source;
  final String clientId;
  final String? remoteId;
  final bool syncToRemote;
  final bool dirty;

  /// 已关联远端的条目在手机上删除时只隐藏，避免下次同步又被拉回来。
  final bool isHidden;
  final int createdAt;
  final int updatedAt;
  const AgendaRow({
    required this.id,
    required this.date,
    this.minutesOfDay,
    required this.title,
    required this.note,
    required this.category,
    required this.origin,
    required this.isDone,
    required this.source,
    required this.clientId,
    this.remoteId,
    required this.syncToRemote,
    required this.dirty,
    required this.isHidden,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['date'] = Variable<String>(date);
    if (!nullToAbsent || minutesOfDay != null) {
      map['minutes_of_day'] = Variable<int>(minutesOfDay);
    }
    map['title'] = Variable<String>(title);
    map['note'] = Variable<String>(note);
    map['category'] = Variable<String>(category);
    map['origin'] = Variable<String>(origin);
    map['is_done'] = Variable<bool>(isDone);
    map['source'] = Variable<int>(source);
    map['client_id'] = Variable<String>(clientId);
    if (!nullToAbsent || remoteId != null) {
      map['remote_id'] = Variable<String>(remoteId);
    }
    map['sync_to_remote'] = Variable<bool>(syncToRemote);
    map['dirty'] = Variable<bool>(dirty);
    map['is_hidden'] = Variable<bool>(isHidden);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  AgendaItemsCompanion toCompanion(bool nullToAbsent) {
    return AgendaItemsCompanion(
      id: Value(id),
      date: Value(date),
      minutesOfDay: minutesOfDay == null && nullToAbsent
          ? const Value.absent()
          : Value(minutesOfDay),
      title: Value(title),
      note: Value(note),
      category: Value(category),
      origin: Value(origin),
      isDone: Value(isDone),
      source: Value(source),
      clientId: Value(clientId),
      remoteId: remoteId == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteId),
      syncToRemote: Value(syncToRemote),
      dirty: Value(dirty),
      isHidden: Value(isHidden),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory AgendaRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AgendaRow(
      id: serializer.fromJson<int>(json['id']),
      date: serializer.fromJson<String>(json['date']),
      minutesOfDay: serializer.fromJson<int?>(json['minutesOfDay']),
      title: serializer.fromJson<String>(json['title']),
      note: serializer.fromJson<String>(json['note']),
      category: serializer.fromJson<String>(json['category']),
      origin: serializer.fromJson<String>(json['origin']),
      isDone: serializer.fromJson<bool>(json['isDone']),
      source: serializer.fromJson<int>(json['source']),
      clientId: serializer.fromJson<String>(json['clientId']),
      remoteId: serializer.fromJson<String?>(json['remoteId']),
      syncToRemote: serializer.fromJson<bool>(json['syncToRemote']),
      dirty: serializer.fromJson<bool>(json['dirty']),
      isHidden: serializer.fromJson<bool>(json['isHidden']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'date': serializer.toJson<String>(date),
      'minutesOfDay': serializer.toJson<int?>(minutesOfDay),
      'title': serializer.toJson<String>(title),
      'note': serializer.toJson<String>(note),
      'category': serializer.toJson<String>(category),
      'origin': serializer.toJson<String>(origin),
      'isDone': serializer.toJson<bool>(isDone),
      'source': serializer.toJson<int>(source),
      'clientId': serializer.toJson<String>(clientId),
      'remoteId': serializer.toJson<String?>(remoteId),
      'syncToRemote': serializer.toJson<bool>(syncToRemote),
      'dirty': serializer.toJson<bool>(dirty),
      'isHidden': serializer.toJson<bool>(isHidden),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  AgendaRow copyWith({
    int? id,
    String? date,
    Value<int?> minutesOfDay = const Value.absent(),
    String? title,
    String? note,
    String? category,
    String? origin,
    bool? isDone,
    int? source,
    String? clientId,
    Value<String?> remoteId = const Value.absent(),
    bool? syncToRemote,
    bool? dirty,
    bool? isHidden,
    int? createdAt,
    int? updatedAt,
  }) => AgendaRow(
    id: id ?? this.id,
    date: date ?? this.date,
    minutesOfDay: minutesOfDay.present ? minutesOfDay.value : this.minutesOfDay,
    title: title ?? this.title,
    note: note ?? this.note,
    category: category ?? this.category,
    origin: origin ?? this.origin,
    isDone: isDone ?? this.isDone,
    source: source ?? this.source,
    clientId: clientId ?? this.clientId,
    remoteId: remoteId.present ? remoteId.value : this.remoteId,
    syncToRemote: syncToRemote ?? this.syncToRemote,
    dirty: dirty ?? this.dirty,
    isHidden: isHidden ?? this.isHidden,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  AgendaRow copyWithCompanion(AgendaItemsCompanion data) {
    return AgendaRow(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      minutesOfDay: data.minutesOfDay.present
          ? data.minutesOfDay.value
          : this.minutesOfDay,
      title: data.title.present ? data.title.value : this.title,
      note: data.note.present ? data.note.value : this.note,
      category: data.category.present ? data.category.value : this.category,
      origin: data.origin.present ? data.origin.value : this.origin,
      isDone: data.isDone.present ? data.isDone.value : this.isDone,
      source: data.source.present ? data.source.value : this.source,
      clientId: data.clientId.present ? data.clientId.value : this.clientId,
      remoteId: data.remoteId.present ? data.remoteId.value : this.remoteId,
      syncToRemote: data.syncToRemote.present
          ? data.syncToRemote.value
          : this.syncToRemote,
      dirty: data.dirty.present ? data.dirty.value : this.dirty,
      isHidden: data.isHidden.present ? data.isHidden.value : this.isHidden,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AgendaRow(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('minutesOfDay: $minutesOfDay, ')
          ..write('title: $title, ')
          ..write('note: $note, ')
          ..write('category: $category, ')
          ..write('origin: $origin, ')
          ..write('isDone: $isDone, ')
          ..write('source: $source, ')
          ..write('clientId: $clientId, ')
          ..write('remoteId: $remoteId, ')
          ..write('syncToRemote: $syncToRemote, ')
          ..write('dirty: $dirty, ')
          ..write('isHidden: $isHidden, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    date,
    minutesOfDay,
    title,
    note,
    category,
    origin,
    isDone,
    source,
    clientId,
    remoteId,
    syncToRemote,
    dirty,
    isHidden,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AgendaRow &&
          other.id == this.id &&
          other.date == this.date &&
          other.minutesOfDay == this.minutesOfDay &&
          other.title == this.title &&
          other.note == this.note &&
          other.category == this.category &&
          other.origin == this.origin &&
          other.isDone == this.isDone &&
          other.source == this.source &&
          other.clientId == this.clientId &&
          other.remoteId == this.remoteId &&
          other.syncToRemote == this.syncToRemote &&
          other.dirty == this.dirty &&
          other.isHidden == this.isHidden &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class AgendaItemsCompanion extends UpdateCompanion<AgendaRow> {
  final Value<int> id;
  final Value<String> date;
  final Value<int?> minutesOfDay;
  final Value<String> title;
  final Value<String> note;
  final Value<String> category;
  final Value<String> origin;
  final Value<bool> isDone;
  final Value<int> source;
  final Value<String> clientId;
  final Value<String?> remoteId;
  final Value<bool> syncToRemote;
  final Value<bool> dirty;
  final Value<bool> isHidden;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  const AgendaItemsCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.minutesOfDay = const Value.absent(),
    this.title = const Value.absent(),
    this.note = const Value.absent(),
    this.category = const Value.absent(),
    this.origin = const Value.absent(),
    this.isDone = const Value.absent(),
    this.source = const Value.absent(),
    this.clientId = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.syncToRemote = const Value.absent(),
    this.dirty = const Value.absent(),
    this.isHidden = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  AgendaItemsCompanion.insert({
    this.id = const Value.absent(),
    required String date,
    this.minutesOfDay = const Value.absent(),
    required String title,
    this.note = const Value.absent(),
    this.category = const Value.absent(),
    this.origin = const Value.absent(),
    this.isDone = const Value.absent(),
    this.source = const Value.absent(),
    required String clientId,
    this.remoteId = const Value.absent(),
    this.syncToRemote = const Value.absent(),
    this.dirty = const Value.absent(),
    this.isHidden = const Value.absent(),
    required int createdAt,
    required int updatedAt,
  }) : date = Value(date),
       title = Value(title),
       clientId = Value(clientId),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<AgendaRow> custom({
    Expression<int>? id,
    Expression<String>? date,
    Expression<int>? minutesOfDay,
    Expression<String>? title,
    Expression<String>? note,
    Expression<String>? category,
    Expression<String>? origin,
    Expression<bool>? isDone,
    Expression<int>? source,
    Expression<String>? clientId,
    Expression<String>? remoteId,
    Expression<bool>? syncToRemote,
    Expression<bool>? dirty,
    Expression<bool>? isHidden,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (minutesOfDay != null) 'minutes_of_day': minutesOfDay,
      if (title != null) 'title': title,
      if (note != null) 'note': note,
      if (category != null) 'category': category,
      if (origin != null) 'origin': origin,
      if (isDone != null) 'is_done': isDone,
      if (source != null) 'source': source,
      if (clientId != null) 'client_id': clientId,
      if (remoteId != null) 'remote_id': remoteId,
      if (syncToRemote != null) 'sync_to_remote': syncToRemote,
      if (dirty != null) 'dirty': dirty,
      if (isHidden != null) 'is_hidden': isHidden,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  AgendaItemsCompanion copyWith({
    Value<int>? id,
    Value<String>? date,
    Value<int?>? minutesOfDay,
    Value<String>? title,
    Value<String>? note,
    Value<String>? category,
    Value<String>? origin,
    Value<bool>? isDone,
    Value<int>? source,
    Value<String>? clientId,
    Value<String?>? remoteId,
    Value<bool>? syncToRemote,
    Value<bool>? dirty,
    Value<bool>? isHidden,
    Value<int>? createdAt,
    Value<int>? updatedAt,
  }) {
    return AgendaItemsCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      minutesOfDay: minutesOfDay ?? this.minutesOfDay,
      title: title ?? this.title,
      note: note ?? this.note,
      category: category ?? this.category,
      origin: origin ?? this.origin,
      isDone: isDone ?? this.isDone,
      source: source ?? this.source,
      clientId: clientId ?? this.clientId,
      remoteId: remoteId ?? this.remoteId,
      syncToRemote: syncToRemote ?? this.syncToRemote,
      dirty: dirty ?? this.dirty,
      isHidden: isHidden ?? this.isHidden,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (minutesOfDay.present) {
      map['minutes_of_day'] = Variable<int>(minutesOfDay.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (origin.present) {
      map['origin'] = Variable<String>(origin.value);
    }
    if (isDone.present) {
      map['is_done'] = Variable<bool>(isDone.value);
    }
    if (source.present) {
      map['source'] = Variable<int>(source.value);
    }
    if (clientId.present) {
      map['client_id'] = Variable<String>(clientId.value);
    }
    if (remoteId.present) {
      map['remote_id'] = Variable<String>(remoteId.value);
    }
    if (syncToRemote.present) {
      map['sync_to_remote'] = Variable<bool>(syncToRemote.value);
    }
    if (dirty.present) {
      map['dirty'] = Variable<bool>(dirty.value);
    }
    if (isHidden.present) {
      map['is_hidden'] = Variable<bool>(isHidden.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AgendaItemsCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('minutesOfDay: $minutesOfDay, ')
          ..write('title: $title, ')
          ..write('note: $note, ')
          ..write('category: $category, ')
          ..write('origin: $origin, ')
          ..write('isDone: $isDone, ')
          ..write('source: $source, ')
          ..write('clientId: $clientId, ')
          ..write('remoteId: $remoteId, ')
          ..write('syncToRemote: $syncToRemote, ')
          ..write('dirty: $dirty, ')
          ..write('isHidden: $isHidden, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $HabitsTable habits = $HabitsTable(this);
  late final $CheckInsTable checkIns = $CheckInsTable(this);
  late final $RemindersTable reminders = $RemindersTable(this);
  late final $AgendaItemsTable agendaItems = $AgendaItemsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    habits,
    checkIns,
    reminders,
    agendaItems,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'habits',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('check_ins', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'habits',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('reminders', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$HabitsTableCreateCompanionBuilder = HabitsCompanion Function({
  Value<int> id,
  required String name,
  required String iconKey,
  Value<int> scheduleType,
  Value<int> scheduleValue,
  Value<int> weekdaysMask,
  Value<int?> goalDays,
  required String startDate,
  Value<String> motto,
  Value<bool> enableScore,
  Value<bool> enableMood,
  Value<int> dailyTarget,
  Value<bool> isActive,
  Value<int> sortOrder,
  required int createdAt,
});
typedef $$HabitsTableUpdateCompanionBuilder = HabitsCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<String> iconKey,
  Value<int> scheduleType,
  Value<int> scheduleValue,
  Value<int> weekdaysMask,
  Value<int?> goalDays,
  Value<String> startDate,
  Value<String> motto,
  Value<bool> enableScore,
  Value<bool> enableMood,
  Value<int> dailyTarget,
  Value<bool> isActive,
  Value<int> sortOrder,
  Value<int> createdAt,
});

final class $$HabitsTableReferences
    extends BaseReferences<_$AppDatabase, $HabitsTable, HabitRow> {
  $$HabitsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$CheckInsTable, List<CheckInRow>>
  _checkInsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.checkIns,
    aliasName: 'habits__id__check_ins__habit_id',
  );

  $$CheckInsTableProcessedTableManager get checkInsRefs {
    final manager = $$CheckInsTableTableManager(
      $_db,
      $_db.checkIns,
    ).filter((f) => f.habitId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_checkInsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$RemindersTable, List<ReminderRow>>
  _remindersRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.reminders,
    aliasName: 'habits__id__reminders__habit_id',
  );

  $$RemindersTableProcessedTableManager get remindersRefs {
    final manager = $$RemindersTableTableManager(
      $_db,
      $_db.reminders,
    ).filter((f) => f.habitId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_remindersRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$HabitsTableFilterComposer
    extends Composer<_$AppDatabase, $HabitsTable> {
  $$HabitsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get iconKey => $composableBuilder(
    column: $table.iconKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get scheduleType => $composableBuilder(
    column: $table.scheduleType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get scheduleValue => $composableBuilder(
    column: $table.scheduleValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get weekdaysMask => $composableBuilder(
    column: $table.weekdaysMask,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get goalDays => $composableBuilder(
    column: $table.goalDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get motto => $composableBuilder(
    column: $table.motto,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get enableScore => $composableBuilder(
    column: $table.enableScore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get enableMood => $composableBuilder(
    column: $table.enableMood,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dailyTarget => $composableBuilder(
    column: $table.dailyTarget,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> checkInsRefs(
    Expression<bool> Function($$CheckInsTableFilterComposer f) f,
  ) {
    final $$CheckInsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.checkIns,
      getReferencedColumn: (t) => t.habitId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CheckInsTableFilterComposer(
            $db: $db,
            $table: $db.checkIns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> remindersRefs(
    Expression<bool> Function($$RemindersTableFilterComposer f) f,
  ) {
    final $$RemindersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.reminders,
      getReferencedColumn: (t) => t.habitId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RemindersTableFilterComposer(
            $db: $db,
            $table: $db.reminders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$HabitsTableOrderingComposer
    extends Composer<_$AppDatabase, $HabitsTable> {
  $$HabitsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get iconKey => $composableBuilder(
    column: $table.iconKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get scheduleType => $composableBuilder(
    column: $table.scheduleType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get scheduleValue => $composableBuilder(
    column: $table.scheduleValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get weekdaysMask => $composableBuilder(
    column: $table.weekdaysMask,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get goalDays => $composableBuilder(
    column: $table.goalDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get motto => $composableBuilder(
    column: $table.motto,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get enableScore => $composableBuilder(
    column: $table.enableScore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get enableMood => $composableBuilder(
    column: $table.enableMood,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dailyTarget => $composableBuilder(
    column: $table.dailyTarget,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$HabitsTableAnnotationComposer
    extends Composer<_$AppDatabase, $HabitsTable> {
  $$HabitsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get iconKey =>
      $composableBuilder(column: $table.iconKey, builder: (column) => column);

  GeneratedColumn<int> get scheduleType => $composableBuilder(
    column: $table.scheduleType,
    builder: (column) => column,
  );

  GeneratedColumn<int> get scheduleValue => $composableBuilder(
    column: $table.scheduleValue,
    builder: (column) => column,
  );

  GeneratedColumn<int> get weekdaysMask => $composableBuilder(
    column: $table.weekdaysMask,
    builder: (column) => column,
  );

  GeneratedColumn<int> get goalDays =>
      $composableBuilder(column: $table.goalDays, builder: (column) => column);

  GeneratedColumn<String> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<String> get motto =>
      $composableBuilder(column: $table.motto, builder: (column) => column);

  GeneratedColumn<bool> get enableScore => $composableBuilder(
    column: $table.enableScore,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get enableMood => $composableBuilder(
    column: $table.enableMood,
    builder: (column) => column,
  );

  GeneratedColumn<int> get dailyTarget => $composableBuilder(
    column: $table.dailyTarget,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> checkInsRefs<T extends Object>(
    Expression<T> Function($$CheckInsTableAnnotationComposer a) f,
  ) {
    final $$CheckInsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.checkIns,
      getReferencedColumn: (t) => t.habitId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CheckInsTableAnnotationComposer(
            $db: $db,
            $table: $db.checkIns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> remindersRefs<T extends Object>(
    Expression<T> Function($$RemindersTableAnnotationComposer a) f,
  ) {
    final $$RemindersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.reminders,
      getReferencedColumn: (t) => t.habitId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RemindersTableAnnotationComposer(
            $db: $db,
            $table: $db.reminders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$HabitsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $HabitsTable,
          HabitRow,
          $$HabitsTableFilterComposer,
          $$HabitsTableOrderingComposer,
          $$HabitsTableAnnotationComposer,
          $$HabitsTableCreateCompanionBuilder,
          $$HabitsTableUpdateCompanionBuilder,
          (HabitRow, $$HabitsTableReferences),
          HabitRow,
          PrefetchHooks Function({bool checkInsRefs, bool remindersRefs})
        > {
  $$HabitsTableTableManager(_$AppDatabase db, $HabitsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HabitsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HabitsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HabitsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> iconKey = const Value.absent(),
                Value<int> scheduleType = const Value.absent(),
                Value<int> scheduleValue = const Value.absent(),
                Value<int> weekdaysMask = const Value.absent(),
                Value<int?> goalDays = const Value.absent(),
                Value<String> startDate = const Value.absent(),
                Value<String> motto = const Value.absent(),
                Value<bool> enableScore = const Value.absent(),
                Value<bool> enableMood = const Value.absent(),
                Value<int> dailyTarget = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
              }) => HabitsCompanion(
                id: id,
                name: name,
                iconKey: iconKey,
                scheduleType: scheduleType,
                scheduleValue: scheduleValue,
                weekdaysMask: weekdaysMask,
                goalDays: goalDays,
                startDate: startDate,
                motto: motto,
                enableScore: enableScore,
                enableMood: enableMood,
                dailyTarget: dailyTarget,
                isActive: isActive,
                sortOrder: sortOrder,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required String iconKey,
                Value<int> scheduleType = const Value.absent(),
                Value<int> scheduleValue = const Value.absent(),
                Value<int> weekdaysMask = const Value.absent(),
                Value<int?> goalDays = const Value.absent(),
                required String startDate,
                Value<String> motto = const Value.absent(),
                Value<bool> enableScore = const Value.absent(),
                Value<bool> enableMood = const Value.absent(),
                Value<int> dailyTarget = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                required int createdAt,
              }) => HabitsCompanion.insert(
                id: id,
                name: name,
                iconKey: iconKey,
                scheduleType: scheduleType,
                scheduleValue: scheduleValue,
                weekdaysMask: weekdaysMask,
                goalDays: goalDays,
                startDate: startDate,
                motto: motto,
                enableScore: enableScore,
                enableMood: enableMood,
                dailyTarget: dailyTarget,
                isActive: isActive,
                sortOrder: sortOrder,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$HabitsTable, HabitRow>(table),
                  $$HabitsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({checkInsRefs = false, remindersRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (checkInsRefs) db.checkIns,
                    if (remindersRefs) db.reminders,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (checkInsRefs)
                        await $_getPrefetchedDataByColumns<
                          HabitRow,
                          $HabitsTable,
                          CheckInRow,
                          $CheckInsTable
                        >(
                          currentTable: table,
                          referencedTable: $$HabitsTableReferences
                              ._checkInsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$HabitsTableReferences(
                                db,
                                table,
                                p0,
                              ).checkInsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'habit_id',
                          typedResults: items,
                        ),
                      if (remindersRefs)
                        await $_getPrefetchedDataByColumns<
                          HabitRow,
                          $HabitsTable,
                          ReminderRow,
                          $RemindersTable
                        >(
                          currentTable: table,
                          referencedTable: $$HabitsTableReferences
                              ._remindersRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$HabitsTableReferences(
                                db,
                                table,
                                p0,
                              ).remindersRefs,
                          currentColumn: 'id',
                          referencedColumn: 'habit_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$HabitsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $HabitsTable,
      HabitRow,
      $$HabitsTableFilterComposer,
      $$HabitsTableOrderingComposer,
      $$HabitsTableAnnotationComposer,
      $$HabitsTableCreateCompanionBuilder,
      $$HabitsTableUpdateCompanionBuilder,
      (HabitRow, $$HabitsTableReferences),
      HabitRow,
      PrefetchHooks Function({bool checkInsRefs, bool remindersRefs})
    >;
typedef $$CheckInsTableCreateCompanionBuilder = CheckInsCompanion Function({
  Value<int> id,
  required int habitId,
  required String date,
  Value<int> doneCount,
  Value<int?> score,
  Value<int?> mood,
  Value<String?> note,
  required int updatedAt,
});
typedef $$CheckInsTableUpdateCompanionBuilder = CheckInsCompanion Function({
  Value<int> id,
  Value<int> habitId,
  Value<String> date,
  Value<int> doneCount,
  Value<int?> score,
  Value<int?> mood,
  Value<String?> note,
  Value<int> updatedAt,
});

final class $$CheckInsTableReferences
    extends BaseReferences<_$AppDatabase, $CheckInsTable, CheckInRow> {
  $$CheckInsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $HabitsTable _habitIdTable(_$AppDatabase db) =>
      db.habits.createAlias('check_ins__habit_id__habits__id');

  $$HabitsTableProcessedTableManager get habitId {
    final $_column = $_itemColumn<int>('habit_id')!;

    final manager = $$HabitsTableTableManager(
      $_db,
      $_db.habits,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_habitIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CheckInsTableFilterComposer
    extends Composer<_$AppDatabase, $CheckInsTable> {
  $$CheckInsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get doneCount => $composableBuilder(
    column: $table.doneCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get mood => $composableBuilder(
    column: $table.mood,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$HabitsTableFilterComposer get habitId {
    final $$HabitsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.habitId,
      referencedTable: $db.habits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HabitsTableFilterComposer(
            $db: $db,
            $table: $db.habits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CheckInsTableOrderingComposer
    extends Composer<_$AppDatabase, $CheckInsTable> {
  $$CheckInsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get doneCount => $composableBuilder(
    column: $table.doneCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get mood => $composableBuilder(
    column: $table.mood,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$HabitsTableOrderingComposer get habitId {
    final $$HabitsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.habitId,
      referencedTable: $db.habits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HabitsTableOrderingComposer(
            $db: $db,
            $table: $db.habits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CheckInsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CheckInsTable> {
  $$CheckInsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<int> get doneCount =>
      $composableBuilder(column: $table.doneCount, builder: (column) => column);

  GeneratedColumn<int> get score =>
      $composableBuilder(column: $table.score, builder: (column) => column);

  GeneratedColumn<int> get mood =>
      $composableBuilder(column: $table.mood, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$HabitsTableAnnotationComposer get habitId {
    final $$HabitsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.habitId,
      referencedTable: $db.habits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HabitsTableAnnotationComposer(
            $db: $db,
            $table: $db.habits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CheckInsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CheckInsTable,
          CheckInRow,
          $$CheckInsTableFilterComposer,
          $$CheckInsTableOrderingComposer,
          $$CheckInsTableAnnotationComposer,
          $$CheckInsTableCreateCompanionBuilder,
          $$CheckInsTableUpdateCompanionBuilder,
          (CheckInRow, $$CheckInsTableReferences),
          CheckInRow,
          PrefetchHooks Function({bool habitId})
        > {
  $$CheckInsTableTableManager(_$AppDatabase db, $CheckInsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CheckInsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CheckInsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CheckInsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> habitId = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<int> doneCount = const Value.absent(),
                Value<int?> score = const Value.absent(),
                Value<int?> mood = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
              }) => CheckInsCompanion(
                id: id,
                habitId: habitId,
                date: date,
                doneCount: doneCount,
                score: score,
                mood: mood,
                note: note,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int habitId,
                required String date,
                Value<int> doneCount = const Value.absent(),
                Value<int?> score = const Value.absent(),
                Value<int?> mood = const Value.absent(),
                Value<String?> note = const Value.absent(),
                required int updatedAt,
              }) => CheckInsCompanion.insert(
                id: id,
                habitId: habitId,
                date: date,
                doneCount: doneCount,
                score: score,
                mood: mood,
                note: note,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CheckInsTable, CheckInRow>(table),
                  $$CheckInsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({habitId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (habitId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.habitId,
                        referencedTable: $$CheckInsTableReferences
                            ._habitIdTable(db),
                        referencedColumn: $$CheckInsTableReferences
                            ._habitIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$CheckInsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CheckInsTable,
      CheckInRow,
      $$CheckInsTableFilterComposer,
      $$CheckInsTableOrderingComposer,
      $$CheckInsTableAnnotationComposer,
      $$CheckInsTableCreateCompanionBuilder,
      $$CheckInsTableUpdateCompanionBuilder,
      (CheckInRow, $$CheckInsTableReferences),
      CheckInRow,
      PrefetchHooks Function({bool habitId})
    >;
typedef $$RemindersTableCreateCompanionBuilder = RemindersCompanion Function({
  Value<int> id,
  required int habitId,
  required int minutesOfDay,
  Value<int> weekdaysMask,
  Value<bool> enabled,
});
typedef $$RemindersTableUpdateCompanionBuilder = RemindersCompanion Function({
  Value<int> id,
  Value<int> habitId,
  Value<int> minutesOfDay,
  Value<int> weekdaysMask,
  Value<bool> enabled,
});

final class $$RemindersTableReferences
    extends BaseReferences<_$AppDatabase, $RemindersTable, ReminderRow> {
  $$RemindersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $HabitsTable _habitIdTable(_$AppDatabase db) =>
      db.habits.createAlias('reminders__habit_id__habits__id');

  $$HabitsTableProcessedTableManager get habitId {
    final $_column = $_itemColumn<int>('habit_id')!;

    final manager = $$HabitsTableTableManager(
      $_db,
      $_db.habits,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_habitIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$RemindersTableFilterComposer
    extends Composer<_$AppDatabase, $RemindersTable> {
  $$RemindersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get minutesOfDay => $composableBuilder(
    column: $table.minutesOfDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get weekdaysMask => $composableBuilder(
    column: $table.weekdaysMask,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnFilters(column),
  );

  $$HabitsTableFilterComposer get habitId {
    final $$HabitsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.habitId,
      referencedTable: $db.habits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HabitsTableFilterComposer(
            $db: $db,
            $table: $db.habits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RemindersTableOrderingComposer
    extends Composer<_$AppDatabase, $RemindersTable> {
  $$RemindersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get minutesOfDay => $composableBuilder(
    column: $table.minutesOfDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get weekdaysMask => $composableBuilder(
    column: $table.weekdaysMask,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnOrderings(column),
  );

  $$HabitsTableOrderingComposer get habitId {
    final $$HabitsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.habitId,
      referencedTable: $db.habits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HabitsTableOrderingComposer(
            $db: $db,
            $table: $db.habits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RemindersTableAnnotationComposer
    extends Composer<_$AppDatabase, $RemindersTable> {
  $$RemindersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get minutesOfDay => $composableBuilder(
    column: $table.minutesOfDay,
    builder: (column) => column,
  );

  GeneratedColumn<int> get weekdaysMask => $composableBuilder(
    column: $table.weekdaysMask,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);

  $$HabitsTableAnnotationComposer get habitId {
    final $$HabitsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.habitId,
      referencedTable: $db.habits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HabitsTableAnnotationComposer(
            $db: $db,
            $table: $db.habits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RemindersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RemindersTable,
          ReminderRow,
          $$RemindersTableFilterComposer,
          $$RemindersTableOrderingComposer,
          $$RemindersTableAnnotationComposer,
          $$RemindersTableCreateCompanionBuilder,
          $$RemindersTableUpdateCompanionBuilder,
          (ReminderRow, $$RemindersTableReferences),
          ReminderRow,
          PrefetchHooks Function({bool habitId})
        > {
  $$RemindersTableTableManager(_$AppDatabase db, $RemindersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RemindersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RemindersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RemindersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> habitId = const Value.absent(),
                Value<int> minutesOfDay = const Value.absent(),
                Value<int> weekdaysMask = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
              }) => RemindersCompanion(
                id: id,
                habitId: habitId,
                minutesOfDay: minutesOfDay,
                weekdaysMask: weekdaysMask,
                enabled: enabled,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int habitId,
                required int minutesOfDay,
                Value<int> weekdaysMask = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
              }) => RemindersCompanion.insert(
                id: id,
                habitId: habitId,
                minutesOfDay: minutesOfDay,
                weekdaysMask: weekdaysMask,
                enabled: enabled,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$RemindersTable, ReminderRow>(table),
                  $$RemindersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({habitId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (habitId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.habitId,
                        referencedTable: $$RemindersTableReferences
                            ._habitIdTable(db),
                        referencedColumn: $$RemindersTableReferences
                            ._habitIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$RemindersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RemindersTable,
      ReminderRow,
      $$RemindersTableFilterComposer,
      $$RemindersTableOrderingComposer,
      $$RemindersTableAnnotationComposer,
      $$RemindersTableCreateCompanionBuilder,
      $$RemindersTableUpdateCompanionBuilder,
      (ReminderRow, $$RemindersTableReferences),
      ReminderRow,
      PrefetchHooks Function({bool habitId})
    >;
typedef $$AgendaItemsTableCreateCompanionBuilder =
    AgendaItemsCompanion Function({
      Value<int> id,
      required String date,
      Value<int?> minutesOfDay,
      required String title,
      Value<String> note,
      Value<String> category,
      Value<String> origin,
      Value<bool> isDone,
      Value<int> source,
      required String clientId,
      Value<String?> remoteId,
      Value<bool> syncToRemote,
      Value<bool> dirty,
      Value<bool> isHidden,
      required int createdAt,
      required int updatedAt,
    });
typedef $$AgendaItemsTableUpdateCompanionBuilder =
    AgendaItemsCompanion Function({
      Value<int> id,
      Value<String> date,
      Value<int?> minutesOfDay,
      Value<String> title,
      Value<String> note,
      Value<String> category,
      Value<String> origin,
      Value<bool> isDone,
      Value<int> source,
      Value<String> clientId,
      Value<String?> remoteId,
      Value<bool> syncToRemote,
      Value<bool> dirty,
      Value<bool> isHidden,
      Value<int> createdAt,
      Value<int> updatedAt,
    });

class $$AgendaItemsTableFilterComposer
    extends Composer<_$AppDatabase, $AgendaItemsTable> {
  $$AgendaItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get minutesOfDay => $composableBuilder(
    column: $table.minutesOfDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get origin => $composableBuilder(
    column: $table.origin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDone => $composableBuilder(
    column: $table.isDone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get syncToRemote => $composableBuilder(
    column: $table.syncToRemote,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get dirty => $composableBuilder(
    column: $table.dirty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isHidden => $composableBuilder(
    column: $table.isHidden,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AgendaItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $AgendaItemsTable> {
  $$AgendaItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get minutesOfDay => $composableBuilder(
    column: $table.minutesOfDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get origin => $composableBuilder(
    column: $table.origin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDone => $composableBuilder(
    column: $table.isDone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get syncToRemote => $composableBuilder(
    column: $table.syncToRemote,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get dirty => $composableBuilder(
    column: $table.dirty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isHidden => $composableBuilder(
    column: $table.isHidden,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AgendaItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AgendaItemsTable> {
  $$AgendaItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<int> get minutesOfDay => $composableBuilder(
    column: $table.minutesOfDay,
    builder: (column) => column,
  );

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get origin =>
      $composableBuilder(column: $table.origin, builder: (column) => column);

  GeneratedColumn<bool> get isDone =>
      $composableBuilder(column: $table.isDone, builder: (column) => column);

  GeneratedColumn<int> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get clientId =>
      $composableBuilder(column: $table.clientId, builder: (column) => column);

  GeneratedColumn<String> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => column);

  GeneratedColumn<bool> get syncToRemote => $composableBuilder(
    column: $table.syncToRemote,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get dirty =>
      $composableBuilder(column: $table.dirty, builder: (column) => column);

  GeneratedColumn<bool> get isHidden =>
      $composableBuilder(column: $table.isHidden, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$AgendaItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AgendaItemsTable,
          AgendaRow,
          $$AgendaItemsTableFilterComposer,
          $$AgendaItemsTableOrderingComposer,
          $$AgendaItemsTableAnnotationComposer,
          $$AgendaItemsTableCreateCompanionBuilder,
          $$AgendaItemsTableUpdateCompanionBuilder,
          (
            AgendaRow,
            BaseReferences<_$AppDatabase, $AgendaItemsTable, AgendaRow>,
          ),
          AgendaRow,
          PrefetchHooks Function()
        > {
  $$AgendaItemsTableTableManager(_$AppDatabase db, $AgendaItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AgendaItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AgendaItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AgendaItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<int?> minutesOfDay = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String> origin = const Value.absent(),
                Value<bool> isDone = const Value.absent(),
                Value<int> source = const Value.absent(),
                Value<String> clientId = const Value.absent(),
                Value<String?> remoteId = const Value.absent(),
                Value<bool> syncToRemote = const Value.absent(),
                Value<bool> dirty = const Value.absent(),
                Value<bool> isHidden = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
              }) => AgendaItemsCompanion(
                id: id,
                date: date,
                minutesOfDay: minutesOfDay,
                title: title,
                note: note,
                category: category,
                origin: origin,
                isDone: isDone,
                source: source,
                clientId: clientId,
                remoteId: remoteId,
                syncToRemote: syncToRemote,
                dirty: dirty,
                isHidden: isHidden,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String date,
                Value<int?> minutesOfDay = const Value.absent(),
                required String title,
                Value<String> note = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String> origin = const Value.absent(),
                Value<bool> isDone = const Value.absent(),
                Value<int> source = const Value.absent(),
                required String clientId,
                Value<String?> remoteId = const Value.absent(),
                Value<bool> syncToRemote = const Value.absent(),
                Value<bool> dirty = const Value.absent(),
                Value<bool> isHidden = const Value.absent(),
                required int createdAt,
                required int updatedAt,
              }) => AgendaItemsCompanion.insert(
                id: id,
                date: date,
                minutesOfDay: minutesOfDay,
                title: title,
                note: note,
                category: category,
                origin: origin,
                isDone: isDone,
                source: source,
                clientId: clientId,
                remoteId: remoteId,
                syncToRemote: syncToRemote,
                dirty: dirty,
                isHidden: isHidden,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AgendaItemsTable, AgendaRow>(table),
                  BaseReferences<_$AppDatabase, $AgendaItemsTable, AgendaRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AgendaItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AgendaItemsTable,
      AgendaRow,
      $$AgendaItemsTableFilterComposer,
      $$AgendaItemsTableOrderingComposer,
      $$AgendaItemsTableAnnotationComposer,
      $$AgendaItemsTableCreateCompanionBuilder,
      $$AgendaItemsTableUpdateCompanionBuilder,
      (AgendaRow, BaseReferences<_$AppDatabase, $AgendaItemsTable, AgendaRow>),
      AgendaRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$HabitsTableTableManager get habits =>
      $$HabitsTableTableManager(_db, _db.habits);
  $$CheckInsTableTableManager get checkIns =>
      $$CheckInsTableTableManager(_db, _db.checkIns);
  $$RemindersTableTableManager get reminders =>
      $$RemindersTableTableManager(_db, _db.reminders);
  $$AgendaItemsTableTableManager get agendaItems =>
      $$AgendaItemsTableTableManager(_db, _db.agendaItems);
}
