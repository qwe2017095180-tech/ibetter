/// 轻松日程（qingsong-rili）通知卡片在 iBetter 里的镜像，对应 `/bridge/v1/notices`。
/// 纯 Dart，不依赖 Flutter。
library;

class QingsongNotice {
  const QingsongNotice({
    required this.id,
    required this.title,
    this.summary = '',
    this.detail = '',
    this.category = '其他',
    this.deadline,
    this.status = 'new',
    this.group = '',
    this.externalId,
    this.createdAt,
    this.updatedAt,
    this.archivedAt,
  });

  final String id;
  final String title;
  final String summary;
  final String detail;
  final String category;

  /// `YYYY-MM-DD HH:mm` / `YYYY-MM-DD` / null。
  final String? deadline;

  /// new | todo | done | skip
  final String status;
  final String group;

  /// 由 iBetter 新建时的 clientId。
  final String? externalId;
  final int? createdAt;
  final int? updatedAt;
  final int? archivedAt;

  bool get isNew => status == 'new';
  bool get isTodo => status == 'todo';
  bool get isDone => status == 'done';
  bool get isSkipped => status == 'skip';
  bool get isArchived => status == 'done' || status == 'skip';
  bool get isLocalOnly => id.startsWith('local:');

  QingsongNotice copyWith({
    String? title,
    String? summary,
    String? detail,
    String? category,
    String? deadline,
    bool clearDeadline = false,
    String? status,
    String? group,
    String? externalId,
    int? createdAt,
    int? updatedAt,
    int? archivedAt,
    bool clearArchivedAt = false,
  }) =>
      QingsongNotice(
        id: id,
        title: title ?? this.title,
        summary: summary ?? this.summary,
        detail: detail ?? this.detail,
        category: category ?? this.category,
        deadline: clearDeadline ? null : (deadline ?? this.deadline),
        status: status ?? this.status,
        group: group ?? this.group,
        externalId: externalId ?? this.externalId,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        archivedAt: clearArchivedAt ? null : (archivedAt ?? this.archivedAt),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'summary': summary,
        'detail': detail,
        'category': category,
        'deadline': deadline,
        'status': status,
        'group': group,
        'externalId': externalId,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
        'archivedAt': archivedAt,
      };

  static QingsongNotice? tryParse(Object? json) {
    if (json is! Map) return null;
    final id = json['id'];
    if (id is! String || id.isEmpty) return null;
    String str(String k, [String fallback = '']) {
      final v = json[k];
      return v is String ? v : fallback;
    }

    int? integer(String k) {
      final v = json[k];
      return v is num ? v.toInt() : null;
    }

    final deadline = json['deadline'];
    final externalId = json['externalId'];
    return QingsongNotice(
      id: id,
      title: str('title').trim(),
      summary: str('summary').trim(),
      detail: str('detail').trim(),
      category: str('category', '其他'),
      deadline: deadline is String && deadline.trim().isNotEmpty ? deadline.trim() : null,
      status: str('status', 'new'),
      group: str('group'),
      externalId: externalId is String && externalId.isNotEmpty ? externalId : null,
      createdAt: integer('createdAt'),
      updatedAt: integer('updatedAt'),
      archivedAt: integer('archivedAt'),
    );
  }
}
