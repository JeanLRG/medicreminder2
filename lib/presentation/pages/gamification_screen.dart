import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../medicamento_provider.dart';
import '../../domain/conquista.dart';

class GamificationScreen extends StatelessWidget {
  const GamificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Meu Progresso',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF00B4DB), Color(0xFF0083B0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Consumer<MedicamentoProvider>(
            builder: (context, provider, child) {
              final int xpAtual = provider.xpAtualNoNivel;
              final int xpTotalProxNivel = provider.xpProximoNivel;
              final double progressoNivel = xpAtual / xpTotalProxNivel.toDouble();
              final bool maxLevel = provider.nivel >= 100; // Caso queiramos um limite

              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          _buildLevelCard(provider.nivel, xpAtual, xpTotalProxNivel, progressoNivel, maxLevel, theme),
                          const SizedBox(height: 24),
                          _buildStatsRow(provider.pontos, provider.streak),
                          const SizedBox(height: 32),
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Minhas Conquistas',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.9,
                      ),
                      delegate: SliverChildListDelegate(
                        Conquista.todas
                            // Filter out 'level_up' if you don't consider it a badge to display on the glass case, 
                            // but usually it's better to only show actual badges like 'primeira_tomada' etc.
                            // Let's hide 'level_up' from the grid since it's an event badge, not a collection badge.
                            .where((c) => c.id != 'level_up')
                            .map((conquista) => _buildBadge(
                                  id: conquista.id,
                                  nome: conquista.titulo,
                                  descricao: conquista.descricao,
                                  icone: conquista.icone,
                                  cor: conquista.cor,
                                  badgesUsuario: provider.badges,
                                ))
                            .toList(),
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 40)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLevelCard(int nivel, int xpAtual, int xpTotalProxNivel, double progresso, bool maxLevel, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          )
        ],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: progresso),
                  duration: const Duration(seconds: 1),
                  curve: Curves.easeInOut,
                  builder: (context, value, child) {
                    return CircularProgressIndicator(
                      value: maxLevel ? 1.0 : value,
                      strokeWidth: 10,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    );
                  },
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'NÍVEL',
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '$nivel',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              )
            ],
          ),
          const SizedBox(height: 20),
          Text(
            maxLevel ? 'Nível Máximo Alcançado!' : '$xpAtual / $xpTotalProxNivel XP',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            maxLevel ? 'Você é um mestre!' : 'Faltam ${xpTotalProxNivel - xpAtual} XP para o próximo nível',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(int pontosGlobais, int streak) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatItem('Pontos Totais', '$pontosGlobais', Icons.auto_awesome),
        Container(width: 1, height: 40, color: Colors.white.withOpacity(0.3)),
        _buildStatItem('Dias Seguidos', '$streak', Icons.local_fire_department),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildBadge({
    required String id,
    required String nome,
    required String descricao,
    required IconData icone,
    required Color cor,
    required List<String> badgesUsuario,
  }) {
    final bool isUnblocked = badgesUsuario.contains(id);

    return Container(
      decoration: BoxDecoration(
        color: isUnblocked ? Colors.white : Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isUnblocked ? cor.withOpacity(0.5) : Colors.white.withOpacity(0.2),
          width: 2,
        ),
        boxShadow: isUnblocked
            ? [
                BoxShadow(
                  color: cor.withOpacity(0.3),
                  blurRadius: 15,
                  spreadRadius: 2,
                )
              ]
            : [],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isUnblocked ? icone : Icons.lock_rounded,
            size: 48,
            color: isUnblocked ? cor : Colors.white.withOpacity(0.5),
          ),
          const SizedBox(height: 12),
          Text(
            nome,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isUnblocked ? Colors.black87 : Colors.white70,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            descricao,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isUnblocked ? Colors.black54 : Colors.white54,
              fontSize: 10,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
