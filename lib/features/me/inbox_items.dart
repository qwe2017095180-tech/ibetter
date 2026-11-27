/// Built-in local inbox messages displayed on "我的" -> "我的收件箱".
class InboxMessage {
  const InboxMessage({
    required this.id,
    required this.sender,
    required this.handle,
    required this.date,
    required this.title,
    required this.body,
  });

  final String id;
  final String sender;
  final String handle;
  final String date;
  final String title;
  final String body;
}

const List<InboxMessage> kInboxMessages = [
  InboxMessage(
    id: 'msg_welcome_sync',
    sender: '轻松打卡 助手',
    handle: '@qingsong',
    date: '2026-11-27',
    title: '欢迎使用轻松打卡 · 本地备份与桌面挂件已上线',
    body:
        '现在你可以在「我的 → 设置」中自由调整卡片风格、网格布局、日历达成配色与每周起始日，也可以开启密码保护、配置桌面小部件，或随时导出本地 JSON 备份，确保打卡记录安心无忧。',
  ),
  InboxMessage(
    id: 'msg_icons_160',
    sender: '轻松打卡 助手',
    handle: '@qingsong',
    date: '2026-11-25',
    title: '「图标库」160+ 精美 3D 图标，覆盖学习运动健康与心情',
    body:
        '创建或编辑习惯项目时，可在底部自由挑选追求成就、更健康、爱学习、爱运动、爱生活与心情 6 大分类图标，让每日打卡更有仪式感。',
  ),
  InboxMessage(
    id: 'msg_lan_agenda',
    sender: '轻松打卡 助手',
    handle: '@qingsong',
    date: '2026-11-22',
    title: '局域网同步电脑「轻松日程」，今日安排一目了然',
    body:
        '在「更多 → 轻松日程同步」中填入电脑端显示的局域网地址与 8 位配对码，即可在首页下拉刷新双向同步今日日程，还支持在 GitHub Releases 一键拉取应用内更新。',
  ),
];
