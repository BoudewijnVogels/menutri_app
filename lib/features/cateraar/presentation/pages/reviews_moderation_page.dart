import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/api_service.dart';

class ReviewsModerationPage extends ConsumerStatefulWidget {
  const ReviewsModerationPage({super.key});

  @override
  ConsumerState<ReviewsModerationPage> createState() =>
      _ReviewsModerationPageState();
}

class _ReviewsModerationPageState extends ConsumerState<ReviewsModerationPage>
    with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _responseController = TextEditingController();

  late TabController _tabController;

  bool _isLoading = true;
  List<Map<String, dynamic>> _reviews = [];
  List<Map<String, dynamic>> _filteredReviews = [];
  List<Map<String, dynamic>> _restaurants = [];
  String _searchQuery = '';
  String _filterStatus = 'all';
  String _filterRating = 'all';
  String? _selectedRestaurant;
  String _sortBy = 'created_at';
  bool _sortAscending = false;

  final Map<String, String> _statusLabels = {
    'all': 'Alle Reviews',
    'pending': 'In afwachting',
    'approved': 'Goedgekeurd',
    'rejected': 'Afgewezen',
    'flagged': 'Gemeld',
    'responded': 'Beantwoord',
    'archived': 'Gearchiveerd',
  };

  final Map<String, Color> _statusColors = {
    'pending': Colors.orange,
    'approved': Colors.green,
    'rejected': Colors.red,
    'flagged': Colors.purple,
    'responded': Colors.blue,
    'archived': Colors.grey,
  };

  final Map<String, String> _sortOptions = {
    'created_at': 'Datum',
    'rating': 'Beoordeling',
    'restaurant_name': 'Restaurant',
    'user_name': 'Gebruiker',
    'response_count': 'Reacties',
  };

  final Map<String, String> _ratingFilters = {
    'all': 'Alle Beoordelingen',
    '5': '5 Sterren',
    '4': '4 Sterren',
    '3': '3 Sterren',
    '2': '2 Sterren',
    '1': '1 Ster',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _responseController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final reviewsResponse = await _apiService.getReviews();
      final restaurantsResponse = await _apiService.getRestaurants();

      final reviews =
          List<Map<String, dynamic>>.from(reviewsResponse['reviews'] ?? []);
      final restaurants = List<Map<String, dynamic>>.from(
          restaurantsResponse['restaurants'] ?? []);

      setState(() {
        _reviews = reviews;
        _restaurants = restaurants;
        _isLoading = false;
      });

      _filterReviews();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fout bij laden reviews: $e')),
        );
      }
    }
  }

  void _filterReviews() {
    List<Map<String, dynamic>> filtered = List.from(_reviews);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((review) {
        final comment = (review['comment'] ?? '').toLowerCase();
        final userName = (review['user_name'] ?? '').toLowerCase();
        final restaurantName = (review['restaurant_name'] ?? '').toLowerCase();
        final query = _searchQuery.toLowerCase();
        return comment.contains(query) ||
            userName.contains(query) ||
            restaurantName.contains(query);
      }).toList();
    }

    // Apply status filter
    if (_filterStatus != 'all') {
      filtered = filtered.where((review) {
        return review['status'] == _filterStatus;
      }).toList();
    }

    // Apply rating filter
    if (_filterRating != 'all') {
      final rating = int.tryParse(_filterRating);
      if (rating != null) {
        filtered = filtered.where((review) {
          return review['rating'] == rating;
        }).toList();
      }
    }

    // Apply restaurant filter
    if (_selectedRestaurant != null) {
      filtered = filtered.where((review) {
        return review['restaurant_id'] == _selectedRestaurant;
      }).toList();
    }

    // Apply sorting
    filtered.sort((a, b) {
      dynamic aValue = a[_sortBy];
      dynamic bValue = b[_sortBy];

      if (_sortBy == 'created_at') {
        aValue = DateTime.tryParse(aValue ?? '') ?? DateTime.now();
        bValue = DateTime.tryParse(bValue ?? '') ?? DateTime.now();
      } else if (_sortBy == 'rating' || _sortBy == 'response_count') {
        aValue = (aValue ?? 0).toInt();
        bValue = (bValue ?? 0).toInt();
      } else {
        aValue = (aValue ?? '').toString().toLowerCase();
        bValue = (bValue ?? '').toString().toLowerCase();
      }

      int comparison = Comparable.compare(aValue, bValue);
      return _sortAscending ? comparison : -comparison;
    });

    setState(() {
      _filteredReviews = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Reviews Moderatie'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: () => _showSortDialog(),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'bulk_approve':
                  _showBulkActionDialog('approve');
                  break;
                case 'bulk_reject':
                  _showBulkActionDialog('reject');
                  break;
                case 'export':
                  _exportReviews();
                  break;
                case 'settings':
                  _showModerationSettings();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'bulk_approve',
                child: ListTile(
                  leading: Icon(Icons.check_circle, color: Colors.green),
                  title: Text('Bulk Goedkeuren'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'bulk_reject',
                child: ListTile(
                  leading: Icon(Icons.cancel, color: Colors.red),
                  title: Text('Bulk Afwijzen'),
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
                  title: Text('Moderatie Instellingen'),
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
            isScrollable: true,
            tabs: [
              Tab(text: 'Alle Reviews (${_reviews.length})'),
              Tab(
                  text:
                      'In Afwachting (${_reviews.where((r) => r['status'] == 'pending').length})'),
              Tab(
                  text:
                      'Gemeld (${_reviews.where((r) => r['status'] == 'flagged').length})'),
              const Tab(text: 'Statistieken'),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildAllReviewsTab(),
                _buildPendingReviewsTab(),
                _buildFlaggedReviewsTab(),
                _buildStatisticsTab(),
              ],
            ),
    );
  }

  Widget _buildAllReviewsTab() {
    return Column(
      children: [
        // Search and filter bar
        _buildSearchAndFilter(),

        // Reviews list
        Expanded(
          child: _filteredReviews.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredReviews.length,
                    itemBuilder: (context, index) {
                      final review = _filteredReviews[index];
                      return _buildReviewCard(review);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildPendingReviewsTab() {
    final pendingReviews =
        _reviews.where((r) => r['status'] == 'pending').toList();

    return pendingReviews.isEmpty
        ? _buildEmptyPendingState()
        : RefreshIndicator(
            onRefresh: _loadData,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: pendingReviews.length,
              itemBuilder: (context, index) {
                final review = pendingReviews[index];
                return _buildReviewCard(review, showQuickActions: true);
              },
            ),
          );
  }

  Widget _buildFlaggedReviewsTab() {
    final flaggedReviews =
        _reviews.where((r) => r['status'] == 'flagged').toList();

    return flaggedReviews.isEmpty
        ? _buildEmptyFlaggedState()
        : RefreshIndicator(
            onRefresh: _loadData,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: flaggedReviews.length,
              itemBuilder: (context, index) {
                final review = flaggedReviews[index];
                return _buildReviewCard(review, showModerationActions: true);
              },
            ),
          );
  }

  Widget _buildStatisticsTab() {
    final totalReviews = _reviews.length;
    final pendingCount = _reviews.where((r) => r['status'] == 'pending').length;
    final approvedCount =
        _reviews.where((r) => r['status'] == 'approved').length;
    final rejectedCount =
        _reviews.where((r) => r['status'] == 'rejected').length;
    final flaggedCount = _reviews.where((r) => r['status'] == 'flagged').length;

    final averageRating = _reviews.isNotEmpty
        ? _reviews.map((r) => r['rating'] ?? 0).reduce((a, b) => a + b) /
            _reviews.length
        : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overview cards
          Text(
            'Reviews Overzicht',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),

          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _buildStatCard('Totaal Reviews', totalReviews.toString(),
                  Icons.rate_review, Colors.blue),
              _buildStatCard('Gemiddelde Rating',
                  averageRating.toStringAsFixed(1), Icons.star, Colors.orange),
              _buildStatCard('In Afwachting', pendingCount.toString(),
                  Icons.hourglass_empty, Colors.orange),
              _buildStatCard('Goedgekeurd', approvedCount.toString(),
                  Icons.check_circle, Colors.green),
              _buildStatCard('Afgewezen', rejectedCount.toString(),
                  Icons.cancel, Colors.red),
              _buildStatCard(
                  'Gemeld', flaggedCount.toString(), Icons.flag, Colors.purple),
            ],
          ),

          const SizedBox(height: 24),

          // Rating distribution
          Text(
            'Rating Verdeling',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),

          ...List.generate(5, (index) {
            final rating = 5 - index;
            final count = _reviews.where((r) => r['rating'] == rating).length;
            final percentage =
                totalReviews > 0 ? (count / totalReviews) * 100 : 0.0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 60,
                    child: Row(
                      children: [
                        Text('$rating'),
                        const SizedBox(width: 4),
                        Icon(Icons.star, size: 16, color: Colors.orange),
                      ],
                    ),
                  ),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: percentage / 100,
                      backgroundColor: Colors.grey.shade300,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        rating >= 4
                            ? Colors.green
                            : rating >= 3
                                ? Colors.orange
                                : Colors.red,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 60,
                    child: Text(
                      '$count (${percentage.toStringAsFixed(1)}%)',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),

          const SizedBox(height: 24),

          // Recent activity
          Text(
            'Recente Activiteit',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),

          ..._reviews.take(5).map((review) {
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      _statusColors[review['status']]?.withOpacity(0.2),
                  child: Icon(
                    _getStatusIcon(review['status']),
                    color: _statusColors[review['status']],
                    size: 20,
                  ),
                ),
                title: Text(review['restaurant_name'] ?? ''),
                subtitle: Text(
                    '${review['user_name']} - ${_formatDateTime(review['created_at'])}'),
                trailing: _buildRatingStars(review['rating'] ?? 0),
              ),
            );
          }).toList(),
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
            color: AppColors.withAlphaFraction(AppColors.black, 0.05),
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
              hintText: 'Zoek reviews, gebruikers, restaurants...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                        _filterReviews();
                      },
                    )
                  : null,
              border: const OutlineInputBorder(),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
              _filterReviews();
            },
          ),

          const SizedBox(height: 12),

          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Status filters
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
                        _filterReviews();
                      },
                      backgroundColor: AppColors.background,
                      selectedColor: _statusColors[entry.key]
                              ?.withOpacity(0.2) ??
                          AppColors.withAlphaFraction(AppColors.primary, 0.2),
                      checkmarkColor:
                          _statusColors[entry.key] ?? AppColors.primary,
                    ),
                  );
                }).toList(),

                const SizedBox(width: 8),

                // Rating filters
                ..._ratingFilters.entries.map((entry) {
                  final isSelected = _filterRating == entry.key;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(entry.value),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _filterRating = selected ? entry.key : 'all';
                        });
                        _filterReviews();
                      },
                      backgroundColor: AppColors.background,
                      selectedColor:
                          AppColors.withAlphaFraction(Colors.orange, 0.2),
                      checkmarkColor: Colors.orange,
                    ),
                  );
                }).toList(),
              ],
            ),
          ),

          // Restaurant filter
          if (_restaurants.isNotEmpty) ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedRestaurant,
              decoration: const InputDecoration(
                labelText: 'Filter op Restaurant',
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('Alle Restaurants'),
                ),
                ..._restaurants.map((restaurant) {
                  return DropdownMenuItem<String>(
                    value: restaurant['id'],
                    child: Text(restaurant['name'] ?? ''),
                  );
                }).toList(),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedRestaurant = value;
                });
                _filterReviews();
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReviewCard(
    Map<String, dynamic> review, {
    bool showQuickActions = false,
    bool showModerationActions = false,
  }) {
    final status = review['status'] ?? 'pending';
    final rating = review['rating'] ?? 0;
    final hasResponse =
        review['response'] != null && review['response'].isNotEmpty;
    final isFlagged = status == 'flagged';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isFlagged
            ? BorderSide(
                color: AppColors.withAlphaFraction(Colors.red, 0.3), width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with user info and rating
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor:
                      AppColors.withAlphaFraction(AppColors.primary, 0.2),
                  backgroundImage: review['user_avatar'] != null
                      ? NetworkImage(review['user_avatar'])
                      : null,
                  child: review['user_avatar'] == null
                      ? Text(
                          _getInitials(review['user_name'] ?? ''),
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              review['user_name'] ?? 'Anonieme Gebruiker',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                          _buildRatingStars(rating),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            review['restaurant_name'] ?? '',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '• ${_formatDateTime(review['created_at'])}',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Status badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColors[status]?.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getStatusIcon(status),
                        size: 14,
                        color: _statusColors[status],
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

                // Actions menu
                PopupMenuButton<String>(
                  onSelected: (value) => _handleReviewAction(value, review),
                  itemBuilder: (context) => [
                    if (status == 'pending') ...[
                      const PopupMenuItem(
                        value: 'approve',
                        child: ListTile(
                          leading:
                              Icon(Icons.check_circle, color: Colors.green),
                          title: Text('Goedkeuren'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'reject',
                        child: ListTile(
                          leading: Icon(Icons.cancel, color: Colors.red),
                          title: Text('Afwijzen'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                    const PopupMenuItem(
                      value: 'respond',
                      child: ListTile(
                        leading: Icon(Icons.reply),
                        title: Text('Reageren'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'flag',
                      child: ListTile(
                        leading: Icon(Icons.flag, color: Colors.orange),
                        title: Text('Markeren'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'hide',
                      child: ListTile(
                        leading: Icon(Icons.visibility_off),
                        title: Text('Verbergen'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(Icons.delete, color: Colors.red),
                        title: Text('Verwijderen',
                            style: TextStyle(color: Colors.red)),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Review comment
            if (review['comment'] != null && review['comment'].isNotEmpty) ...[
              Text(
                review['comment'],
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
            ],

            // Review images
            if (review['images'] != null && review['images'].isNotEmpty) ...[
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: review['images'].length,
                  itemBuilder: (context, index) {
                    return Container(
                      width: 80,
                      height: 80,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: NetworkImage(review['images'][index]),
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Flag reason if flagged
            if (isFlagged && review['flag_reason'] != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.withAlphaFraction(Colors.red, 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: AppColors.withAlphaFraction(Colors.red, 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Gemeld: ${review['flag_reason']}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.red.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Response section
            if (hasResponse) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.withAlphaFraction(AppColors.primary, 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.reply, color: AppColors.primary, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Reactie van ${review['response_author'] ?? 'Restaurant'}',
                          style:
                              Theme.of(context).textTheme.labelMedium?.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        const Spacer(),
                        Text(
                          _formatDateTime(review['response_date']),
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      review['response'],
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Quick actions for pending reviews
            if (showQuickActions && status == 'pending') ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _approveReview(review),
                      icon: const Icon(Icons.check),
                      label: const Text('Goedkeuren'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _rejectReview(review),
                      icon: const Icon(Icons.close),
                      label: const Text('Afwijzen'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],

            // Moderation actions for flagged reviews
            if (showModerationActions && isFlagged) ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _approveReview(review),
                      icon: const Icon(Icons.check),
                      label: const Text('Goedkeuren'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _hideReview(review),
                      icon: const Icon(Icons.visibility_off),
                      label: const Text('Verbergen'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _deleteReview(review),
                      icon: const Icon(Icons.delete),
                      label: const Text('Verwijderen'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRatingStars(int rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star : Icons.star_border,
          color: Colors.orange,
          size: 16,
        );
      }),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.rate_review,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty ||
                      _filterStatus != 'all' ||
                      _filterRating != 'all' ||
                      _selectedRestaurant != null
                  ? 'Geen reviews gevonden'
                  : 'Nog geen reviews',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty ||
                      _filterStatus != 'all' ||
                      _filterRating != 'all' ||
                      _selectedRestaurant != null
                  ? 'Probeer een andere zoekopdracht of filter'
                  : 'Reviews verschijnen hier zodra klanten ze achterlaten',
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

  Widget _buildEmptyPendingState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.hourglass_empty,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'Geen Reviews in Afwachting',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Alle reviews zijn beoordeeld of er zijn nog geen nieuwe reviews',
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

  Widget _buildEmptyFlaggedState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.flag,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'Geen Gemelde Reviews',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Er zijn momenteel geen reviews gemeld door gebruikers',
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

  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sorteren'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ..._sortOptions.entries.map((entry) {
              return RadioListTile<String>(
                title: Text(entry.value),
                value: entry.key,
                groupValue: _sortBy,
                onChanged: (value) {
                  setState(() {
                    _sortBy = value!;
                  });
                  _filterReviews();
                  Navigator.pop(context);
                },
              );
            }),
            const Divider(),
            SwitchListTile(
              title: const Text('Oplopend'),
              subtitle:
                  Text(_sortAscending ? 'Oud naar nieuw' : 'Nieuw naar oud'),
              value: _sortAscending,
              onChanged: (value) {
                setState(() {
                  _sortAscending = value;
                });
                _filterReviews();
                Navigator.pop(context);
              },
            ),
          ],
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

  void _handleReviewAction(String action, Map<String, dynamic> review) {
    switch (action) {
      case 'approve':
        _approveReview(review);
        break;
      case 'reject':
        _rejectReview(review);
        break;
      case 'respond':
        _showResponseDialog(review);
        break;
      case 'hide':
        _hideReview(review);
        break;
      case 'delete':
        _deleteReview(review);
        break;
    }
  }

  Future<void> _approveReview(Map<String, dynamic> review) async {
    try {
      await _apiService.approveReview(review['id']);
      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Review goedgekeurd'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fout bij goedkeuren: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectReview(Map<String, dynamic> review) async {
    try {
      await _apiService.rejectReview(review['id']);
      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Review afgewezen'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fout bij afwijzen: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showResponseDialog(Map<String, dynamic> review) {
    _responseController.clear();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reageren op review van ${review['user_name']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Original review
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildRatingStars(review['rating'] ?? 0),
                  const SizedBox(height: 8),
                  Text(review['comment'] ?? ''),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Response input
            TextField(
              controller: _responseController,
              decoration: const InputDecoration(
                labelText: 'Jouw reactie',
                hintText: 'Bedankt voor je review...',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuleren'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_responseController.text.isNotEmpty) {
                Navigator.pop(context);
                replyToReview(review, _responseController.text);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
            ),
            child: const Text('Versturen'),
          ),
        ],
      ),
    );
  }

  Future<void> replyToReview(
      Map<String, dynamic> review, String response) async {
    try {
      await _apiService.replyToReview(review['id'], response);
      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reactie verstuurd'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fout bij versturen reactie: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _hideReview(Map<String, dynamic> review) async {
    try {
      await _apiService.hideReview(review['id']);
      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Review verborgen'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fout bij verbergen: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _deleteReview(Map<String, dynamic> review) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Review Verwijderen'),
        content: Text(
            'Weet je zeker dat je deze review van ${review['user_name']} wilt verwijderen? Deze actie kan niet ongedaan worden gemaakt.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuleren'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _apiService.deleteReview(review['id']);
                await _loadData();

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Review verwijderd'),
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

  void _showBulkActionDialog(String action) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Bulk ${action == 'approve' ? 'Goedkeuren' : 'Afwijzen'}'),
        content: Text(
            '${action == 'approve' ? 'Goedkeuren' : 'Afwijzen'} functionaliteit wordt binnenkort toegevoegd'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _exportReviews() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Export functionaliteit wordt binnenkort toegevoegd'),
      ),
    );
  }

  void _showModerationSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Moderatie Instellingen'),
        content:
            const Text('Moderatie instellingen worden binnenkort toegevoegd'),
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

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.hourglass_empty;
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'flagged':
        return Icons.flag;
      case 'responded':
        return Icons.reply;
      case 'archived':
        return Icons.archive;
      default:
        return Icons.help;
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
