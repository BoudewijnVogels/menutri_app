import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';

class HelpPage extends ConsumerStatefulWidget {
  const HelpPage({super.key});

  @override
  ConsumerState<HelpPage> createState() => _HelpPageState();
}

class _HelpPageState extends ConsumerState<HelpPage> with TickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  final List<FAQItem> _faqItems = [
    FAQItem(
      category: 'Account',
      question: 'Hoe maak ik een account aan?',
      answer: 'Je kunt een account aanmaken door op "Registreren" te tikken op het inlogscherm. Vul je e-mailadres, naam en wachtwoord in. Je ontvangt een bevestigingsmail om je account te activeren.',
    ),
    FAQItem(
      category: 'Account',
      question: 'Ik ben mijn wachtwoord vergeten',
      answer: 'Tik op "Wachtwoord vergeten?" op het inlogscherm. Voer je e-mailadres in en je ontvangt een link om je wachtwoord opnieuw in te stellen.',
    ),
    FAQItem(
      category: 'Account',
      question: 'Hoe wijzig ik mijn profiel?',
      answer: 'Ga naar je profiel en tik op "Profiel bewerken". Hier kun je je naam, foto en taalvoorkeur wijzigen.',
    ),
    FAQItem(
      category: 'Restaurants',
      question: 'Hoe vind ik restaurants in de buurt?',
      answer: 'Gebruik de zoekfunctie of kaart om restaurants in je omgeving te vinden. Je kunt filteren op keuken, prijs en dieetvoorkeuren.',
    ),
    FAQItem(
      category: 'Restaurants',
      question: 'Hoe scan ik een QR-code?',
      answer: 'Tik op de QR-scanner in de app. Richt je camera op de QR-code van het restaurant om direct het menu te bekijken.',
    ),
    FAQItem(
      category: 'Restaurants',
      question: 'Hoe voeg ik restaurants toe aan mijn favorieten?',
      answer: 'Tik op het hartje bij een restaurant of gerecht om het toe te voegen aan je favorieten. Je kunt ook collecties maken om je favorieten te organiseren.',
    ),
    FAQItem(
      category: 'Voeding',
      question: 'Hoe log ik mijn maaltijden?',
      answer: 'Ga naar het voedingslogboek en tik op de + knop. Selecteer het maaltijdtype en voer de voedingsinformatie in.',
    ),
    FAQItem(
      category: 'Voeding',
      question: 'Hoe stel ik mijn voedingsdoelen in?',
      answer: 'Ga naar je gezondheidsprofiel en vul je lengte, gewicht en activiteitsniveau in. De app berekent automatisch je dagelijkse calorie- en macronutriëntendoelen.',
    ),
    FAQItem(
      category: 'Voeding',
      question: 'Wat betekenen de calorie-marges?',
      answer: 'Calorie-marges geven aan hoe goed een gerecht past bij je dagelijkse doelen:\n• Grijs (≤5%): Uitstekend\n• Geel (5-10%): Goed\n• Oranje (10-15%): Matig\n• Rood (>15%): Hoog',
    ),
    FAQItem(
      category: 'Technisch',
      question: 'De app werkt traag of crasht',
      answer: 'Probeer de app opnieuw te starten. Als het probleem aanhoudt, controleer of je de nieuwste versie hebt geïnstalleerd. Herstart je telefoon indien nodig.',
    ),
    FAQItem(
      category: 'Technisch',
      question: 'Ik krijg geen notificaties',
      answer: 'Controleer of notificaties zijn ingeschakeld in je telefooninstellingen en in de app. Ga naar Profiel > Instellingen > Notificaties.',
    ),
    FAQItem(
      category: 'Privacy',
      question: 'Hoe wordt mijn data gebruikt?',
      answer: 'We gebruiken je gegevens alleen om de app te verbeteren en gepersonaliseerde aanbevelingen te doen. Lees ons privacybeleid voor meer details.',
    ),
    FAQItem(
      category: 'Privacy',
      question: 'Kan ik mijn data exporteren?',
      answer: 'Ja, je kunt je gegevens exporteren door contact op te nemen met ons support team. We sturen je binnen 30 dagen een kopie van al je data.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
        backgroundColor: AppColors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.mediumBrown,
          unselectedLabelColor: AppColors.grey,
          indicatorColor: AppColors.mediumBrown,
          tabs: const [
            Tab(text: 'FAQ'),
            Tab(text: 'Contact'),
            Tab(text: 'Over'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFAQTab(),
          _buildContactTab(),
          _buildAboutTab(),
        ],
      ),
    );
  }

  Widget _buildFAQTab() {
    final filteredFAQs = _faqItems.where((faq) {
      if (_searchQuery.isEmpty) return true;
      return faq.question.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             faq.answer.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             faq.category.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    final categories = _faqItems.map((faq) => faq.category).toSet().toList();

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Zoek in veelgestelde vragen...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
              border: const OutlineInputBorder(),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
        ),

        // Category chips
        if (_searchQuery.isEmpty) ...[
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(category),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _searchQuery = category;
                          _searchController.text = category;
                        });
                      }
                    },
                  ),
                );
              },
            ),
          ),
        ],

        // FAQ list
        Expanded(
          child: filteredFAQs.isEmpty
              ? _buildEmptySearchState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredFAQs.length,
                  itemBuilder: (context, index) {
                    final faq = filteredFAQs[index];
                    return _buildFAQItem(faq);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFAQItem(FAQItem faq) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        title: Text(
          faq.question,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          faq.category,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.mediumBrown,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              faq.answer,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySearchState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, size: 64, color: AppColors.grey),
          const SizedBox(height: 16),
          Text(
            'Geen resultaten gevonden',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Probeer een andere zoekterm',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.grey,
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
          // Contact header
          Text(
            'Neem contact met ons op',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            'We helpen je graag verder! Kies de manier die het beste bij je past.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.grey,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Contact methods
          _buildContactMethod(
            icon: Icons.email,
            title: 'E-mail support',
            subtitle: 'support@menutri.app',
            description: 'Stuur ons een e-mail voor uitgebreide vragen',
            onTap: () => _launchEmail('support@menutri.app'),
          ),
          
          const SizedBox(height: 16),
          
          _buildContactMethod(
            icon: Icons.chat,
            title: 'Live chat',
            subtitle: 'Ma-Vr 9:00-17:00',
            description: 'Chat direct met ons support team',
            onTap: _openLiveChat,
          ),
          
          const SizedBox(height: 16),
          
          _buildContactMethod(
            icon: Icons.phone,
            title: 'Telefoon',
            subtitle: '+31 20 123 4567',
            description: 'Bel ons voor urgente vragen',
            onTap: () => _launchPhone('+31201234567'),
          ),
          
          const SizedBox(height: 32),
          
          // Social media
          Text(
            'Volg ons',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              _buildSocialButton(
                icon: Icons.facebook,
                label: 'Facebook',
                onTap: () => _launchURL('https://facebook.com/menutri'),
              ),
              const SizedBox(width: 16),
              _buildSocialButton(
                icon: Icons.alternate_email,
                label: 'Twitter',
                onTap: () => _launchURL('https://twitter.com/menutri'),
              ),
              const SizedBox(width: 16),
              _buildSocialButton(
                icon: Icons.camera_alt,
                label: 'Instagram',
                onTap: () => _launchURL('https://instagram.com/menutri'),
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Feedback section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.lightBrown.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.feedback, color: AppColors.mediumBrown),
                    const SizedBox(width: 8),
                    Text(
                      'Feedback geven',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Help ons de app te verbeteren door je feedback te delen. Elke suggestie is welkom!',
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _sendFeedback,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.mediumBrown,
                  ),
                  child: const Text('Feedback versturen'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactMethod({
    required IconData icon,
    required String title,
    required String subtitle,
    required String description,
    required VoidCallback onTap,
  }) {
    return Card(
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.mediumBrown.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.mediumBrown),
        ),
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.mediumBrown,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(description),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.mediumBrown,
        ),
      ),
    );
  }

  Widget _buildAboutTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // App info
          Center(
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.mediumBrown,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.restaurant_menu,
                    size: 40,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Menutri',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Versie 1.0.0',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.grey,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // About text
          Text(
            'Over Menutri',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 16),
          
          const Text(
            'Menutri helpt je gezondere keuzes te maken bij het eten. '
            'Ontdek restaurants, bekijk voedingsinformatie en houd je voedingsdoelen bij. '
            'Onze missie is om gezond eten toegankelijk en leuk te maken voor iedereen.',
          ),
          
          const SizedBox(height: 24),
          
          // Features
          Text(
            'Functies',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 16),
          
          _buildFeatureItem('🍽️', 'Restaurant ontdekking', 'Vind restaurants in je buurt'),
          _buildFeatureItem('📱', 'QR-code scanner', 'Scan menu\'s direct'),
          _buildFeatureItem('📊', 'Voedingslogboek', 'Houd je maaltijden bij'),
          _buildFeatureItem('🎯', 'Persoonlijke doelen', 'Stel je eigen doelen in'),
          _buildFeatureItem('❤️', 'Favorieten', 'Bewaar je favoriete gerechten'),
          
          const SizedBox(height: 24),
          
          // Legal links
          Text(
            'Juridisch',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 16),
          
          _buildLegalLink('Privacybeleid', () => _launchURL('https://menutri.app/privacy')),
          _buildLegalLink('Gebruiksvoorwaarden', () => _launchURL('https://menutri.app/terms')),
          _buildLegalLink('Licenties', () => _showLicenses()),
          
          const SizedBox(height: 24),
          
          // Company info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.lightGrey,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Menutri B.V.',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                const Text('KvK: 12345678'),
                const Text('BTW: NL123456789B01'),
                const Text('Amsterdam, Nederland'),
                const SizedBox(height: 8),
                const Text('© 2024 Menutri. Alle rechten voorbehouden.'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String emoji, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegalLink(String title, VoidCallback onTap) {
    return ListTile(
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }

  Future<void> _launchEmail(String email) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=Menutri Support',
    );
    
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kon e-mail app niet openen'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _launchPhone(String phone) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phone);
    
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kon telefoon app niet openen'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kon link niet openen'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _openLiveChat() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Live Chat'),
        content: const Text(
          'Live chat is momenteel niet beschikbaar. '
          'Stuur ons een e-mail voor snelle ondersteuning.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Sluiten'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _launchEmail('support@menutri.app');
            },
            child: const Text('E-mail versturen'),
          ),
        ],
      ),
    );
  }

  void _sendFeedback() {
    showDialog(
      context: context,
      builder: (context) => _FeedbackDialog(),
    );
  }

  void _showLicenses() {
    showLicensePage(
      context: context,
      applicationName: 'Menutri',
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.mediumBrown,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.restaurant_menu,
          color: AppColors.white,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}

class FAQItem {
  final String category;
  final String question;
  final String answer;

  FAQItem({
    required this.category,
    required this.question,
    required this.answer,
  });
}

class _FeedbackDialog extends StatefulWidget {
  @override
  State<_FeedbackDialog> createState() => _FeedbackDialogState();
}

class _FeedbackDialogState extends State<_FeedbackDialog> {
  final _formKey = GlobalKey<FormState>();
  final _feedbackController = TextEditingController();
  String _feedbackType = 'Suggestie';
  bool _isSending = false;

  final List<String> _feedbackTypes = [
    'Suggestie',
    'Bug report',
    'Compliment',
    'Klacht',
    'Andere',
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Feedback versturen'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _feedbackType,
              decoration: const InputDecoration(
                labelText: 'Type feedback',
                border: OutlineInputBorder(),
              ),
              items: _feedbackTypes.map((type) {
                return DropdownMenuItem(value: type, child: Text(type));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _feedbackType = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _feedbackController,
              decoration: const InputDecoration(
                labelText: 'Je feedback',
                border: OutlineInputBorder(),
                hintText: 'Vertel ons wat je denkt...',
              ),
              maxLines: 4,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Voer je feedback in';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuleren'),
        ),
        ElevatedButton(
          onPressed: _isSending ? null : _sendFeedback,
          child: _isSending
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Versturen'),
        ),
      ],
    );
  }

  Future<void> _sendFeedback() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSending = true;
    });

    // Simulate sending feedback
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bedankt voor je feedback!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }
}

