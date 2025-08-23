import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/api_service.dart';

class TeamManagementPage extends ConsumerStatefulWidget {
  const TeamManagementPage({super.key});

  @override
  ConsumerState<TeamManagementPage> createState() => _TeamManagementPageState();
}

class _TeamManagementPageState extends ConsumerState<TeamManagementPage>
    with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  
  late TabController _tabController;
  
  bool _isLoading = true;
  List<Map<String, dynamic>> _teamMembers = [];
  List<Map<String, dynamic>> _filteredMembers = [];
  List<Map<String, dynamic>> _pendingInvitations = [];
  List<Map<String, dynamic>> _restaurants = [];
  String _searchQuery = '';
  String _filterRole = 'all';
  String _filterStatus = 'all';

  final Map<String, String> _roleLabels = {
    'owner': 'Eigenaar',
    'admin': 'Beheerder',
    'manager': 'Manager',
    'staff': 'Medewerker',
    'viewer': 'Kijker',
  };

  final Map<String, Color> _roleColors = {
    'owner': Colors.purple,
    'admin': Colors.red,
    'manager': Colors.orange,
    'staff': Colors.blue,
    'viewer': Colors.green,
  };

  final Map<String, String> _statusLabels = {
    'active': 'Actief',
    'inactive': 'Inactief',
    'pending': 'In afwachting',
    'suspended': 'Geschorst',
  };

  final Map<String, Color> _statusColors = {
    'active': Colors.green,
    'inactive': Colors.grey,
    'pending': Colors.orange,
    'suspended': Colors.red,
  };

  final Map<String, List<String>> _rolePermissions = {
    'owner': [
      'Alle rechten',
      'Team beheren',
      'Restaurants beheren',
      'Menu\'s beheren',
      'Analytics bekijken',
      'Facturatie beheren',
    ],
    'admin': [
      'Team uitnodigen',
      'Restaurants beheren',
      'Menu\'s beheren',
      'Analytics bekijken',
      'Reviews modereren',
    ],
    'manager': [
      'Menu\'s bewerken',
      'Analytics bekijken',
      'Reviews modereren',
      'Ingrediënten beheren',
    ],
    'staff': [
      'Menu\'s bekijken',
      'Ingrediënten bekijken',
      'Basis analytics',
    ],
    'viewer': [
      'Alleen bekijken',
      'Basis informatie',
    ],
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
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final teamResponse = await _apiService.getTeamMembers();
      final invitationsResponse = await _apiService.getPendingInvitations();
      final restaurantsResponse = await _apiService.getRestaurants();
      
      final members = List<Map<String, dynamic>>.from(
        teamResponse['members'] ?? []
      );
      final invitations = List<Map<String, dynamic>>.from(
        invitationsResponse['invitations'] ?? []
      );
      final restaurants = List<Map<String, dynamic>>.from(
        restaurantsResponse['restaurants'] ?? []
      );
      
      setState(() {
        _teamMembers = members;
        _pendingInvitations = invitations;
        _restaurants = restaurants;
        _isLoading = false;
      });
      
      _filterMembers();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fout bij laden team data: $e')),
        );
      }
    }
  }

  void _filterMembers() {
    List<Map<String, dynamic>> filtered = List.from(_teamMembers);
    
    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((member) {
        final name = (member['name'] ?? '').toLowerCase();
        final email = (member['email'] ?? '').toLowerCase();
        final query = _searchQuery.toLowerCase();
        return name.contains(query) || email.contains(query);
      }).toList();
    }
    
    // Apply role filter
    if (_filterRole != 'all') {
      filtered = filtered.where((member) {
        return member['role'] == _filterRole;
      }).toList();
    }
    
    // Apply status filter
    if (_filterStatus != 'all') {
      filtered = filtered.where((member) {
        return member['status'] == _filterStatus;
      }).toList();
    }
    
    setState(() {
      _filteredMembers = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Team Beheer'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () => _showInviteDialog(),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'bulk_invite':
                  _showBulkInviteDialog();
                  break;
                case 'export':
                  _exportTeamData();
                  break;
                case 'settings':
                  _showTeamSettings();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'bulk_invite',
                child: ListTile(
                  leading: Icon(Icons.group_add),
                  title: Text('Bulk Uitnodigen'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'export',
                child: ListTile(
                  leading: Icon(Icons.download),
                  title: Text('Exporteren'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: ListTile(
                  leading: Icon(Icons.settings),
                  title: Text('Team Instellingen'),
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
            unselectedLabelColor: AppColors.onPrimary.withOpacity(0.7),
            tabs: [
              Tab(text: 'Team (${_teamMembers.length})'),
              Tab(text: 'Uitnodigingen (${_pendingInvitations.length})'),
              const Tab(text: 'Rollen & Rechten'),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildTeamTab(),
                _buildInvitationsTab(),
                _buildRolesTab(),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showInviteDialog(),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        icon: const Icon(Icons.person_add),
        label: const Text('Uitnodigen'),
      ),
    );
  }

  Widget _buildTeamTab() {
    return Column(
      children: [
        // Search and filter bar
        _buildSearchAndFilter(),
        
        // Team members list
        Expanded(
          child: _filteredMembers.isEmpty
              ? _buildEmptyTeamState()
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredMembers.length,
                    itemBuilder: (context, index) {
                      final member = _filteredMembers[index];
                      return _buildMemberCard(member);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
              hintText: 'Zoek teamleden...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                        _filterMembers();
                      },
                    )
                  : null,
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
              _filterMembers();
            },
          ),
          
          const SizedBox(height: 12),
          
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Role filters
                FilterChip(
                  label: const Text('Alle Rollen'),
                  selected: _filterRole == 'all',
                  onSelected: (selected) {
                    setState(() {
                      _filterRole = 'all';
                    });
                    _filterMembers();
                  },
                  backgroundColor: AppColors.background,
                  selectedColor: AppColors.primary.withOpacity(0.2),
                  checkmarkColor: AppColors.primary,
                ),
                const SizedBox(width: 8),
                
                ..._roleLabels.entries.map((entry) {
                  final isSelected = _filterRole == entry.key;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(entry.value),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _filterRole = selected ? entry.key : 'all';
                        });
                        _filterMembers();
                      },
                      backgroundColor: AppColors.background,
                      selectedColor: _roleColors[entry.key]?.withOpacity(0.2),
                      checkmarkColor: _roleColors[entry.key],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberCard(Map<String, dynamic> member) {
    final role = member['role'] ?? 'viewer';
    final status = member['status'] ?? 'active';
    final isOwner = role == 'owner';
    final isCurrentUser = member['is_current_user'] == true;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showMemberDetails(member),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with avatar and info
              Row(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: _roleColors[role]?.withOpacity(0.2),
                    backgroundImage: member['avatar_url'] != null
                        ? NetworkImage(member['avatar_url'])
                        : null,
                    child: member['avatar_url'] == null
                        ? Text(
                            _getInitials(member['name'] ?? ''),
                            style: TextStyle(
                              color: _roleColors[role],
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // Name and email
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                member['name'] ?? '',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (isCurrentUser)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Jij',
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          member['email'] ?? '',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Actions menu
                  if (!isCurrentUser || !isOwner)
                    PopupMenuButton<String>(
                      onSelected: (value) => _handleMemberAction(value, member),
                      itemBuilder: (context) => [
                        if (!isOwner) ...[
                          const PopupMenuItem(
                            value: 'edit_role',
                            child: ListTile(
                              leading: Icon(Icons.edit),
                              title: Text('Rol Wijzigen'),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'edit_permissions',
                            child: ListTile(
                              leading: Icon(Icons.security),
                              title: Text('Rechten Wijzigen'),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                        const PopupMenuItem(
                          value: 'send_message',
                          child: ListTile(
                            leading: Icon(Icons.message),
                            title: Text('Bericht Sturen'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        if (status == 'active')
                          const PopupMenuItem(
                            value: 'suspend',
                            child: ListTile(
                              leading: Icon(Icons.block, color: Colors.orange),
                              title: Text('Schorsen', style: TextStyle(color: Colors.orange)),
                              contentPadding: EdgeInsets.zero,
                            ),
                          )
                        else
                          const PopupMenuItem(
                            value: 'activate',
                            child: ListTile(
                              leading: Icon(Icons.check_circle, color: Colors.green),
                              title: Text('Activeren', style: TextStyle(color: Colors.green)),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        if (!isOwner)
                          const PopupMenuItem(
                            value: 'remove',
                            child: ListTile(
                              leading: Icon(Icons.person_remove, color: Colors.red),
                              title: Text('Verwijderen', style: TextStyle(color: Colors.red)),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                      ],
                    ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Role and status badges
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _roleColors[role]?.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getRoleIcon(role),
                          size: 14,
                          color: _roleColors[role],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _roleLabels[role] ?? role,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: _roleColors[role],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(width: 8),
                  
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _statusColors[status]?.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: _statusColors[status],
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _statusLabels[status] ?? status,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: _statusColors[status],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // Last seen
                  if (member['last_seen'] != null)
                    Text(
                      'Laatst gezien: ${_formatDateTime(member['last_seen'])}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
              
              // Restaurant access
              if (member['restaurant_access'] != null && member['restaurant_access'].isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Toegang tot restaurants:',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: (member['restaurant_access'] as List).map<Widget>((restaurantId) {
                    final restaurant = _restaurants.firstWhere(
                      (r) => r['id'] == restaurantId,
                      orElse: () => {'name': 'Onbekend Restaurant'},
                    );
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        restaurant['name'] ?? '',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInvitationsTab() {
    return _pendingInvitations.isEmpty
        ? _buildEmptyInvitationsState()
        : RefreshIndicator(
            onRefresh: _loadData,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _pendingInvitations.length,
              itemBuilder: (context, index) {
                final invitation = _pendingInvitations[index];
                return _buildInvitationCard(invitation);
              },
            ),
          );
  }

  Widget _buildInvitationCard(Map<String, dynamic> invitation) {
    final role = invitation['role'] ?? 'viewer';
    final expiresAt = invitation['expires_at'];
    final isExpired = expiresAt != null && DateTime.parse(expiresAt).isBefore(DateTime.now());
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.mail_outline,
                  color: isExpired ? Colors.red : AppColors.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        invitation['email'] ?? '',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Uitgenodigd als ${_roleLabels[role] ?? role}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) => _handleInvitationAction(value, invitation),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'resend',
                      child: ListTile(
                        leading: Icon(Icons.send),
                        title: Text('Opnieuw Versturen'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'copy_link',
                      child: ListTile(
                        leading: Icon(Icons.copy),
                        title: Text('Link Kopiëren'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'cancel',
                      child: ListTile(
                        leading: Icon(Icons.cancel, color: Colors.red),
                        title: Text('Annuleren', style: TextStyle(color: Colors.red)),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Status and expiry
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isExpired 
                        ? Colors.red.withOpacity(0.1)
                        : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isExpired ? 'Verlopen' : 'In afwachting',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: isExpired ? Colors.red : Colors.orange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                
                const Spacer(),
                
                if (expiresAt != null)
                  Text(
                    isExpired 
                        ? 'Verlopen op ${_formatDate(expiresAt)}'
                        : 'Verloopt op ${_formatDate(expiresAt)}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: isExpired ? Colors.red : AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
            
            // Sent info
            if (invitation['sent_at'] != null) ...[
              const SizedBox(height: 8),
              Text(
                'Verstuurd op ${_formatDateTime(invitation['sent_at'])}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRolesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rollen & Rechten Overzicht',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Hieronder vind je een overzicht van alle beschikbare rollen en hun rechten.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Role cards
          ..._roleLabels.entries.map((entry) {
            return _buildRoleCard(entry.key, entry.value);
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildRoleCard(String role, String label) {
    final permissions = _rolePermissions[role] ?? [];
    final color = _roleColors[role] ?? Colors.grey;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Role header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getRoleIcon(role),
                    color: color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      Text(
                        _getRoleDescription(role),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Permissions
            Text(
              'Rechten:',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            
            ...permissions.map((permission) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 16,
                      color: color,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        permission,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyTeamState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.group,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty || _filterRole != 'all' || _filterStatus != 'all'
                  ? 'Geen teamleden gevonden'
                  : 'Nog geen teamleden',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty || _filterRole != 'all' || _filterStatus != 'all'
                  ? 'Probeer een andere zoekopdracht of filter'
                  : 'Nodig je eerste teamlid uit om samen te werken',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (_searchQuery.isEmpty && _filterRole == 'all' && _filterStatus == 'all') ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _showInviteDialog(),
                icon: const Icon(Icons.person_add),
                label: const Text('Eerste Teamlid Uitnodigen'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyInvitationsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.mail_outline,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'Geen Openstaande Uitnodigingen',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Alle uitnodigingen zijn geaccepteerd of verlopen',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showInviteDialog(),
              icon: const Icon(Icons.person_add),
              label: const Text('Nieuw Teamlid Uitnodigen'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showInviteDialog() {
    String selectedRole = 'staff';
    List<String> selectedRestaurants = [];
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Teamlid Uitnodigen'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Email input
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email adres',
                    hintText: 'naam@bedrijf.nl',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                
                const SizedBox(height: 16),
                
                // Role selection
                Text(
                  'Rol:',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                
                ..._roleLabels.entries.where((entry) => entry.key != 'owner').map((entry) {
                  return RadioListTile<String>(
                    title: Text(entry.value),
                    subtitle: Text(_getRoleDescription(entry.key)),
                    value: entry.key,
                    groupValue: selectedRole,
                    onChanged: (value) {
                      setState(() {
                        selectedRole = value!;
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                  );
                }).toList(),
                
                const SizedBox(height: 16),
                
                // Restaurant access
                Text(
                  'Restaurant Toegang:',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                
                ..._restaurants.map((restaurant) {
                  final isSelected = selectedRestaurants.contains(restaurant['id']);
                  return CheckboxListTile(
                    title: Text(restaurant['name'] ?? ''),
                    value: isSelected,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          selectedRestaurants.add(restaurant['id']);
                        } else {
                          selectedRestaurants.remove(restaurant['id']);
                        }
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                  );
                }).toList(),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _emailController.clear();
                Navigator.pop(context);
              },
              child: const Text('Annuleren'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_emailController.text.isNotEmpty) {
                  Navigator.pop(context);
                  _sendInvitation(
                    _emailController.text,
                    selectedRole,
                    selectedRestaurants,
                  );
                  _emailController.clear();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
              ),
              child: const Text('Uitnodigen'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendInvitation(String email, String role, List<String> restaurantAccess) async {
    try {
      await _apiService.inviteTeamMember({
        'email': email,
        'role': role,
        'restaurant_access': restaurantAccess,
      });
      
      await _loadData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Uitnodiging verstuurd naar $email'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fout bij versturen uitnodiging: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showMemberDetails(Map<String, dynamic> member) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(member['name'] ?? ''),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Email: ${member['email'] ?? ''}'),
              const SizedBox(height: 8),
              Text('Rol: ${_roleLabels[member['role']] ?? member['role']}'),
              const SizedBox(height: 8),
              Text('Status: ${_statusLabels[member['status']] ?? member['status']}'),
              if (member['last_seen'] != null) ...[
                const SizedBox(height: 8),
                Text('Laatst gezien: ${_formatDateTime(member['last_seen'])}'),
              ],
              if (member['joined_at'] != null) ...[
                const SizedBox(height: 8),
                Text('Lid sinds: ${_formatDate(member['joined_at'])}'),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Sluiten'),
          ),
        ],
      ),
    );
  }

  void _handleMemberAction(String action, Map<String, dynamic> member) {
    switch (action) {
      case 'edit_role':
        _showEditRoleDialog(member);
        break;
      case 'edit_permissions':
        _showEditPermissionsDialog(member);
        break;
      case 'send_message':
        _sendMessage(member);
        break;
      case 'suspend':
        _suspendMember(member);
        break;
      case 'activate':
        _activateMember(member);
        break;
      case 'remove':
        _removeMember(member);
        break;
    }
  }

  void _handleInvitationAction(String action, Map<String, dynamic> invitation) {
    switch (action) {
      case 'resend':
        _resendInvitation(invitation);
        break;
      case 'copy_link':
        _copyInvitationLink(invitation);
        break;
      case 'cancel':
        _cancelInvitation(invitation);
        break;
    }
  }

  void _showEditRoleDialog(Map<String, dynamic> member) {
    String currentRole = member['role'] ?? 'viewer';
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Rol wijzigen voor ${member['name']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: _roleLabels.entries.where((entry) => entry.key != 'owner').map((entry) {
              return RadioListTile<String>(
                title: Text(entry.value),
                subtitle: Text(_getRoleDescription(entry.key)),
                value: entry.key,
                groupValue: currentRole,
                onChanged: (value) {
                  setState(() {
                    currentRole = value!;
                  });
                },
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuleren'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _updateMemberRole(member, currentRole);
              },
              child: const Text('Opslaan'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditPermissionsDialog(Map<String, dynamic> member) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Rechten voor ${member['name']}'),
        content: const Text('Aangepaste rechten functionaliteit wordt binnenkort toegevoegd'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateMemberRole(Map<String, dynamic> member, String newRole) async {
    try {
      await _apiService.updateTeamMemberRole(member['id'], newRole);
      await _loadData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rol van ${member['name']} gewijzigd naar ${_roleLabels[newRole]}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fout bij wijzigen rol: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _sendMessage(Map<String, dynamic> member) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Bericht functionaliteit naar ${member['name']} wordt binnenkort toegevoegd'),
      ),
    );
  }

  Future<void> _suspendMember(Map<String, dynamic> member) async {
    try {
      await _apiService.suspendTeamMember(member['id']);
      await _loadData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${member['name']} is geschorst'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fout bij schorsen: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _activateMember(Map<String, dynamic> member) async {
    try {
      await _apiService.activateTeamMember(member['id']);
      await _loadData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${member['name']} is geactiveerd'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fout bij activeren: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _removeMember(Map<String, dynamic> member) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Teamlid Verwijderen'),
        content: Text('Weet je zeker dat je ${member['name']} uit het team wilt verwijderen? Deze actie kan niet ongedaan worden gemaakt.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuleren'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _apiService.removeTeamMember(member['id']);
                await _loadData();
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${member['name']} is verwijderd uit het team'),
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

  Future<void> _resendInvitation(Map<String, dynamic> invitation) async {
    try {
      await _apiService.resendInvitation(invitation['id']);
      await _loadData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Uitnodiging opnieuw verstuurd naar ${invitation['email']}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fout bij opnieuw versturen: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _copyInvitationLink(Map<String, dynamic> invitation) async {
    try {
      final link = invitation['invitation_link'] ?? 'https://menutri.app/invite/${invitation['token']}';
      await Clipboard.setData(ClipboardData(text: link));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Uitnodigingslink gekopieerd naar klembord'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fout bij kopiëren link: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _cancelInvitation(Map<String, dynamic> invitation) async {
    try {
      await _apiService.cancelInvitation(invitation['id']);
      await _loadData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Uitnodiging naar ${invitation['email']} geannuleerd'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fout bij annuleren uitnodiging: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showBulkInviteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bulk Uitnodigen'),
        content: const Text('Bulk uitnodiging functionaliteit wordt binnenkort toegevoegd'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _exportTeamData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Export functionaliteit wordt binnenkort toegevoegd'),
      ),
    );
  }

  void _showTeamSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Team Instellingen'),
        content: const Text('Team instellingen worden binnenkort toegevoegd'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'owner':
        return Icons.crown;
      case 'admin':
        return Icons.admin_panel_settings;
      case 'manager':
        return Icons.manage_accounts;
      case 'staff':
        return Icons.person;
      case 'viewer':
        return Icons.visibility;
      default:
        return Icons.person;
    }
  }

  String _getRoleDescription(String role) {
    switch (role) {
      case 'owner':
        return 'Volledige controle over het account';
      case 'admin':
        return 'Kan team en restaurants beheren';
      case 'manager':
        return 'Kan menu\'s en content beheren';
      case 'staff':
        return 'Kan menu\'s bewerken en bekijken';
      case 'viewer':
        return 'Kan alleen informatie bekijken';
      default:
        return 'Onbekende rol';
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

  String _formatDate(String? dateTime) {
    if (dateTime == null) return '';
    
    try {
      final date = DateTime.parse(dateTime);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateTime;
    }
  }
}

