import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/api_service.dart';

class CateraarHelpSupportPage extends ConsumerStatefulWidget {
  const CateraarHelpSupportPage({super.key});

  @override
  ConsumerState<CateraarHelpSupportPage> createState() =>
      _CateraarHelpSupportPageState();
}

class _CateraarHelpSupportPageState
    extends ConsumerState<CateraarHelpSupportPage>
    with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();

  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _feedbackController = TextEditingController();
  final TextEditingController _ticketTitleController = TextEditingController();
  final TextEditingController _ticketDescriptionController =
      TextEditingController();

  bool _isLoading = true;
  bool _isSubmittingFeedback = false;
  List<Map<String, dynamic>> _faqItems = [];
  List<Map<String, dynamic>> _filteredFaqItems = [];
  final List<Map<String, dynamic>> _supportTickets = [];
  String _selectedCategory = 'all';

  final List<Map<String, dynamic>> _helpCategories = [
    {'id': 'all', 'name': 'Alle', 'icon': Icons.help_outline},
    {'id': 'getting_started', 'name': 'Aan de slag', 'icon': Icons.play_arrow},
    {'id': 'restaurants', 'name': 'Restaurants', 'icon': Icons.restaurant},
    {'id': 'menus', 'name': 'Menu\'s', 'icon': Icons.restaurant},
    {'id': 'analytics', 'name': 'Analytics', 'icon': Icons.analytics},
    {'id': 'team', 'name': 'Team', 'icon': Icons.group},
    {'id': 'billing', 'name': 'Facturering', 'icon': Icons.payment},
    {'id': 'technical', 'name': 'Technisch', 'icon': Icons.build},
    {'id': 'account', 'name': 'Account', 'icon': Icons.account_circle},
  ];

  final List<Map<String, dynamic>> _contactOptions = [
    {
      'title': 'Live Chat',
      'subtitle': 'Chat direct met ons support team',
      'icon': Icons.chat,
      'color': Colors.green,
      'action': 'chat',
      'available': true,
    },
    {
      'title': 'Email Support',
      'subtitle': 'support@menutri.nl',
      'icon': Icons.email,
      'color': Colors.blue,
      'action': 'email',
      'available': true,
    },
    {
      'title': 'Telefoon Support',
      'subtitle': '+31 20 123 4567',
      'icon': Icons.phone,
      'color': Colors.orange,
      'action': 'phone',
      'available': true,
    },
    {
      'title': 'WhatsApp',
      'subtitle': 'Chat via WhatsApp',
      'icon': Icons.message,
      'color': Colors.green,
      'action': 'whatsapp',
      'available': true,
    },
    {
      'title': 'Video Call',
      'subtitle': 'Persoonlijke ondersteuning',
      'icon': Icons.video_call,
      'color': Colors.purple,
      'action': 'video',
      'available': false,
    },
    {
      'title': 'Remote Support',
      'subtitle': 'Scherm delen voor hulp',
      'icon': Icons.screen_share,
      'color': Colors.red,
      'action': 'remote',
      'available': false,
    },
  ];

  final List<Map<String, dynamic>> _quickActions = [
    {
      'title': 'Account Activeren',
      'subtitle': 'Activeer je Cateraar account',
      'icon': Icons.verified_user,
      'action': 'activate_account',
    },
    {
      'title': 'Restaurant Toevoegen',
      'subtitle': 'Voeg je eerste restaurant toe',
      'icon': Icons.add_business,
      'action': 'add_restaurant',
    },
    {
      'title': 'Menu Uploaden',
      'subtitle': 'Upload je menu items',
      'icon': Icons.upload_file,
      'action': 'upload_menu',
    },
    {
      'title': 'QR Code Genereren',
      'subtitle': 'Maak QR codes voor je menu\'s',
      'icon': Icons.qr_code,
      'action': 'generate_qr',
    },
    {
      'title': 'Team Uitnodigen',
      'subtitle': 'Nodig teamleden uit',
      'icon': Icons.person_add,
      'action': 'invite_team',
    },
    {
      'title': 'Analytics Bekijken',
      'subtitle': 'Bekijk je restaurant statistieken',
      'icon': Icons.bar_chart,
      'action': 'view_analytics',
    },
  ];

  final List<Map<String, dynamic>> _tutorials = [
    {
      'title': 'Aan de slag met Menutri',
      'duration': '5 min',
      'thumbnail': 'assets/images/tutorial_1.jpg',
      'description': 'Leer de basis van het Menutri platform',
      'url': 'https://youtube.com/watch?v=tutorial1',
    },
    {
      'title': 'Restaurant Profiel Instellen',
      'duration': '8 min',
      'thumbnail': 'assets/images/tutorial_2.jpg',
      'description': 'Stel je restaurant profiel correct in',
      'url': 'https://youtube.com/watch?v=tutorial2',
    },
    {
      'title': 'Menu\'s Beheren',
      'duration': '12 min',
      'thumbnail': 'assets/images/tutorial_3.jpg',
      'description': 'Leer hoe je menu\'s en items beheert',
      'url': 'https://youtube.com/watch?v=tutorial3',
    },
    {
      'title': 'QR Codes Gebruiken',
      'duration': '6 min',
      'thumbnail': 'assets/images/tutorial_4.jpg',
      'description': 'Genereer en gebruik QR codes effectief',
      'url': 'https://youtube.com/watch?v=tutorial4',
    },
    {
      'title': 'Analytics Interpreteren',
      'duration': '10 min',
      'thumbnail': 'assets/images/tutorial_5.jpg',
      'description': 'Begrijp je restaurant analytics',
      'url': 'https://youtube.com/watch?v=tutorial5',
    },
    {
      'title': 'Team Beheer',
      'duration': '7 min',
      'thumbnail': 'assets/images/tutorial_6.jpg',
      'description': 'Beheer je team effectief',
      'url': 'https://youtube.com/watch?v=tutorial6',
    },
  ];

  @override
  void initState() {
    super.initState();
    // Tabs initialiseren
    _tabController = TabController(length: 5, vsync: this);
    // FAQ lokaal laden (fallback zonder backend)
    _faqItems = _getDefaultFaqItems();
    _filteredFaqItems = List<Map<String, dynamic>>.from(_faqItems);
    _isLoading = false;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _feedbackController.dispose();
    _ticketTitleController.dispose();
    _ticketDescriptionController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _getDefaultFaqItems() {
    return [
      {
        'id': '1',
        'category': 'getting_started',
        'question': 'Hoe begin ik met Menutri?',
        'answer':
            'Start door je restaurant profiel in te stellen, upload je menu items, en genereer QR codes voor je tafels. Bekijk onze getting started tutorial voor een complete gids.',
        'helpful': 0,
        'not_helpful': 0,
      },
      {
        'id': '2',
        'category': 'restaurants',
        'question': 'Kan ik meerdere restaurants beheren?',
        'answer':
            'Ja, je kunt meerdere restaurants toevoegen en beheren vanuit één account. Elk restaurant heeft zijn eigen menu\'s, analytics en instellingen.',
        'helpful': 0,
        'not_helpful': 0,
      },
      {
        'id': '3',
        'category': 'menus',
        'question': 'Hoe upload ik mijn menu items?',
        'answer':
            'Ga naar Menu Beheer, klik op "Item Toevoegen", vul de details in inclusief naam, beschrijving, prijs en voedingswaarden. Je kunt ook foto\'s toevoegen.',
        'helpful': 0,
        'not_helpful': 0,
      },
      {
        'id': '4',
        'category': 'analytics',
        'question': 'Welke analytics zijn beschikbaar?',
        'answer':
            'Je krijgt inzicht in QR code scans, populaire menu items, piekuren, klanttevredenheid en veel meer. Data kan geëxporteerd worden naar CSV.',
        'helpful': 0,
        'not_helpful': 0,
      },
      {
        'id': '5',
        'category': 'team',
        'question': 'Hoe nodig ik teamleden uit?',
        'answer':
            'Ga naar Team Beheer, klik op "Uitnodigen", vul het email adres in en selecteer de juiste rol. De uitnodiging wordt automatisch verstuurd.',
        'helpful': 0,
        'not_helpful': 0,
      },
      {
        'id': '6',
        'category': 'billing',
        'question': 'Wat kosten de verschillende abonnementen?',
        'answer':
            'We hebben verschillende abonnementen vanaf €29/maand. Bekijk onze prijspagina voor alle opties en features per abonnement.',
        'helpful': 0,
        'not_helpful': 0,
      },
      {
        'id': '7',
        'category': 'technical',
        'question': 'Mijn QR codes werken niet, wat nu?',
        'answer':
            'Controleer of je QR codes correct gegenereerd zijn en of je restaurant actief is. Probeer de QR code opnieuw te genereren of neem contact op met support.',
        'helpful': 0,
        'not_helpful': 0,
      },
      {
        'id': '8',
        'category': 'account',
        'question': 'Hoe wijzig ik mijn account gegevens?',
        'answer':
            'Ga naar Profiel Beheer waar je je persoonlijke gegevens, bedrijfsinformatie en voorkeuren kunt wijzigen.',
        'helpful': 0,
        'not_helpful': 0,
      },
      {
        'id': '9',
        'category': 'getting_started',
        'question': 'Wat is het verschil tussen Gast en Cateraar?',
        'answer':
            'Gasten kunnen restaurants zoeken en menu\'s bekijken. Cateraars beheren restaurants, menu\'s en krijgen toegang tot analytics en team functies.',
        'helpful': 0,
        'not_helpful': 0,
      },
      {
        'id': '10',
        'category': 'menus',
        'question': 'Kan ik menu items bulksgewijs uploaden?',
        'answer':
            'Ja, je kunt een CSV bestand uploaden met al je menu items. Download eerst onze template om de juiste format te gebruiken.',
        'helpful': 0,
        'not_helpful': 0,
      },
    ];
  }

  void _filterFaqItems() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredFaqItems = _faqItems.where((item) {
        final matchesSearch = query.isEmpty ||
            (item['question'] as String).toLowerCase().contains(query) ||
            (item['answer'] as String).toLowerCase().contains(query);
        final matchesCategory =
            _selectedCategory == 'all' || item['category'] == _selectedCategory;
        return matchesSearch && matchesCategory;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Help & Support'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchDialog(),
            tooltip: 'Zoeken',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'contact_sales':
                  _contactSales();
                  break;
                case 'feature_request':
                  _submitFeatureRequest();
                  break;
                case 'report_bug':
                  _reportBug();
                  break;
                case 'download_guides':
                  _downloadGuides();
                  break;
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'contact_sales',
                child: ListTile(
                  leading: Icon(Icons.business),
                  title: Text('Contact Sales'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'feature_request',
                child: ListTile(
                  leading: Icon(Icons.lightbulb),
                  title: Text('Feature Verzoek'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'report_bug',
                child: ListTile(
                  leading: Icon(Icons.bug_report),
                  title: Text('Bug Melden'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'download_guides',
                child: ListTile(
                  leading: Icon(Icons.download),
                  title: Text('Handleidingen'),
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
            tabs: const [
              Tab(text: 'FAQ'),
              Tab(text: 'Contact'),
              Tab(text: 'Tutorials'),
              Tab(text: 'Tickets'),
              Tab(text: 'Feedback'),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildFaqTab(),
                _buildContactTab(),
                _buildTutorialsTab(),
                _buildTicketsTab(),
                _buildFeedbackTab(),
              ],
            ),
    );
  }

  Widget _buildFaqTab() {
    return Column(
      children: [
        // Search and Filter
        Container(
          padding: const EdgeInsets.all(16),
          color: AppColors.surface,
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Zoek in FAQ...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _filterFaqItems();
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _helpCategories.length,
                  itemBuilder: (context, index) {
                    final category = _helpCategories[index];
                    final isSelected = _selectedCategory == category['id'];

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(category['name']),
                        avatar: Icon(
                          category['icon'],
                          size: 16,
                          color: isSelected
                              ? AppColors.onPrimary
                              : AppColors.primary,
                        ),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedCategory = category['id'];
                          });
                          _filterFaqItems();
                        },
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? AppColors.onPrimary
                              : AppColors.primary,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        // FAQ Items
        Expanded(
          child: _filteredFaqItems.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.help_outline,
                        size: 64,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Geen FAQ items gevonden',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Probeer een andere zoekterm of categorie',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => _tabController.animateTo(1),
                        child: const Text('Contact Support'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _filteredFaqItems.length,
                  itemBuilder: (context, index) {
                    final faq = _filteredFaqItems[index];
                    return _buildFaqItem(faq);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFaqItem(Map<String, dynamic> faq) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(
          faq['question'],
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        leading: Icon(
          _helpCategories.firstWhere(
            (cat) => cat['id'] == faq['category'],
            orElse: () => _helpCategories[0],
          )['icon'],
          color: AppColors.primary,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  faq['answer'],
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Was dit nuttig?'),
                    const SizedBox(width: 16),
                    TextButton.icon(
                      onPressed: () => _markFaqHelpful(faq['id'], true),
                      icon: const Icon(Icons.thumb_up, size: 16),
                      label: Text('Ja (${faq['helpful']})'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.green,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _markFaqHelpful(faq['id'], false),
                      icon: const Icon(Icons.thumb_down, size: 16),
                      label: Text('Nee (${faq['not_helpful']})'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick Actions
          Text(
            'Snelle Acties',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.5,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _quickActions.length,
            itemBuilder: (context, index) {
              final action = _quickActions[index];
              return Card(
                child: InkWell(
                  onTap: () => _performQuickAction(action['action']),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          action['icon'],
                          size: 32,
                          color: AppColors.primary,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          action['title'],
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          action['subtitle'],
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 32),

          // Contact Options
          Text(
            'Contact Opties',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),

          ...(_contactOptions.map((option) => _buildContactOption(option))),

          const SizedBox(height: 32),

          // Business Hours
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Support Tijden',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildBusinessHoursRow('Maandag - Vrijdag', '09:00 - 18:00'),
                  _buildBusinessHoursRow('Zaterdag', '10:00 - 16:00'),
                  _buildBusinessHoursRow('Zondag', 'Gesloten'),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.withAlphaFraction(Colors.blue, 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info,
                          color: Colors.blue,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Voor urgente zaken buiten kantooruren, gebruik WhatsApp of email.',
                            style: TextStyle(
                              color: Colors.blue[800],
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactOption(Map<String, dynamic> option) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.withAlphaFraction(option['color'], 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            option['icon'],
            color: option['color'],
          ),
        ),
        title: Text(
          option['title'],
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(option['subtitle']),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!option['available'])
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.withAlphaFraction(Colors.orange, 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Binnenkort',
                  style: TextStyle(
                    color: Colors.orange[800],
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios),
          ],
        ),
        onTap: option['available']
            ? () => _performContactAction(option['action'])
            : null,
        enabled: option['available'],
      ),
    );
  }

  Widget _buildBusinessHoursRow(String day, String hours) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            day,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(
            hours,
            style: TextStyle(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTutorialsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.play_circle_filled,
                color: AppColors.primary,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Video Tutorials',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      'Leer Menutri kennen met onze stap-voor-stap tutorials',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Tutorial Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 1,
              childAspectRatio: 2.5,
              mainAxisSpacing: 16,
            ),
            itemCount: _tutorials.length,
            itemBuilder: (context, index) {
              final tutorial = _tutorials[index];
              return _buildTutorialCard(tutorial);
            },
          ),

          const SizedBox(height: 32),

          // Additional Resources
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.library_books,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Aanvullende Bronnen',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.description),
                    title: const Text('Gebruikershandleiding'),
                    subtitle: const Text('Complete PDF handleiding'),
                    trailing: const Icon(Icons.download),
                    onTap: () => _downloadUserGuide(),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.api),
                    title: const Text('API Documentatie'),
                    subtitle: const Text('Voor ontwikkelaars'),
                    trailing: const Icon(Icons.open_in_new),
                    onTap: () => _openApiDocs(),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.school),
                    title: const Text('Menutri Academy'),
                    subtitle: const Text('Online cursussen'),
                    trailing: const Icon(Icons.open_in_new),
                    onTap: () => _openAcademy(),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.forum),
                    title: const Text('Community Forum'),
                    subtitle: const Text('Stel vragen aan andere gebruikers'),
                    trailing: const Icon(Icons.open_in_new),
                    onTap: () => _openForum(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTutorialCard(Map<String, dynamic> tutorial) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _playTutorial(tutorial['url']),
        child: Row(
          children: [
            // Thumbnail
            Container(
              width: 120,
              height: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.withAlphaFraction(AppColors.primary, 0.1),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.play_circle_filled,
                    size: 48,
                    color: AppColors.primary,
                  ),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.withAlphaFraction(Colors.black, 0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        tutorial['duration'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      tutorial['title'],
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      tutorial['description'],
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketsTab() {
    return Column(
      children: [
        // In plaats van ticket aanmaken: mail support
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: () => _launchUrl(
                'mailto:support@menutri.nl?subject=Support%20ticket'),
            icon: const Icon(Icons.email),
            label: const Text('Mail Support (support@menutri.nl)'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),

        // Tickets List (optioneel leeg, tot backend bestaat)
        Expanded(
          child: _supportTickets.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.support_agent,
                        size: 64,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Nog geen tickets in het systeem',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Neem contact op via e‑mail: support@menutri.nl',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _supportTickets.length,
                  itemBuilder: (context, index) {
                    final ticket = _supportTickets[index];
                    return _buildTicketCard(ticket);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildTicketCard(Map<String, dynamic> ticket) {
    final status = ticket['status'] ?? 'open';
    final priority = ticket['priority'] ?? 'medium';

    Color statusColor;
    IconData statusIcon;

    switch (status) {
      case 'open':
        statusColor = Colors.blue;
        statusIcon = Icons.help_outline;
        break;
      case 'in_progress':
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_empty;
        break;
      case 'resolved':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'closed':
        statusColor = Colors.grey;
        statusIcon = Icons.close;
        break;
      default:
        statusColor = Colors.blue;
        statusIcon = Icons.help_outline;
    }

    Color priorityColor;
    switch (priority) {
      case 'low':
        priorityColor = Colors.green;
        break;
      case 'medium':
        priorityColor = Colors.orange;
        break;
      case 'high':
        priorityColor = Colors.red;
        break;
      default:
        priorityColor = Colors.orange;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(
          statusIcon,
          color: statusColor,
        ),
        title: Text(
          ticket['title'] ?? 'Support Ticket',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              ticket['description'] ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.withAlphaFraction(statusColor, 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.withAlphaFraction(priorityColor, 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    priority.toUpperCase(),
                    style: TextStyle(
                      color: priorityColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Text(
          ticket['created_at'] ?? 'Nu',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
        onTap: () => _viewTicketDetails(ticket),
      ),
    );
  }

  Widget _buildFeedbackTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.feedback,
                color: AppColors.primary,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Feedback & Suggesties',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      'Help ons Menutri te verbeteren met jouw feedback',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Feedback Form
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Deel je feedback',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _feedbackController,
                    maxLines: 6,
                    decoration: const InputDecoration(
                      hintText:
                          'Vertel ons wat je denkt van Menutri, wat we kunnen verbeteren, of welke features je graag zou willen zien...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed:
                              _isSubmittingFeedback ? null : _submitFeedback,
                          icon: _isSubmittingFeedback
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.send),
                          label: Text(_isSubmittingFeedback
                              ? 'Versturen...'
                              : 'Feedback Versturen'),
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
            ),
          ),

          const SizedBox(height: 24),

          // Quick Feedback Options
          Text(
            'Snelle Feedback',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildQuickFeedbackChip('👍 Geweldig!', 'positive'),
              _buildQuickFeedbackChip('🐛 Bug gevonden', 'bug'),
              _buildQuickFeedbackChip('💡 Feature idee', 'feature'),
              _buildQuickFeedbackChip('📱 UI verbetering', 'ui'),
              _buildQuickFeedbackChip('⚡ Performance', 'performance'),
              _buildQuickFeedbackChip('📚 Documentatie', 'docs'),
            ],
          ),

          const SizedBox(height: 24),

          // App Rating
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Beoordeel Menutri',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Hoe tevreden ben je met Menutri?',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        onPressed: () => _rateApp(index + 1),
                        icon: const Icon(
                          Icons.star,
                          color: Colors.amber,
                          size: 32,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _rateInAppStore(),
                          icon: const Icon(Icons.store),
                          label: const Text('Beoordeel in App Store'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Contact for Feedback
          Card(
            child: ListTile(
              leading: Icon(
                Icons.email,
                color: AppColors.primary,
              ),
              title: const Text('Direct Contact'),
              subtitle: const Text('Stuur feedback direct naar ons team'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => _sendDirectFeedback(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickFeedbackChip(String label, String type) {
    return ActionChip(
      label: Text(label),
      onPressed: () => _sendQuickFeedback(type),
      backgroundColor: AppColors.withAlphaFraction(AppColors.primary, 0.1),
      labelStyle: TextStyle(color: AppColors.primary),
    );
  }

  // Action Methods
  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Zoeken in Help'),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Zoekterm...',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (value) {
            Navigator.pop(context);
            _searchController.text = value;
            _filterFaqItems();
            _tabController.animateTo(0);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuleren'),
          ),
        ],
      ),
    );
  }

  void _markFaqHelpful(String faqId, bool helpful) {
    // Update FAQ helpfulness
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text(helpful ? 'Bedankt voor je feedback!' : 'Feedback ontvangen'),
        backgroundColor: helpful ? Colors.green : Colors.orange,
      ),
    );
  }

  void _performQuickAction(String action) {
    switch (action) {
      case 'activate_account':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Account activatie wordt binnenkort toegevoegd')),
        );
        break;
      case 'add_restaurant':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Restaurant toevoegen wordt binnenkort toegevoegd')),
        );
        break;
      case 'upload_menu':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Menu upload wordt binnenkort toegevoegd')),
        );
        break;
      case 'generate_qr':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('QR code generatie wordt binnenkort toegevoegd')),
        );
        break;
      case 'invite_team':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Team uitnodigen wordt binnenkort toegevoegd')),
        );
        break;
      case 'view_analytics':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Analytics bekijken wordt binnenkort toegevoegd')),
        );
        break;
    }
  }

  void _performContactAction(String action) {
    switch (action) {
      case 'chat':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Live chat wordt binnenkort toegevoegd')),
        );
        break;
      case 'email':
        _launchUrl('mailto:support@menutri.nl');
        break;
      case 'phone':
        _launchUrl('tel:+31201234567');
        break;
      case 'whatsapp':
        _launchUrl('https://wa.me/31201234567');
        break;
      case 'video':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Video call wordt binnenkort toegevoegd')),
        );
        break;
      case 'remote':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Remote support wordt binnenkort toegevoegd')),
        );
        break;
    }
  }

  void _playTutorial(String url) {
    _launchUrl(url);
  }

  void _downloadUserGuide() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text(
              'Gebruikershandleiding download wordt binnenkort toegevoegd')),
    );
  }

  void _openApiDocs() {
    _launchUrl('https://docs.menutri.com/api');
  }

  void _openAcademy() {
    _launchUrl('https://academy.menutri.com');
  }

  void _openForum() {
    _launchUrl('https://community.menutri.com');
  }

  // _showCreateTicketDialog en _createSupportTicket zijn verwijderd i.v.m. geen backend API.
  // Tickets-tab verwijst nu naar e-mail (support@menutri.nl).

  void _viewTicketDetails(Map<String, dynamic> ticket) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(ticket['title'] ?? 'Support Ticket'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status: ${ticket['status'] ?? 'open'}'),
            Text('Prioriteit: ${ticket['priority'] ?? 'medium'}'),
            Text('Categorie: ${ticket['category'] ?? 'general'}'),
            const SizedBox(height: 16),
            Text(ticket['description'] ?? ''),
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

  void _submitFeedback() async {
    if (_feedbackController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vul je feedback in'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmittingFeedback = true);

    try {
      await _apiService.submitFeedback({
        'feedback': _feedbackController.text,
        'type': 'general',
      } as String);

      _feedbackController.clear();

      setState(() => _isSubmittingFeedback = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bedankt voor je feedback!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() => _isSubmittingFeedback = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fout bij versturen feedback: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _sendQuickFeedback(String type) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$type feedback verzonden!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _rateApp(int rating) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Bedankt voor je $rating sterren beoordeling!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _rateInAppStore() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('App Store beoordeling wordt binnenkort toegevoegd')),
    );
  }

  void _sendDirectFeedback() {
    _launchUrl('mailto:feedback@menutri.com?subject=Feedback%20van%20Cateraar');
  }

  void _contactSales() {
    _launchUrl('mailto:sales@menutri.com');
  }

  void _submitFeatureRequest() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Feature verzoek wordt binnenkort toegevoegd')),
    );
  }

  void _reportBug() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Bug rapportage wordt binnenkort toegevoegd')),
    );
  }

  void _downloadGuides() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Handleidingen download wordt binnenkort toegevoegd')),
    );
  }

  Future<void> _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kan $url niet openen'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
