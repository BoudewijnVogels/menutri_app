import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/api_service.dart';

class CateraarNotificationsPage extends ConsumerStatefulWidget {
  const CateraarNotificationsPage({super.key});

  @override
  ConsumerState<CateraarNotificationsPage> createState() =>
      _CateraarNotificationsPageState();
}

class _CateraarNotificationsPageState
    extends ConsumerState<CateraarNotificationsPage>
    with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();

  late TabController _tabController;

  bool _isLoading = true;
  List<Map<String, dynamic>> _notifications = [];
  List<Map<String, dynamic>> _filteredNotifications = [];
  Map<String, bool> _notificationSettings = {};
  String _searchQuery = '';
  String _filterType = 'all';
  String _filterStatus = 'all';
  bool _showOnlyUnread = false;

  final Map<String, String> _typeLabels = {
    'all': 'Alle Meldingen',
    'review': 'Nieuwe Reviews',
    'order': 'Bestellingen',
    'team': 'Team Updates',
    'system': 'Systeem Meldingen',
    'promotion': 'Promoties',
    'analytics': 'Analytics',
    'menu': 'Menu Updates',
    'restaurant': 'Restaurant Updates',
    'payment': 'Betalingen',
    'security': 'Beveiliging',
  };

  final Map<String, IconData> _typeIcons = {
    'review': Icons.rate_review,
    'order': Icons.shopping_cart,
    'team': Icons.group,
    'system': Icons.settings,
    'promotion': Icons.local_offer,
    'analytics': Icons.analytics,
    'menu': Icons.restaurant,
    'restaurant': Icons.store,
    'payment': Icons.payment,
    'security': Icons.security,
  };

  final Map<String, Color> _typeColors = {
    'review': Colors.blue,
    'order': Colors.green,
    'team': Colors.purple,
    'system': Colors.grey,
    'promotion': Colors.orange,
    'analytics': Colors.teal,
    'menu': Colors.brown,
    'restaurant': Colors.indigo,
    'payment': Colors.pink,
    'security': Colors.red,
  };

  final Map<String, String> _statusLabels = {
    'all': 'Alle Statussen',
    'unread': 'Ongelezen',
    'read': 'Gelezen',
    'archived': 'Gearchiveerd',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final notificationsResponse = await _apiService.getNotifications();
      final settingsResponse = await _apiService.getNotificationPreferences();
      final notifications =
          List<Map<String, dynamic>>.from(notificationsResponse);
      final settings = Map<String, bool>.from(settingsResponse);

      setState(() {
        _notifications = notifications;
        _notificationSettings = settings;
        _isLoading = false;
      });

      _filterNotifications();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fout bij laden notificaties: $e')),
        );
      }
    }
  }

  void _filterNotifications() {
    List<Map<String, dynamic>> filtered = List.from(_notifications);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((notification) {
        final title = (notification['title'] ?? '').toLowerCase();
        final message = (notification['message'] ?? '').toLowerCase();
        final query = _searchQuery.toLowerCase();
        return title.contains(query) || message.contains(query);
      }).toList();
    }

    // Apply type filter
    if (_filterType != 'all') {
      filtered = filtered.where((notification) {
        return notification['type'] == _filterType;
      }).toList();
    }

    // Apply status filter
    if (_filterStatus != 'all') {
      filtered = filtered.where((notification) {
        return (notification['status'] ??
                (notification['is_read'] == true ? 'read' : 'unread')) ==
            _filterStatus;
      }).toList();
    }

    // Apply unread filter toggle
    if (_showOnlyUnread) {
      filtered = filtered.where((notification) {
        return notification['is_read'] != true;
      }).toList();
    }

    // Sort by date (newest first)
    filtered.sort((a, b) {
      final aDate = DateTime.tryParse(a['created_at'] ?? '') ?? DateTime.now();
      final bDate = DateTime.tryParse(b['created_at'] ?? '') ?? DateTime.now();
      return bDate.compareTo(aDate);
    });

    setState(() {
      _filteredNotifications = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notificaties'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.mark_email_read),
            onPressed: () => _markAllAsRead(),
            tooltip: 'Alles als gelezen markeren',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'mark_all_read':
                  _markAllAsRead();
                  break;
                case 'clear_all':
                  _showClearAllDialog();
                  break;
                case 'export':
                  _exportNotifications();
                  break;
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'mark_all_read',
                child: ListTile(
                  leading: Icon(Icons.mark_email_read),
                  title: Text('Alles als gelezen markeren'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'clear_all',
                child: ListTile(
                  leading: Icon(Icons.clear_all),
                  title: Text('Alles wissen'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'export',
                child: ListTile(
                  leading: Icon(Icons.download),
                  title: Text('Exporteren'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'test_notification',
                child: ListTile(
                  leading: Icon(Icons.notifications_active),
                  title: Text('Test Notificatie'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: TabBar(
            controller: _tabController,
            indicatorColor: AppColors.onPrimary,
            labelColor: AppColors.onPrimary,
            unselectedLabelColor:
                AppColors.withAlphaFraction(AppColors.onPrimary, 0.7),
            tabs: [
              Tab(text: 'Alle (${_notifications.length})'),
              Tab(
                  text:
                      'Ongelezen (${_notifications.where((n) => n['is_read'] != true).length})'),
              const Tab(text: 'Instellingen'),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildAllNotificationsTab(),
                _buildUnreadNotificationsTab(),
                _buildSettingsTab(),
              ],
            ),
    );
  }

  Widget _buildAllNotificationsTab() {
    return Column(
      children: [
        // Search and filter bar
        _buildSearchAndFilter(),

        // Notifications list
        Expanded(
          child: _filteredNotifications.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredNotifications.length,
                    itemBuilder: (context, index) {
                      final notification = _filteredNotifications[index];
                      return _buildNotificationCard(notification);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildUnreadNotificationsTab() {
    final unreadNotifications =
        _notifications.where((n) => n['is_read'] != true).toList();

    return unreadNotifications.isEmpty
        ? _buildEmptyUnreadState()
        : RefreshIndicator(
            onRefresh: _loadData,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: unreadNotifications.length,
              itemBuilder: (context, index) {
                final notification = unreadNotifications[index];
                return _buildNotificationCard(notification,
                    showQuickActions: true);
              },
            ),
          );
  }

  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Notificatie Instellingen',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Beheer welke notificaties je wilt ontvangen',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),

          const SizedBox(height: 24),

          // Push notifications
          _buildSettingsSection(
            'Push Notificaties',
            'Ontvang notificaties op je apparaat',
            [
              _buildSettingTile(
                'push_notifications',
                'Push Notificaties',
                'Ontvang notificaties op je apparaat',
                Icons.notifications,
              ),
              _buildSettingTile(
                'sound_enabled',
                'Geluid',
                'Speel geluid af bij notificaties',
                Icons.volume_up,
              ),
              _buildSettingTile(
                'vibration_enabled',
                'Trillen',
                'Laat apparaat trillen bij notificaties',
                Icons.vibration,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Email notifications
          _buildSettingsSection(
            'Email Notificaties',
            'Ontvang notificaties via email',
            [
              _buildSettingTile(
                'email_notifications',
                'Email Notificaties',
                'Ontvang notificaties via email',
                Icons.email,
              ),
              _buildSettingTile(
                'email_digest',
                'Dagelijkse Samenvatting',
                'Ontvang dagelijkse email samenvatting',
                Icons.summarize,
              ),
              _buildSettingTile(
                'email_weekly_report',
                'Wekelijks Rapport',
                'Ontvang wekelijks analytics rapport',
                Icons.assessment,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Notification types
          _buildSettingsSection(
            'Notificatie Types',
            'Kies welke types notificaties je wilt ontvangen',
            _typeLabels.entries
                .where((entry) => entry.key != 'all')
                .map((entry) {
              return _buildSettingTile(
                'type_${entry.key}',
                entry.value,
                _getTypeDescription(entry.key),
                _typeIcons[entry.key] ?? Icons.notifications,
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          // Advanced settings
          _buildSettingsSection(
            'Geavanceerde Instellingen',
            'Aanvullende notificatie opties',
            [
              _buildSettingTile(
                'quiet_hours_enabled',
                'Stille Uren',
                'Geen notificaties tussen 22:00 - 08:00',
                Icons.bedtime,
              ),
              _buildSettingTile(
                'priority_only',
                'Alleen Prioriteit',
                'Alleen belangrijke notificaties tonen',
                Icons.priority_high,
              ),
              _buildSettingTile(
                'group_notifications',
                'Groepeer Notificaties',
                'Groepeer vergelijkbare notificaties',
                Icons.group_work,
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _resetToDefaults(),
                  icon: const Icon(Icons.restore),
                  label: const Text('Standaard Instellingen'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _saveSettings(),
                  icon: const Icon(Icons.save),
                  label: const Text('Opslaan'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.withAlphaFraction(Colors.black, 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Zoek notificaties...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_searchQuery.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                        _filterNotifications();
                      },
                    ),
                  IconButton(
                    icon: Icon(
                      _showOnlyUnread
                          ? Icons.mark_email_unread
                          : Icons.mark_email_read,
                      color: _showOnlyUnread ? AppColors.primary : null,
                    ),
                    onPressed: () {
                      setState(() {
                        _showOnlyUnread = !_showOnlyUnread;
                      });
                      _filterNotifications();
                    },
                    tooltip: _showOnlyUnread ? 'Toon alle' : 'Alleen ongelezen',
                  ),
                ],
              ),
              border: const OutlineInputBorder(),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
              _filterNotifications();
            },
          ),

          const SizedBox(height: 12),

          // Type filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ..._typeLabels.entries.map((entry) {
                  final isSelected = _filterType == entry.key;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(entry.value),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _filterType = selected ? entry.key : 'all';
                        });
                        _filterNotifications();
                      },
                      backgroundColor: AppColors.background,
                      selectedColor: AppColors.withAlphaFraction(
                        _typeColors[entry.key] ?? AppColors.primary,
                        0.2,
                      ),
                      checkmarkColor:
                          _typeColors[entry.key] ?? AppColors.primary,
                    ),
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Status filters (gebruikt _statusLabels)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ..._statusLabels.entries.map((entry) {
                  final isSelected = _filterStatus == entry.key;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(entry.value),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _filterStatus = selected ? entry.key : 'all';
                        });
                        _filterNotifications();
                      },
                      backgroundColor: AppColors.background,
                      selectedColor: AppColors.withAlphaFraction(
                        AppColors.primary,
                        0.15,
                      ),
                      checkmarkColor: AppColors.primary,
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification,
      {bool showQuickActions = false}) {
    final type = notification['type'] ?? 'system';
    final isRead = notification['is_read'] == true;
    final isImportant = notification['priority'] == 'high';
    final hasAction = notification['action_url'] != null;

    // Bepaal statuslabel (fallback op is_read)
    final statusKey =
        (notification['status'] ?? (isRead ? 'read' : 'unread')).toString();
    final statusLabel = _statusLabels[statusKey] ?? statusKey;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isRead ? 1 : 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isImportant && !isRead
            ? BorderSide(
                color: AppColors.withAlphaFraction(Colors.red, 0.3), width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () => _handleNotificationTap(notification),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type icon
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.withAlphaFraction(
                        _typeColors[type] ?? AppColors.primary,
                        0.10,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _typeIcons[type] ?? Icons.notifications,
                      color: _typeColors[type] ?? AppColors.primary,
                      size: 20,
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Title and timestamp
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                notification['title'] ?? '',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: isRead
                                          ? FontWeight.normal
                                          : FontWeight.bold,
                                    ),
                              ),
                            ),
                            if (isImportant)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.withAlphaFraction(
                                      Colors.red, 0.10),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Belangrijk',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color: Colors.red,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDateTime(notification['created_at']),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                        ),
                      ],
                    ),
                  ),

                  // Read status indicator
                  if (!isRead)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),

                  // Actions menu
                  PopupMenuButton<String>(
                    onSelected: (value) =>
                        _handleNotificationAction(value, notification),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: isRead ? 'mark_unread' : 'mark_read',
                        child: ListTile(
                          leading: Icon(isRead
                              ? Icons.mark_email_unread
                              : Icons.mark_email_read),
                          title: Text(isRead
                              ? 'Als ongelezen markeren'
                              : 'Als gelezen markeren'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'archive',
                        child: ListTile(
                          leading: Icon(Icons.archive),
                          title: Text('Archiveren'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      if (hasAction)
                        const PopupMenuItem(
                          value: 'open_action',
                          child: ListTile(
                            leading: Icon(Icons.open_in_new),
                            title: Text('Actie Openen'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete, color: Colors.red),
                          title: Text(
                            'Verwijderen',
                            style: TextStyle(color: Colors.red),
                          ),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Message
              Text(
                notification['message'] ?? '',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isRead
                          ? AppColors.textSecondary
                          : AppColors.textPrimary,
                    ),
              ),

              const SizedBox(height: 12),

              // Status badge (gebruikt _statusLabels)
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.withAlphaFraction(
                          statusKey == 'unread'
                              ? AppColors.primary
                              : Colors.grey,
                          0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      statusLabel,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: statusKey == 'unread'
                                ? AppColors.primary
                                : Colors.grey[800],
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (type != 'system')
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.withAlphaFraction(
                            _typeColors[type] ?? AppColors.primary, 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        _typeLabels[type] ?? type,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: _typeColors[type] ?? AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                ],
              ),

              // Action button
              if (hasAction) ...[
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () => _openNotificationAction(notification),
                  icon: const Icon(Icons.open_in_new),
                  label: Text(notification['action_text'] ?? 'Bekijken'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _typeColors[type] ?? AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],

              // Quick actions for unread notifications
              if (showQuickActions && !isRead) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _markAsRead(notification),
                        icon: const Icon(Icons.mark_email_read),
                        label: const Text('Als gelezen markeren'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsSection(
      String title, String subtitle, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingTile(
      String key, String title, String subtitle, IconData icon) {
    final isEnabled = _notificationSettings[key] ?? true;

    return ListTile(
      leading: Icon(icon, color: isEnabled ? AppColors.primary : Colors.grey),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Switch(
        value: isEnabled,
        onChanged: (value) {
          setState(() {
            _notificationSettings[key] = value;
          });
        },
        activeThumbColor: AppColors.primary,
      ),
      onTap: () {
        setState(() {
          _notificationSettings[key] = !isEnabled;
        });
      },
    );
  }

  Widget _buildEmptyState() {
    final isFiltered = _searchQuery.isNotEmpty ||
        _filterType != 'all' ||
        _showOnlyUnread ||
        _filterStatus != 'all';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              isFiltered ? 'Geen notificaties gevonden' : 'Geen notificaties',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              isFiltered
                  ? 'Probeer een andere zoekopdracht of filter'
                  : 'Je ontvangt hier notificaties over je restaurants',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyUnreadState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.mark_email_read,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'Geen Ongelezen Notificaties',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Alle notificaties zijn gelezen! 🎉',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _handleNotificationTap(Map<String, dynamic> notification) {
    if (notification['is_read'] != true) {
      _markAsRead(notification);
    }

    if (notification['action_url'] != null) {
      _openNotificationAction(notification);
    }
  }

  void _handleNotificationAction(
      String action, Map<String, dynamic> notification) {
    switch (action) {
      case 'mark_read':
        _markAsRead(notification);
        break;
      case 'open_action':
        _openNotificationAction(notification);
        break;
      case 'delete':
        _deleteNotification(notification);
        break;
    }
  }

  Future<void> _markAsRead(Map<String, dynamic> notification) async {
    try {
      await _apiService.markNotificationRead(notification['id']);
      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notificatie als gelezen gemarkeerd'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fout bij markeren als gelezen: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _deleteNotification(Map<String, dynamic> notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notificatie Verwijderen'),
        content: const Text(
            'Weet je zeker dat je deze notificatie wilt verwijderen? Deze actie kan niet ongedaan worden gemaakt.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuleren'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _apiService.deleteNotification(notification['id']);
                await _loadData();

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Notificatie verwijderd'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Fout bij verwijderen: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Verwijderen'),
          ),
        ],
      ),
    );
  }

  void _openNotificationAction(Map<String, dynamic> notification) {
    final actionUrl = notification['action_url'];
    if (actionUrl != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Navigeren naar: $actionUrl'),
        ),
      );
      // TODO: vervang bovenstaande met daadwerkelijke navigatie (GoRouter, etc.)
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      await _apiService.markAllNotificationsRead();
      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Alle notificaties als gelezen gemarkeerd'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fout bij markeren alle als gelezen: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Alle Notificaties Wissen'),
        content: const Text(
            'Weet je zeker dat je alle notificaties wilt wissen? Deze actie kan niet ongedaan worden gemaakt.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuleren'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _apiService.clearAllNotifications();
                await _loadData();

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Alle notificaties gewist'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Fout bij wissen alle notificaties: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Wissen'),
          ),
        ],
      ),
    );
  }

  void _exportNotifications() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Export functionaliteit wordt binnenkort toegevoegd'),
      ),
    );
  }

  Future<void> _saveSettings() async {
    try {
      await _apiService.updateNotificationPreferences(_notificationSettings);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Instellingen opgeslagen'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fout bij opslaan instellingen: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _resetToDefaults() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Standaard Instellingen'),
        content: const Text(
            'Weet je zeker dat je alle instellingen wilt terugzetten naar de standaardwaarden?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuleren'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _notificationSettings = {
                  'push_notifications': true,
                  'sound_enabled': true,
                  'vibration_enabled': true,
                  'email_notifications': true,
                  'email_digest': false,
                  'email_weekly_report': true,
                  'type_review': true,
                  'type_order': true,
                  'type_team': true,
                  'type_system': true,
                  'type_promotion': false,
                  'type_analytics': true,
                  'type_menu': true,
                  'type_restaurant': true,
                  'type_payment': true,
                  'type_security': true,
                  'quiet_hours_enabled': false,
                  'priority_only': false,
                  'group_notifications': true,
                };
              });

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content:
                      Text('Instellingen teruggezet naar standaardwaarden'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Terugzetten'),
          ),
        ],
      ),
    );
  }

  String _getTypeDescription(String type) {
    switch (type) {
      case 'review':
        return 'Nieuwe reviews en beoordelingen';
      case 'order':
        return 'Nieuwe bestellingen en updates';
      case 'team':
        return 'Team uitnodigingen en updates';
      case 'system':
        return 'Systeem updates en onderhoud';
      case 'promotion':
        return 'Promoties en marketing berichten';
      case 'analytics':
        return 'Analytics rapporten en inzichten';
      case 'menu':
        return 'Menu wijzigingen en updates';
      case 'restaurant':
        return 'Restaurant informatie updates';
      case 'payment':
        return 'Betalingen en facturatie';
      case 'security':
        return 'Beveiligings waarschuwingen';
      default:
        return 'Algemene notificaties';
    }
  }

  String _formatDateTime(String? dateTime) {
    if (dateTime == null) return '';

    try {
      final date = DateTime.parse(dateTime);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 0) {
        return '${difference.inDays} dagen geleden';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} uur geleden';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} minuten geleden';
      } else {
        return 'Zojuist';
      }
    } catch (e) {
      return dateTime;
    }
  }
}
