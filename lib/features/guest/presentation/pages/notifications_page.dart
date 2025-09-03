import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/api_service.dart';

class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _notifications = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Notification settings
  bool _favoriteNotifications = true;
  bool _eatenNotifications = true;
  bool _reviewNotifications = true;
  bool _milestoneNotifications = true;
  bool _promoNotifications = false;
  bool _soundEnabled = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadNotifications();
    _loadNotificationSettings();
  }

  Future<void> _loadNotifications() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final notifications = await ApiService().getNotifications();

      setState(() {
        _notifications = notifications is List
            ? (notifications as List<dynamic>)
            : (notifications['notifications'] as List<dynamic>? ?? []);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Kon notificaties niet laden: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadNotificationSettings() async {
    try {
      final settings = await ApiService().getNotificationPreferences();

      setState(() {
        _favoriteNotifications = settings['favorite_notifications'] ?? true;
        _eatenNotifications = settings['eaten_notifications'] ?? true;
        _reviewNotifications = settings['review_notifications'] ?? true;
        _milestoneNotifications = settings['milestone_notifications'] ?? true;
        _promoNotifications = settings['promo_notifications'] ?? false;
        _soundEnabled = settings['sound_enabled'] ?? true;
      });
    } catch (e) {
      // Settings loading is optional
      print('Could not load notification settings: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaties'),
        backgroundColor: AppColors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSettingsBottomSheet,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.mediumBrown,
          unselectedLabelColor: AppColors.grey,
          indicatorColor: AppColors.mediumBrown,
          tabs: const [
            Tab(text: 'Alle'),
            Tab(text: 'Ongelezen'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildNotificationsList(showUnreadOnly: false),
          _buildNotificationsList(showUnreadOnly: true),
        ],
      ),
    );
  }

  Widget _buildNotificationsList({required bool showUnreadOnly}) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    final filteredNotifications = showUnreadOnly
        ? _notifications.where((n) => !(n['read'] ?? false)).toList()
        : _notifications;

    if (filteredNotifications.isEmpty) {
      return _buildEmptyState(showUnreadOnly);
    }

    return RefreshIndicator(
      onRefresh: _loadNotifications,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredNotifications.length,
        itemBuilder: (context, index) {
          final notification = filteredNotifications[index];
          return _buildNotificationCard(notification);
        },
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    final isRead = notification['read'] ?? false;
    final type = notification['type'] ?? 'general';
    final createdAt = DateTime.tryParse(notification['created_at'] ?? '');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isRead
          ? null
          : AppColors.withAlphaFraction(AppColors.lightBrown, 0.3),
      child: InkWell(
        onTap: () => _handleNotificationTap(notification),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Notification icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getNotificationColor(type).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  _getNotificationIcon(type),
                  color: _getNotificationColor(type),
                  size: 24,
                ),
              ),

              const SizedBox(width: 16),

              // Notification content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification['title'] ?? 'Notificatie',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: isRead
                                      ? FontWeight.normal
                                      : FontWeight.w600,
                                ),
                          ),
                        ),
                        if (!isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.mediumBrown,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification['message'] ?? '',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.grey,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatNotificationTime(createdAt),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.grey,
                          ),
                    ),
                  ],
                ),
              ),

              // Actions
              PopupMenuButton(
                itemBuilder: (context) => [
                  if (!isRead)
                    const PopupMenuItem(
                      value: 'mark_read',
                      child: Row(
                        children: [
                          Icon(Icons.mark_email_read),
                          SizedBox(width: 8),
                          Text('Markeer als gelezen'),
                        ],
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: AppColors.error),
                        SizedBox(width: 8),
                        Text('Verwijderen'),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'mark_read') {
                    _markAsRead(notification['id']);
                  } else if (value == 'delete') {
                    _deleteNotification(notification['id']);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool showUnreadOnly) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            showUnreadOnly ? Icons.mark_email_read : Icons.notifications_none,
            size: 64,
            color: AppColors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            showUnreadOnly
                ? 'Geen ongelezen notificaties'
                : 'Geen notificaties',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            showUnreadOnly
                ? 'Alle notificaties zijn gelezen'
                : 'Je ontvangt hier meldingen over favorieten, reviews en meer',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.grey,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: AppColors.error),
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadNotifications,
            child: const Text('Opnieuw proberen'),
          ),
        ],
      ),
    );
  }

  void _showSettingsBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(16),
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Text(
                    'Notificatie-instellingen',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _saveNotificationSettings();
                    },
                    child: const Text('Opslaan'),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Meldingstypen',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                      const SizedBox(height: 8),
                      _buildSettingsTile(
                        'Favorieten',
                        'Meldingen wanneer restaurants of gerechten worden toegevoegd aan favorieten',
                        _favoriteNotifications,
                        (value) =>
                            setModalState(() => _favoriteNotifications = value),
                      ),
                      _buildSettingsTile(
                        'Gegeten gerechten',
                        'Meldingen over gelogde maaltijden en voedingsdoelen',
                        _eatenNotifications,
                        (value) =>
                            setModalState(() => _eatenNotifications = value),
                      ),
                      _buildSettingsTile(
                        'Reviews',
                        'Meldingen over nieuwe reviews van restaurants',
                        _reviewNotifications,
                        (value) =>
                            setModalState(() => _reviewNotifications = value),
                      ),
                      _buildSettingsTile(
                        'Mijlpalen',
                        'Meldingen bij het bereiken van doelen (bijv. 100 favorieten)',
                        _milestoneNotifications,
                        (value) => setModalState(
                            () => _milestoneNotifications = value),
                      ),
                      _buildSettingsTile(
                        'Promoties',
                        'Meldingen over Menutri updates en aanbiedingen',
                        _promoNotifications,
                        (value) =>
                            setModalState(() => _promoNotifications = value),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Geluid en trillingen',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                      const SizedBox(height: 8),
                      _buildSettingsTile(
                        'Geluid',
                        'Speel geluid af bij nieuwe notificaties',
                        _soundEnabled,
                        (value) => setModalState(() => _soundEnabled = value),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsTile(
      String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.grey,
            ),
      ),
      value: value,
      onChanged: onChanged,
      activeThumbColor: AppColors.mediumBrown,
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'favorite':
        return Icons.favorite;
      case 'eaten':
        return Icons.restaurant_menu;
      case 'review':
        return Icons.rate_review;
      case 'milestone':
        return Icons.emoji_events;
      case 'promo':
        return Icons.local_offer;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'favorite':
        return AppColors.error;
      case 'eaten':
        return AppColors.success;
      case 'review':
        return AppColors.mediumBrown;
      case 'milestone':
        return AppColors.warning;
      case 'promo':
        return AppColors.darkBrown;
      default:
        return AppColors.grey;
    }
  }

  String _formatNotificationTime(DateTime? dateTime) {
    if (dateTime == null) return 'Onbekend';

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Nu';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m geleden';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}u geleden';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d geleden';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  void _handleNotificationTap(Map<String, dynamic> notification) {
    // Mark as read if not already read
    if (!(notification['read'] ?? false)) {
      _markAsRead(notification['id']);
    }

    // Handle navigation based on notification type
    final type = notification['type'] ?? 'general';
    final data = notification['data'] as Map<String, dynamic>? ?? {};

    switch (type) {
      case 'favorite':
        if (data['restaurant_id'] != null) {
          // Navigate to restaurant detail
          // context.push('/guest/restaurant/${data['restaurant_id']}');
        }
        break;
      case 'eaten':
        // Navigate to nutrition log
        // context.push('/guest/nutrition-log');
        break;
      case 'review':
        if (data['restaurant_id'] != null) {
          // Navigate to restaurant reviews
          // context.push('/guest/restaurant/${data['restaurant_id']}?tab=reviews');
        }
        break;
      default:
        // General notification, no specific action
        break;
    }
  }

  Future<void> _markAsRead(int notificationId) async {
    try {
      await ApiService().markNotificationRead(notificationId);

      setState(() {
        final index =
            _notifications.indexWhere((n) => n['id'] == notificationId);
        if (index != -1) {
          _notifications[index]['read'] = true;
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kon notificatie niet markeren als gelezen: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _deleteNotification(int notificationId) async {
    try {
      await ApiService().deleteNotification(notificationId);

      setState(() {
        _notifications.removeWhere((n) => n['id'] == notificationId);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notificatie verwijderd'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kon notificatie niet verwijderen: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _saveNotificationSettings() async {
    try {
      final settings = {
        'favorite_notifications': _favoriteNotifications,
        'eaten_notifications': _eatenNotifications,
        'review_notifications': _reviewNotifications,
        'milestone_notifications': _milestoneNotifications,
        'promo_notifications': _promoNotifications,
        'sound_enabled': _soundEnabled,
      };

      await ApiService().updateNotificationPreferences(settings);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Instellingen opgeslagen'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kon instellingen niet opslaan: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
