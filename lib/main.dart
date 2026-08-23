import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const JadhalApp());
}

class JadhalApp extends StatelessWidget {
  const JadhalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'જધલ',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: GoogleFonts.notoSansGujarati().fontFamily,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.light,
        ),
      ),
      home: const JadhalHomeScreen(),
    );
  }
}

enum GameScreen { setup, reveal, discussion, result }

class GamePlayer {
  final String name;
  final String role; // 'civilian' or 'imposter'

  GamePlayer({required this.name, required this.role});
}

class JadhalHomeScreen extends StatefulWidget {
  const JadhalHomeScreen({super.key});

  @override
  State<JadhalHomeScreen> createState() => _JadhalHomeScreenState();
}

class _JadhalHomeScreenState extends State<JadhalHomeScreen>
    with SingleTickerProviderStateMixin {
  // Game Setup State
  final List<String> _players = [];
  final TextEditingController _nameController = TextEditingController();
  int _impostersCount = 1;
  String _selectedCategory = 'all';
  bool _trollMode = false;

  // Active Game State
  GameScreen _currentScreen = GameScreen.setup;
  List<GamePlayer> _gamePlayers = [];
  int _currentPlayerIndex = 0;
  bool _isTrollRound = false;
  String _secretWord = '';
  String _startingPlayer = '';
  bool _isCardFlipped = false;

  // Card Flip Animation
  late AnimationController _flipController;

  // Word Database
  static const Map<String, List<String>> wordsDatabase = {
    'food': [
      "પાણીપુરી", "ઢોસા", "પીઝા", "જલેબી", "વડાપાઉં", "બર્ગર", "આઈસ્ક્રીમ", "ચોકલેટ",
      "ગાંઠિયા", "ભજીયા", "રોટલો", "શ્રીખંડ", "કેરીનો રસ", "સમોસા", "મેગી", "સેવ ઉસળ",
      "દાબેલી", "ખમણ", "ઢોકળા", "ઈડલી", "મંચુરિયન", "સેન્ડવીચ", "ભેળ", "પાસ્તા",
      "નૂડલ્સ", "સૂપ", "સલાડ", "પાપડ", "છાશ", "લસ્સી", "દૂધપાક", "બાસુંદી",
      "ગુલાબ જાંબુ", "કાજુ કતરી", "પેંડા", "બરફી", "લાડુ", "મોહનથાળ", "સુખડી",
      "શીરો", "ઉપમા", "પૌવા", "થેપલા", "મુઠીયા", "પાતરા", "ખાંડવી", "ફાફડા",
      "ચોળાફળી", "કચોરી", "પફ", "બિસ્કિટ", "બ્રેડ", "બટર", "ચીઝ", "પનીર", "દહીં",
      "ઘી", "દૂધ", "ચા", "કોફી", "જ્યુસ", "શરબત", "નાળિયેર પાણી", "સફરજન",
      "કેળા", "કેરી", "દ્રાક્ષ", "તરબૂચ", "પપૈયા", "દાડમ", "જામફળ", "સંતરા", "ચીકુ"
    ],
    'animals': [
      "સિંહ", "વાઘ", "હાથી", "કૂતરો", "બિલાડી", "ઘોડો", "ગાય", "ભેંસ", "બકરી",
      "ઘેટું", "ગધેડો", "ઊંટ", "જીરાફ", "ઝીબ્રા", "કાંગારૂ", "પાંડા", "રીંછ",
      "હરણ", "વાંદરો", "ગોરીલા", "ચિમ્પાન્જી", "સસલું", "ઉંદર", "ખિસકોલી", "સાપ",
      "મગર", "કાચબો", "દેડકો", "ગરોળી", "માછલી", "શાર્ક", "વ્હેલ", "ડોલ્ફિન",
      "ઓક્ટોપસ", "પેંગ્વિન", "ગરુડ", "ઘુવડ", "મોર", "પોપટ", "કબૂતર", "કાગડો",
      "ચકલી", "હંસ", "બતક", "મરઘી", "શાહમૃગ", "ફ્લેમિંગો", "પતંગિયું", "મધમાખી",
      "કીડી", "મચ્છર", "માખી", "કરોળિયો", "વીંછી", "દીપડો", "ચિત્તો", "વરુ"
    ],
    'places': [
      "શાળા", "કોલેજ", "ઓફિસ", "હોસ્પિટલ", "બેંક", "પોસ્ટ ઓફિસ", "પોલીસ સ્ટેશન",
      "એરપોર્ટ", "બંદર", "હોટેલ", "રેસ્ટોરન્ટ", "સિનેમા હોલ", "મોલ", "બજાર", "દુકાન",
      "બગીચો", "પ્રાણીસંગ્રહાલય", "મ્યુઝિયમ", "લાઈબ્રેરી", "જીમ", "સ્ટેડિયમ",
      "સ્વિમિંગ પૂલ", "મંદિર", "મસ્જિદ", "ચર્ચ", "ગુરુદ્વારા", "ખેતર", "ગામડું",
      "શહેર", "જંગલ", "પહાડ", "નદી", "તળાવ", "દરિયાકિનારો", "રણ", "ટાપુ",
      "ગુફા", "મહેલ", "કિલ્લો", "પુલ", "બંગલો", "ફ્લેટ", "રસોડું", "બાથરૂમ"
    ],
    'objects': [
      "મોબાઈલ", "ચાર્જર", "ઇયરફોન", "લેપટોપ", "કોમ્પ્યુટર", "કીબોર્ડ", "માઉસ",
      "ટીવી", "રિમોટ", "કેમેરા", "ઘડિયાળ", "પંખો", "એસી", "હીટર", "લાઈટ",
      "ટ્યુબલાઈટ", "ટોર્ચ", "ઇસ્ત્રી", "વોશિંગ મશીન", "ફ્રિજ", "માઇક્રોવેવ",
      "મિક્સર", "ઓવન", "સ્ટવ", "ગેસ સિલિન્ડર", "નળ", "ડોલ", "સાબુ", "શેમ્પૂ",
      "ટૂથબ્રશ", "ટૂથપેસ્ટ", "કાંસકો", "અરીસો", "ટુવાલ", "કપડાં", "શર્ટ", "પેન્ટ",
      "જીન્સ", "સાડી", "બુટ", "મોજાં", "ચપ્પલ", "બેગ", "પર્સ", "વોલેટ", "બેલ્ટ"
    ],
    'bollywood': [
      "અમિતાભ બચ્ચન", "શાહરુખ ખાન", "સલમાન ખાન", "આમિર ખાન", "અક્ષય કુમાર",
      "અજય દેવગન", "રિતિક રોશન", "રણવીર સિંહ", "રણબીર કપૂર", "શાહિદ કપૂર",
      "સંજય દત્ત", "સની દેઓલ", "ગોવિંદા", "અનિલ કપૂર", "પરેશ રાવલ", "અનુપમ ખેર",
      "જોની લીવર", "રાજપાલ યાદવ", "આલિયા ભટ્ટ", "દીપિકા પાદુકોણ", "પ્રિયંકા ચોપરા",
      "કરીના કપૂર", "કેટરીના કૈફ", "શ્રદ્ધા કપૂર", "કિયારા અડવાણી", "કાજોલ",
      "માધુરી દીક્ષિત", "ઐશ્વર્યા રાય", "અરિજિત સિંહ", "નરેન્દ્ર મોદી", "વિરાટ કોહલી",
      "ધોની", "મુકેશ અંબાણી", "જેઠાલાલ", "દયા ભાભી", "સચિન તેંડુલકર"
    ],
    'jobs': [
      "ડોક્ટર", "નર્સ", "એન્જિનિયર", "શિક્ષક", "વિક્રેટા", "વકીલ", "જજ", "પોલીસ",
      "સૈનિક", "પાયલોટ", "ડ્રાઈવર", "કંડક્ટર", "ખેડૂત", "સુથાર", "પ્લમ્બર",
      "ઇલેક્ટ્રિશિયન", "દરજી", "વાળંદ", "મોચી", "દુકાનદાર", "વેપારી", "મેનેજર",
      "ચોકીદાર", "સફાઈ કામદાર", "રસોઈયા", "એક્ટર", "સિંગર", "ડાન્સર", "ચિત્રકાર",
      "ફોટોગ્રાફર", "પત્રકાર", "નેતા", "ક્રિકેટર", "વૈજ્ઞાનિક", "અવકાશયાત્રી"
    ],
    'nature': [
      "સૂર્ય", "ચંદ્ર", "તારા", "આકાશ", "વાદળ", "વરસાદ", "વીજળી", "મેઘધનુષ", "પવન",
      "વાવાઝોડું", "બરફ", "ધુમ્મસ", "ગરમી", "ઠંડી", "આગ", "પાણી", "માટી", "પથ્થર",
      "રેતી", "દરિયો", "મોજાં", "ઝાડ", "પાંદડા", "ફૂલ", "ફળ", "ડાળી", "ઘાસ",
      "જ્વાળામુખી", "ધરતીકંપ", "પૃથ્વી", "સૂર્યોદય", "સૂર્યાસ્ત", "દિવસ", "રાત"
    ],
    'festivals': [
      "દિવાળી", "હોળી", "ધુળેટી", "નવરાત્રી", "રક્ષાબંધન", "જન્માષ્ટમી", "ગણેશ ચતુર્થી",
      "ઉત્તરાયણ", "દશેરા", "ઈદ", "નાતાલ", "સ્વતંત્રતા દિવસ", "પ્રજાસત્તાક દિવસ",
      "લગ્ન", "જન્મદિવસ", "પાર્ટી", "હનુમાન જયંતિ", "રામ નવમી", "મહાશિવરાત્રી"
    ]
  };

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _flipController.dispose();
    super.dispose();
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E293B),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  void _addPlayer() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showToast("મહેરબાની કરીને નામ લખો! ✍️");
      return;
    }
    if (_players.contains(name)) {
      _showToast("આ નામ પહેલેથી જ ઉમેરાયેલ છે! 🚫");
      return;
    }
    setState(() {
      _players.add(name);
      _nameController.clear();
    });
    HapticFeedback.lightImpact();
  }

  void _removePlayer(int index) {
    setState(() {
      _players.removeAt(index);
    });
    HapticFeedback.lightImpact();
  }

  void _startGame() {
    if (_players.length < 3) {
      _showToast("ઓછામાં ઓછા ૩ ખેલાડીઓ જોઈએ! 👥");
      return;
    }
    if (_impostersCount >= _players.length) {
      _showToast("ઇમ્પોસ્ટરની સંખ્યા ખેલાડીઓ કરતાં વધારે ન હોઈ શકે! ⚠️");
      return;
    }

    HapticFeedback.mediumImpact();

    bool troll = false;
    if (_trollMode && Random().nextDouble() < 0.25) {
      troll = true;
    }

    List<String> pool = [];
    if (_selectedCategory == 'all') {
      wordsDatabase.values.forEach(pool.addAll);
    } else {
      pool = wordsDatabase[_selectedCategory] ?? [];
    }

    final secret = pool[Random().nextInt(pool.length)];

    List<GamePlayer> gamePlayersList = [];
    if (troll) {
      gamePlayersList = _players.map((name) => GamePlayer(name: name, role: 'imposter')).toList();
    } else {
      List<int> indices = List.generate(_players.length, (i) => i)..shuffle();
      List<int> impIndices = indices.sublist(0, _impostersCount);
      gamePlayersList = List.generate(_players.length, (i) {
        return GamePlayer(
          name: _players[i],
          role: impIndices.contains(i) ? 'imposter' : 'civilian',
        );
      });
    }

    setState(() {
      _secretWord = secret;
      _isTrollRound = troll;
      _gamePlayers = gamePlayersList;
      _currentPlayerIndex = 0;
      _isCardFlipped = false;
      _currentScreen = GameScreen.reveal;
    });
    _flipController.reset();
  }

  void _flipCard(bool showBack) {
    if (showBack) {
      _flipController.forward();
      HapticFeedback.selectionClick();
    } else {
      _flipController.reverse();
      HapticFeedback.selectionClick();
    }
    setState(() {
      _isCardFlipped = showBack;
    });
  }

  void _nextTurn() {
    if (_currentPlayerIndex < _gamePlayers.length - 1) {
      setState(() {
        _currentPlayerIndex++;
        _isCardFlipped = false;
      });
      _flipController.reset();
    } else {
      final starter = _gamePlayers[Random().nextInt(_gamePlayers.length)].name;
      setState(() {
        _startingPlayer = starter;
        _currentScreen = GameScreen.discussion;
      });
    }
  }

  void _showResultConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text("🤔 પાક્કું પરિણામ જોવું છે?", textAlign: TextAlign.center),
        content: const Text("શું બધાની ચર્ચા પૂરી થઈ ગઈ છે?", textAlign: TextAlign.center),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("ના ❌", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF43F5E),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _currentScreen = GameScreen.result;
              });
            },
            child: const Text("હા ✅", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _resetGame() {
    setState(() {
      _currentScreen = GameScreen.setup;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 440),
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF8FAFC), Color(0xFFF3E8FF)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(36),
              border: Border.all(color: Colors.white.withOpacity(0.2), width: 4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                )
              ],
            ),
            child: Column(
              children: [
                // Header Banner
                _buildHeader(),
                Expanded(child: _buildScreenContent()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF59E0B), Color(0xFFFB923C), Color(0xFFEC4899)],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          const Text(
            'જધલ',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              shadows: [
                Shadow(color: Color(0xFFB45309), offset: Offset(2, 2)),
                Shadow(color: Color(0xFF78350F), offset: Offset(4, 4)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Gujarati Edition',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: Color(0xFF78350F),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildScreenContent() {
    switch (_currentScreen) {
      case GameScreen.setup:
        return _buildSetupScreen();
      case GameScreen.reveal:
        return _buildRevealScreen();
      case GameScreen.discussion:
        return _buildDiscussionScreen();
      case GameScreen.result:
        return _buildResultScreen();
    }
  }

  // --- SCREEN 1: SETUP ---
  Widget _buildSetupScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Player input box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE0E7FF), width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "👥 ખેલાડીઓ ઉમેરો (Players)",
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF4F46E5)),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          hintText: "ખેલાડીનું નામ...",
                          filled: true,
                          fillColor: const Color(0xFFEEF2FF),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        onSubmitted: (_) => _addPlayer(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        padding: const EdgeInsets.all(14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: _addPlayer,
                      child: const Text("➕", style: TextStyle(fontSize: 18, Colors: Colors.white)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 130),
                  child: _players.isEmpty
                      ? Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F3FF),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Text(
                            "કોઈ ખેલાડી ઉમેરાયેલ નથી! (ઓછામાં ઓછા ૩) 🤷‍♂️",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Color(0xFFA5B4FC), fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          itemCount: _players.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 6),
                          itemBuilder: (context, index) {
                            final p = _players[index];
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F3FF),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 12,
                                    backgroundColor: const Color(0xFF6366F1),
                                    child: Text(p[0], style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(child: Text(p, style: const TextStyle(fontWeight: FontWeight.bold))),
                                  IconButton(
                                    icon: const Icon(Icons.close, size: 18, color: Colors.rose),
                                    onPressed: () => _removePlayer(index),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Imposters & Category
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("ઇમ્પોસ્ટર સંખ્યા", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF4F46E5))),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _impostersCount = 1),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: _impostersCount == 1 ? const Color(0xFFF43F5E) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text("1 લોકો", textAlign: TextAlign.center, style: TextStyle(color: _impostersCount == 1 ? Colors.white : Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _impostersCount = 2),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: _impostersCount == 2 ? const Color(0xFFF43F5E) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text("2 લોકો", textAlign: TextAlign.center, style: TextStyle(color: _impostersCount == 2 ? Colors.white : Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("કેટેગરી પસંદ કરો", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF4F46E5))),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedCategory,
                          isExpanded: true,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black),
                          items: const [
                            DropdownMenuItem(value: 'all', child: Text("🌈 બધું મિક્સ")),
                            DropdownMenuItem(value: 'food', child: Text("🍔 ખોરાક")),
                            DropdownMenuItem(value: 'animals', child: Text("🦁 પ્રાણીઓ")),
                            DropdownMenuItem(value: 'places', child: Text("🏰 જગ્યાઓ")),
                            DropdownMenuItem(value: 'objects', child: Text("📱 વસ્તુઓ")),
                            DropdownMenuItem(value: 'bollywood', child: Text("🎬 બોલીવુડ")),
                            DropdownMenuItem(value: 'jobs', child: Text("👨‍⚕️ વ્યવસાય")),
                            DropdownMenuItem(value: 'nature', child: Text("🌳 કુદરત")),
                            DropdownMenuItem(value: 'festivals', child: Text("🎉 તહેવારો")),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedCategory = val);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Troll Mode Toggle
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Row(
              children: [
                const Text("🤡", style: TextStyle(fontSize: 28)),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("ટ્રોલ મોડ (Troll Mode)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF78350F))),
                      Text("બધા જ ઇમ્પોસ્ટર બની જશે!", style: TextStyle(fontSize: 10, color: Color(0xFF92400E))),
                    ],
                  ),
                ),
                Switch(
                  value: _trollMode,
                  activeColor: const Color(0xFF10B981),
                  onChanged: (val) => setState(() => _trollMode = val),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Start Button
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 5,
            ),
            onPressed: _startGame,
            child: const Text("રમત શરૂ કરો 🚀", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- SCREEN 2: CARD REVEAL ---
  Widget _buildRevealScreen() {
    final player = _gamePlayers[_currentPlayerIndex];
    final nextPlayer = _currentPlayerIndex < _gamePlayers.length - 1
        ? _gamePlayers[_currentPlayerIndex + 1].name
        : "સૌ પ્રથમ ખેલાડી";

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFE0E7FF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text("આમનો વારો છે", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5))),
          ),
          const SizedBox(height: 4),
          Text(
            player.name,
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF1E1B4B)),
          ),
          const Spacer(),
          // 3D Animated Card
          GestureDetector(
            onLongPressStart: (_) => _flipCard(true),
            onLongPressEnd: (_) => _flipCard(false),
            child: AnimatedBuilder(
              animation: _flipController,
              builder: (context, child) {
                final angle = _flipController.value * pi;
                final isBackVisible = angle >= pi / 2;
                return Transform(
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateY(angle),
                  alignment: Alignment.center,
                  child: Container(
                    width: 260,
                    height: 320,
                    decoration: BoxDecoration(
                      gradient: isBackVisible
                          ? (player.role == 'imposter'
                              ? const LinearGradient(colors: [Color(0xFFF43F5E), Color(0xFFBE123C)])
                              : const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF047857)]))
                          : const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF4338CA)]),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: Colors.white.withOpacity(0.3), width: 4),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 20, offset: const Offset(0, 10))
                      ],
                    ),
                    child: Transform(
                      transform: Matrix4.identity()..rotateY(isBackVisible ? pi : 0),
                      alignment: Alignment.center,
                      child: isBackVisible
                          ? (player.role == 'imposter'
                              ? const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text("😈", style: TextStyle(fontSize: 64)),
                                    SizedBox(height: 12),
                                    Text("તમે ઇમ્પોસ્ટર જધલ છો", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white)),
                                    SizedBox(height: 6),
                                    Text("🤫 શૂૂ.... કોઈને કહેતા નહીં!", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                                  ],
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text("✅", style: TextStyle(fontSize: 54)),
                                    const SizedBox(height: 8),
                                    const Text("તમારો ગુપ્ત શબ્દ", style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: Colors.black26,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Text(
                                        _secretWord,
                                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white),
                                      ),
                                    ),
                                  ],
                                ))
                          : const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text("🕵️‍♂️", style: TextStyle(fontSize: 72)),
                                SizedBox(height: 12),
                                Text("તમારો ગુપ્ત શબ્દ જોવા", style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                                SizedBox(height: 4),
                                Text("દબાવી રાખો", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white)),
                                SizedBox(height: 16),
                                Text("👆 Hold Card", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                              ],
                            ),
                    ),
                  ),
                );
              },
            ),
          ),
          const Spacer(),
          Text(
            "કાર્ડ જોઈ લીધા પછી $nextPlayer ને ફોન આપો",
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF97316),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
              onPressed: _nextTurn,
              child: const Text("આગળનો ખેલાડી ➡️", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  // --- SCREEN 3: DISCUSSION ---
  Widget _buildDiscussionScreen() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(color: Color(0xFFFDE68A), shape: BoxShape.circle),
            child: const Text("🗣️", style: TextStyle(fontSize: 54)),
          ),
          const SizedBox(height: 20),
          const Text("ચર્ચા કરો! (Discuss)", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          const Text("બધા ખેલાડીઓએ તેમનો શબ્દ જોઈ લીધો છે.", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
            child: Column(
              children: [
                const Text("પ્રથમ બોલવાની શરૂઆત કરશે", style: TextStyle(fontSize: 11, color: Color(0xFFD97706), fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(_startingPlayer, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFFF43F5E))),
              ],
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF43F5E),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              onPressed: _showResultConfirmation,
              child: const Text("પરિણામ જુઓ 👁️", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  // --- SCREEN 4: RESULTS ---
  Widget _buildResultScreen() {
    final imposters = _gamePlayers.where((p) => p.role == 'imposter').toList();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_isTrollRound)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: const Row(
                children: [
                  Text("🤡", style: TextStyle(fontSize: 28)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("ટ્રોલ મોડ ધમાકો!", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF78350F))),
                        Text("બધા જ ઇમ્પોસ્ટર હતા!", style: TextStyle(fontSize: 11, color: Color(0xFF92400E))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const Text("સાચો ગુપ્ત શબ્દ", textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF059669))),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
            ),
            child: Text(
              _isTrollRound ? "??? (કોઈ શબ્દ નહોતો!)" : _secretWord,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
            ),
          ),
          const SizedBox(height: 20),
          const Text("ઇમ્પોસ્ટર કોણ હતા?", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.grey)),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.separated(
              itemCount: imposters.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final imp = imposters[index];
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFFFE4E6)),
                  ),
                  child: Row(
                    children: [
                      const Text("😈", style: TextStyle(fontSize: 22)),
                      const SizedBox(width: 12),
                      Text(imp.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                    ],
                  ),
                );
              },
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            onPressed: _resetGame,
            child: const Text("ફરી રમો 🔄", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
          ),
          const SizedBox(height: 12),
          const Text(
            "Made with ❤️ By Aadhar",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
