import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'models/character_unit.dart';
import 'providers/battle_provider.dart';
import 'widgets/center_control_panel.dart';
import 'widgets/dialogs/character_select_dialog.dart';
import 'widgets/dialogs/game_over_dialog.dart';
import 'widgets/main_home_page.dart';
import 'widgets/player_panel.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 強制橫屏 (Landscape Only)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // 全螢幕沉浸模式 (隱藏系統狀態列、時間、電量與導航列)
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  runApp(const BoardGameBattleApp());
}

class BoardGameBattleApp extends StatelessWidget {
  final BattleProvider? provider;

  const BoardGameBattleApp({super.key, this.provider});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => provider ?? BattleProvider(),
      child: MaterialApp(
        title: 'Ash Bound',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF0D1117),
          primaryColor: const Color(0xFF3B82F6),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF3B82F6),
            secondary: Color(0xFFEF4444),
            surface: Color(0xFF161C26),
          ),
          fontFamily: 'Roboto',
          useMaterial3: true,
          splashFactory: InkRipple.splashFactory,
        ),
        home: const MainHomePage(),
      ),
    );
  }
}

class BattleFieldScreen extends StatefulWidget {
  const BattleFieldScreen({super.key});

  @override
  State<BattleFieldScreen> createState() => _BattleFieldScreenState();
}

class _BattleFieldScreenState extends State<BattleFieldScreen> {
  bool _gameOverDialogShown = false;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BattleProvider>();

    // 若遊戲已重新開始，重設標記
    if (!provider.isGameOver && _gameOverDialogShown) {
      _gameOverDialogShown = false;
    }

    // 監聽生命值歸零或手動結束遊戲，自動彈出結算對話框
    if (provider.isGameOver && !_gameOverDialogShown) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _gameOverDialogShown) return;
        _gameOverDialogShown = true;

        GameOverDialog.show(
          context: context,
          winnerIndex: provider.winnerIndex,
          title: provider.winnerIndex == null
              ? '遊戲已結束'
              : provider.winnerIndex == -1
                  ? '平局！'
                  : '勝利者產生！',
          reason: provider.gameOverReason ?? '遊戲結束',
          onRestart: () {
            CharacterSelectDialog.show(
              context: context,
              initialStartingPlayer: 0,
              onConfirm: ({
                required CharacterUnit hero1,
                required CharacterUnit hero2,
                required int startingPlayerIndex,
              }) {
                provider.restartGame(
                  startingPlayerIndex: startingPlayerIndex,
                  hero1: hero1,
                  hero2: hero2,
                );
              },
            );
          },
        ).then((_) {
          // 當對話框被關閉時，若遊戲尚未重啟（isGameOver 仍為 true），保持標記避免重新彈出；
          // 只有當遊戲已被重啟 (isGameOver 變為 false) 時，重設標記
          if (!provider.isGameOver) {
            _gameOverDialogShown = false;
          }
        });
      });
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 900;
    final horizontalPadding = isTablet ? 12.0 : 6.0;
    final verticalPadding = isTablet ? 8.0 : 4.0;
    final panelSpacing = isTablet ? 10.0 : 6.0;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 左方玩家 (Player 1)
              const Expanded(
                flex: 11,
                child: PlayerPanel(playerIndex: 0),
              ),

              SizedBox(width: panelSpacing),

              // 中間全域控制按鈕 (結束回合置中，骰子與輔助按鈕置於下方)
              const CenterControlPanel(),

              SizedBox(width: panelSpacing),

              // 右方玩家 (Player 2)
              const Expanded(
                flex: 11,
                child: PlayerPanel(playerIndex: 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
