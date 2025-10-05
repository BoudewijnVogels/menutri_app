import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/api_service.dart';

class QRGeneratorPage extends ConsumerStatefulWidget {
  const QRGeneratorPage({super.key});

  @override
  ConsumerState<QRGeneratorPage> createState() => _QRGeneratorPageState();
}

class _QRGeneratorPageState extends ConsumerState<QRGeneratorPage>
    with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();

  late TabController _tabController;

  bool _isLoading = true;
  bool _isGenerating = false;
  List<Map<String, dynamic>> _restaurants = [];
  List<Map<String, dynamic>> _menus = [];
  Map<String, dynamic>? _selectedRestaurant;
  Map<String, dynamic>? _selectedMenu;
  Map<String, dynamic>? _generatedQR;

  // QR Code customization options
  String _qrType = 'restaurant'; // restaurant, menu, custom
  String _customUrl = '';
  Color _qrColor = Colors.black;
  Color _backgroundColor = Colors.white;
  String _logoPosition = 'center'; // center, none
  double _qrSize = 200.0;
  String _format = 'png'; // png, svg, pdf

  final List<Color> _colorOptions = [
    Colors.black,
    AppColors.primary,
    Colors.blue,
    Colors.green,
    Colors.red,
    Colors.purple,
    Colors.orange,
  ];

  final List<Color> _backgroundOptions = [
    Colors.white,
    Colors.grey.shade100,
    Colors.blue.shade50,
    Colors.green.shade50,
    Colors.red.shade50,
    Colors.purple.shade50,
    Colors.orange.shade50,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final restaurantsResponse = await _apiService.getRestaurants();
      final restaurants = List<Map<String, dynamic>>.from(
          restaurantsResponse['restaurants'] ?? []);

      setState(() {
        _restaurants = restaurants;
        if (restaurants.isNotEmpty) {
          _selectedRestaurant = restaurants.first;
        }
        _isLoading = false;
      });

      if (_selectedRestaurant != null) {
        await _loadMenus();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fout bij laden data: $e')),
        );
      }
    }
  }

  Future<void> _loadMenus() async {
    if (_selectedRestaurant == null) return;

    try {
      final restaurantId = (_selectedRestaurant!['id'] as num).toInt();
      final response = await _apiService.getMenus(restaurantId: restaurantId);
      final menus = List<Map<String, dynamic>>.from(response['menus'] ?? []);

      setState(() {
        _menus = menus;
        if (menus.isNotEmpty) {
          _selectedMenu = menus.first;
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fout bij laden menu\'s: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('QR Code Generator'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
        actions: [
          if (_generatedQR != null)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () => _shareQRCode(),
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
            tabs: const [
              Tab(text: 'Generator'),
              Tab(text: 'Aanpassen'),
              Tab(text: 'Geschiedenis'),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildGeneratorTab(),
                _buildCustomizeTab(),
                _buildHistoryTab(),
              ],
            ),
    );
  }

  Widget _buildGeneratorTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // QR Type Selection
          _buildQRTypeSelection(),

          const SizedBox(height: 24),

          // Content Selection
          _buildContentSelection(),

          const SizedBox(height: 24),

          // QR Preview
          _buildQRPreview(),

          const SizedBox(height: 24),

          // Generate Button
          _buildGenerateButton(),

          if (_generatedQR != null) ...[
            const SizedBox(height: 24),
            _buildQRActions(),
          ],
        ],
      ),
    );
  }

  Widget _buildQRTypeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'QR Code Type',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildTypeCard(
                type: 'restaurant',
                title: 'Restaurant',
                subtitle: 'Link naar restaurant pagina',
                icon: Icons.restaurant,
                isSelected: _qrType == 'restaurant',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTypeCard(
                type: 'menu',
                title: 'Menu',
                subtitle: 'Link naar specifiek menu',
                icon: Icons.menu_book,
                isSelected: _qrType == 'menu',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTypeCard(
                type: 'custom',
                title: 'Custom',
                subtitle: 'Eigen URL',
                icon: Icons.link,
                isSelected: _qrType == 'custom',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTypeCard({
    required String type,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () {
        setState(() {
          _qrType = type;
          _generatedQR = null; // Reset generated QR when type changes
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.withAlphaFraction(AppColors.primary, 0.1)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.outline,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isSelected ? AppColors.primary : null,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
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

  Widget _buildContentSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Content Selectie',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        if (_qrType == 'restaurant') ...[
          // Restaurant selector
          DropdownButtonFormField<Map<String, dynamic>>(
            initialValue: _selectedRestaurant,
            decoration: const InputDecoration(
              labelText: 'Selecteer Restaurant',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.restaurant),
            ),
            items: _restaurants.map((restaurant) {
              return DropdownMenuItem(
                value: restaurant,
                child: Text((restaurant['name'] ?? restaurant['name'] ?? '')
                    .toString()),
              );
            }).toList(),
            onChanged: (restaurant) {
              setState(() {
                _selectedRestaurant = restaurant;
                _generatedQR = null;
              });
              if (restaurant != null) {
                _loadMenus();
              }
            },
          ),
        ] else if (_qrType == 'menu') ...[
          // Restaurant selector
          DropdownButtonFormField<Map<String, dynamic>>(
            initialValue: _selectedRestaurant,
            decoration: const InputDecoration(
              labelText: 'Selecteer Restaurant',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.restaurant),
            ),
            items: _restaurants.map((restaurant) {
              return DropdownMenuItem(
                value: restaurant,
                child: Text((restaurant['name'] ?? restaurant['name'] ?? '')
                    .toString()),
              );
            }).toList(),
            onChanged: (restaurant) {
              setState(() {
                _selectedRestaurant = restaurant;
                _selectedMenu = null;
                _generatedQR = null;
              });
              if (restaurant != null) {
                _loadMenus();
              }
            },
          ),

          const SizedBox(height: 16),

          // Menu selector
          DropdownButtonFormField<Map<String, dynamic>>(
            initialValue: _selectedMenu,
            decoration: const InputDecoration(
              labelText: 'Selecteer Menu',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.menu_book),
            ),
            items: _menus.map((menu) {
              return DropdownMenuItem(
                value: menu,
                child: Text((menu['name'] ?? menu['name'] ?? '').toString()),
              );
            }).toList(),
            onChanged: (menu) {
              setState(() {
                _selectedMenu = menu;
                _generatedQR = null;
              });
            },
          ),
        ] else if (_qrType == 'custom') ...[
          // Custom URL input
          TextFormField(
            initialValue: _customUrl,
            decoration: const InputDecoration(
              labelText: 'Custom URL',
              hintText: 'https://example.com',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.link),
            ),
            onChanged: (value) {
              setState(() {
                _customUrl = value;
                _generatedQR = null;
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Voer een URL in';
              }
              final uri = Uri.tryParse(value);
              if (uri == null || !uri.hasAbsolutePath) {
                return 'Voer een geldige URL in';
              }
              return null;
            },
          ),
        ],
      ],
    );
  }

  Widget _buildQRPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'QR Code Preview',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Container(
            width: _qrSize + 40,
            height: _qrSize + 40,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _backgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.outline),
              boxShadow: [
                BoxShadow(
                  color: AppColors.withAlphaFraction(AppColors.black, 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: _generatedQR != null
                ? Image.network(
                    _generatedQR!['qr_url'],
                    width: _qrSize,
                    height: _qrSize,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildQRPlaceholder();
                    },
                  )
                : _buildQRPlaceholder(),
          ),
        ),
        if (_generatedQR != null) ...[
          const SizedBox(height: 16),
          Center(
            child: Column(
              children: [
                Text(
                  'QR Code URL:',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 4),
                SelectableText(
                  _generatedQR!['target_url'] ?? '',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.primary,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildQRPlaceholder() {
    return Container(
      width: _qrSize,
      height: _qrSize,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.qr_code,
            size: _qrSize * 0.3,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 8),
          Text(
            'QR Code Preview',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenerateButton() {
    final canGenerate =
        _qrType == 'restaurant' && _selectedRestaurant != null ||
            _qrType == 'menu' && _selectedMenu != null ||
            _qrType == 'custom' && _customUrl.isNotEmpty;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: canGenerate && !_isGenerating ? _generateQRCode : null,
        icon: _isGenerating
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.qr_code),
        label: Text(_isGenerating ? 'Genereren...' : 'QR Code Genereren'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildQRActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Acties',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _downloadQRCode(),
                icon: const Icon(Icons.download),
                label: const Text('Download'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _shareQRCode(),
                icon: const Icon(Icons.share),
                label: const Text('Delen'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _copyQRUrl(),
                icon: const Icon(Icons.copy),
                label: const Text('Kopiëren'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCustomizeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Size customization
          _buildSizeCustomization(),

          const SizedBox(height: 24),

          // Color customization
          _buildColorCustomization(),

          const SizedBox(height: 24),

          // Format selection
          _buildFormatSelection(),

          const SizedBox(height: 24),

          // Logo options
          _buildLogoOptions(),
        ],
      ),
    );
  }

  Widget _buildSizeCustomization() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Grootte',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const Text('Klein'),
            Expanded(
              child: Slider(
                value: _qrSize,
                min: 100,
                max: 400,
                divisions: 6,
                label: '${_qrSize.round()}px',
                onChanged: (value) {
                  setState(() {
                    _qrSize = value;
                  });
                },
              ),
            ),
            const Text('Groot'),
          ],
        ),
        Center(
          child: Text(
            '${_qrSize.round()} x ${_qrSize.round()} pixels',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildColorCustomization() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kleuren',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),

        // QR Color
        Text(
          'QR Code Kleur',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),

        Wrap(
          spacing: 8,
          children: _colorOptions.map((color) {
            final isSelected = _qrColor == color;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _qrColor = color;
                });
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color:
                        isSelected ? AppColors.primary : Colors.grey.shade300,
                    width: isSelected ? 3 : 1,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 20)
                    : null,
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 16),

        // Background Color
        Text(
          'Achtergrond Kleur',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),

        Wrap(
          spacing: 8,
          children: _backgroundOptions.map((color) {
            final isSelected = _backgroundColor == color;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _backgroundColor = color;
                });
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color:
                        isSelected ? AppColors.primary : Colors.grey.shade300,
                    width: isSelected ? 3 : 1,
                  ),
                ),
                child: isSelected
                    ? Icon(Icons.check, color: AppColors.primary, size: 20)
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildFormatSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bestandsformaat',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: RadioListTile<String>(
                title: const Text('PNG'),
                subtitle: const Text('Bitmap afbeelding'),
                value: 'png',
                groupValue: _format,
                onChanged: (value) {
                  setState(() {
                    _format = value!;
                  });
                },
              ),
            ),
            Expanded(
              child: RadioListTile<String>(
                title: const Text('SVG'),
                subtitle: const Text('Vector afbeelding'),
                value: 'svg',
                groupValue: _format,
                onChanged: (value) {
                  setState(() {
                    _format = value!;
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLogoOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Logo Opties',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        RadioListTile<String>(
          title: const Text('Geen Logo'),
          subtitle: const Text('Alleen QR code'),
          value: 'none',
          groupValue: _logoPosition,
          onChanged: (value) {
            setState(() {
              _logoPosition = value!;
            });
          },
        ),
        RadioListTile<String>(
          title: const Text('Logo in Centrum'),
          subtitle: const Text('Menutri logo in het midden'),
          value: 'center',
          groupValue: _logoPosition,
          onChanged: (value) {
            setState(() {
              _logoPosition = value!;
            });
          },
        ),
      ],
    );
  }

  Widget _buildHistoryTab() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'QR Code Geschiedenis',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Geschiedenis van gegenereerde QR codes wordt binnenkort toegevoegd',
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

  // Helpers om QR-preview URL te maken voor restaurant/custom
  String _hexNoAlpha(Color c) {
    // kleur in RRGGBB (zonder alpha)
    final v = c.value.toRadixString(16).padLeft(8, '0'); // AARRGGBB
    return v.substring(2); // skip AA
  }

  String _buildQrPreviewUrl(
    String data,
    int size, {
    required Color fore,
    required Color back,
    String format = 'png',
  }) {
    // Gebruik eenvoudige publieke QR-service voor preview (zonder extra package)
    final color = _hexNoAlpha(fore);
    final bg = _hexNoAlpha(back);
    final s = '${size}x$size';
    final f = (format == 'svg') ? 'svg' : 'png';
    // api.qrserver.com accepteert color=RRGGBB en bgcolor=RRGGBB
    final encoded = Uri.encodeComponent(data);
    return 'https://api.qrserver.com/v1/create-qr-code/?size=$s&data=$encoded&color=$color&bgcolor=$bg&format=$f';
  }

  Future<void> _generateQRCode() async {
    setState(() => _isGenerating = true);

    try {
      String targetUrl;
      String description;

      switch (_qrType) {
        case 'restaurant':
          targetUrl =
              'https://menutri.nl/restaurant/${_selectedRestaurant!['id']}';
          description =
              'QR code voor ${_selectedRestaurant!['name'] ?? _selectedRestaurant!['name']}';
          break;
        case 'menu':
          targetUrl = 'https://menutri.nl/menu/${_selectedMenu!['id']}';
          description =
              'QR code voor menu ${_selectedMenu!['name'] ?? _selectedMenu!['name']}';
          break;
        case 'custom':
          targetUrl = _customUrl;
          description = 'Custom QR code voor $targetUrl';
          break;
        default:
          throw Exception('Onbekend QR type');
      }

      if (_qrType == 'menu') {
        // ✅ Backend ondersteunt: GET /menus/<id>/qr
        final menuId = (_selectedMenu!['id'] as num).toInt();
        final resp = await _apiService.getMenuQR(menuId);
        final Map<String, dynamic> response = Map<String, dynamic>.from(resp);

        // Als backend geen 'qr_url' teruggeeft, maak zelf een preview URL
        final qrUrl = response['qr_url'] ??
            _buildQrPreviewUrl(
              targetUrl,
              _qrSize.round(),
              fore: _qrColor,
              back: _backgroundColor,
              format: _format,
            );

        setState(() {
          _generatedQR = {
            ...response,
            'qr_url': qrUrl,
            'target_url': response['target_url'] ?? targetUrl,
            'description': response['description'] ?? description,
          };
          _isGenerating = false;
        });
      } else {
        // ✅ Voor restaurant/custom: gebruik preview-URL (geen backend nodig)
        final qrUrl = _buildQrPreviewUrl(
          targetUrl,
          _qrSize.round(),
          fore: _qrColor,
          back: _backgroundColor,
          format: _format,
        );

        setState(() {
          _generatedQR = {
            'qr_url': qrUrl,
            'target_url': targetUrl,
            'description': description,
            'format': _format,
            'size': _qrSize.round(),
            'qr_color': '#${_hexNoAlpha(_qrColor)}',
            'background_color': '#${_hexNoAlpha(_backgroundColor)}',
          };
          _isGenerating = false;
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('QR code succesvol gegenereerd!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isGenerating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fout bij genereren QR code: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _downloadQRCode() async {
    if (_generatedQR == null) return;

    try {
      // In a real app, this would trigger a download
      // For now, we'll show a success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('QR code download gestart'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fout bij downloaden: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _shareQRCode() async {
    if (_generatedQR == null) return;

    try {
      await Share.share(
        'Bekijk ons menu via deze QR code: ${_generatedQR!['target_url']}',
        subject: 'Menutri QR Code',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fout bij delen: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _copyQRUrl() async {
    if (_generatedQR == null) return;

    try {
      await Clipboard.setData(
        ClipboardData(text: _generatedQR!['target_url']),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('URL gekopieerd naar klembord'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fout bij kopiëren: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
