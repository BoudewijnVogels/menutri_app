# Menutri Flutter App

Een moderne Flutter-applicatie voor het ontdekken van gezonde restaurants en gerechten, met gepersonaliseerde voedingsaanbevelingen.

## 🎯 Overzicht

Menutri is een complete mobiele applicatie die gebruikers helpt bij het vinden van gezonde voedingsopties in restaurants. De app biedt twee verschillende gebruikersrollen:

- **Gasten**: Ontdekken restaurants, scannen QR-codes, beheren favorieten en volgen voedingsinformatie
- **Cateraars**: Beheren restaurants, menu's en analyseren klantgegevens

## ✨ Functies

### Voor Gasten
- 🏠 **Home Dashboard** - Gepersonaliseerde aanbevelingen en nabijgelegen restaurants
- 🔍 **Zoeken & Filteren** - Vind restaurants op basis van locatie, prijs, keuken en dieetwensen
- ❤️ **Favorieten** - Bewaar favoriete restaurants en gerechten in collecties
- 📱 **QR Scanner** - Scan restaurant QR-codes voor directe toegang tot menu's
- 🏥 **Gezondheidsprofiel** - Stel persoonlijke voedingsdoelen en beperkingen in
- 📊 **Voedingslogboek** - Volg wat je eet en je voedingsinname

### Voor Cateraars
- 📈 **Dashboard** - Overzicht van restaurant prestaties en statistieken
- 🏪 **Restaurant Beheer** - Beheer restaurant informatie en instellingen
- 📋 **Menu Beheer** - Voeg gerechten toe, bewerk prijzen en voedingsinformatie
- 📊 **Analytics** - Gedetailleerde inzichten in klantgedrag en populaire gerechten

## 🎨 Design

De app gebruikt een moderne, vriendelijke design met een warme kleurenpalet:

- **Donkerbruin** (#1D140C) - Primaire tekst en accenten
- **Middenbruin** (#AA8474) - Hoofdmerkkleur
- **Lichtbruin** (#DFD3CE) - Secundaire elementen
- **Wit** (#FFFFFF) - Achtergronden en contrast

Typography gebruikt de **Inter** font familie voor optimale leesbaarheid.

## 🏗️ Architectuur

### Project Structuur
```
lib/
├── core/                    # Gedeelde functionaliteit
│   ├── constants/          # App constanten
│   ├── models/             # Data modellen
│   ├── routing/            # Navigatie configuratie
│   ├── services/           # API services
│   └── theme/              # UI theming
├── features/               # Feature modules
│   ├── auth/               # Authenticatie
│   ├── guest/              # Gast functionaliteit
│   └── cateraar/           # Cateraar functionaliteit
└── main.dart               # App entry point
```

### Technische Stack
- **Flutter** - Cross-platform UI framework
- **Riverpod** - State management
- **Go Router** - Declarative routing
- **Dio** - HTTP client voor API calls
- **Google Fonts** - Typography
- **Material 3** - Design system

## 🔌 API Integratie

De app integreert volledig met de Menutri backend API:

### Authenticatie
- JWT-gebaseerde authenticatie met refresh tokens
- Rol-gebaseerde toegangscontrole (Gast/Cateraar)
- Veilige token opslag

### Endpoints
- **Restaurants** - Zoeken, details, locatie-gebaseerd zoeken
- **Menu's & Gerechten** - Volledige menu informatie met voeding
- **Favorieten** - Persoonlijke collecties en delen
- **Gezondheid** - BMI/BMR berekeningen en doelen
- **Analytics** - Uitgebreide statistieken voor cateraars

## 🚀 Installatie & Setup

### Vereisten
- Flutter SDK (3.5.3+)
- Dart SDK
- Android Studio / VS Code
- Android SDK (voor Android builds)
- Xcode (voor iOS builds, alleen macOS)

### Installatie
1. Clone de repository
```bash
git clone <repository-url>
cd menutri_app
```

2. Installeer dependencies
```bash
flutter pub get
```

3. Configureer API endpoint
```dart
// lib/core/constants/app_constants.dart
static const String baseUrl = 'https://your-backend-url.com/api';
```

4. Run de app
```bash
flutter run
```

## 🧪 Testing

Run tests:
```bash
flutter test
```

Analyze code:
```bash
flutter analyze
```

## 📱 Builds

### Debug Build
```bash
flutter build apk --debug
```

### Release Build
```bash
flutter build apk --release
```

### iOS Build (macOS only)
```bash
flutter build ios --release
```

## 🔧 Configuratie

### API Configuration
Update de base URL in `lib/core/constants/app_constants.dart`:

```dart
static const String baseUrl = 'https://your-backend-url.com/api';
```

### Theme Customization
Pas kleuren aan in `lib/core/theme/app_colors.dart`:

```dart
static const Color darkBrown = Color(0xFF1D140C);
static const Color mediumBrown = Color(0xFFAA8474);
// etc...
```

## 📋 Roadmap

### Volgende Features
- [ ] Offline ondersteuning
- [ ] Push notificaties
- [ ] Social sharing
- [ ] Geavanceerde filters
- [ ] Meal planning
- [ ] Barcode scanning voor ingrediënten
- [ ] Integratie met fitness apps
- [ ] Multi-language ondersteuning

### Technische Verbeteringen
- [ ] Caching strategie
- [ ] Performance optimalisatie
- [ ] Accessibility verbeteringen
- [ ] Unit test coverage uitbreiden
- [ ] Integration tests

## 🤝 Contributing

1. Fork het project
2. Maak een feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit je changes (`git commit -m 'Add some AmazingFeature'`)
4. Push naar de branch (`git push origin feature/AmazingFeature`)
5. Open een Pull Request

## 📄 License

Dit project is gelicenseerd onder de MIT License - zie het [LICENSE](LICENSE) bestand voor details.

## 📞 Contact

Voor vragen of ondersteuning, neem contact op via:
- Email: support@menutri.com
- Website: https://menutri.com

---

**Menutri** - Ontdek gezonde voeding, overal en altijd! 🥗✨

