import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../medicamento_provider.dart';
import '../../domain/conquista.dart';
import '../../core/app_theme.dart';

class GamificationScreen extends StatelessWidget {
  const GamificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text(
          'Meu Progresso',
          style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: AppTheme.primaryBlue,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white, size: 28),
      ),
      body: SafeArea(
        child: Consumer<MedicamentoProvider>(
          builder: (context, provider, child) {
            final int xpAtual = provider.xpAtualNoNivel;
            final int xpTotalProxNivel = provider.xpProximoNivel;
            final double progressoNivel = xpAtual / xpTotalProxNivel.toDouble();
            final bool maxLevel = provider.nivel >= 100;

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        _buildLevelCard(provider.nivel, xpAtual,
                            xpTotalProxNivel, progressoNivel, maxLevel),
                        const SizedBox(height: 24),
                        _buildStatsRow(provider.pontos, provider.streak),
                        const SizedBox(height: 32),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Minhas Conquistas',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.textDark,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final listConquistas = Conquista.todas
                            .where((c) => c.id != 'level_up')
                            .toList();
                        if (index >= listConquistas.length) return null;
                        
                        final conquista = listConquistas[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: _buildBadgeListTile(
                            id: conquista.id,
                            nome: conquista.titulo,
                            descricao: conquista.descricao,
                            icone: conquista.icone,
                            cor: conquista.cor,
                            badgesUsuario: provider.badges,
                          ),
                        );
                      },
                      childCount: Conquista.todas.where((c) => c.id != 'level_up').length,
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildLevelCard(int nivel, int xpAtual, int xpTotalProxNivel,
      double progresso, bool maxLevel) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 140,
                height: 140,
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: progresso),
                  duration: const Duration(seconds: 1),
                  curve: Curves.easeInOut,
                  builder: (context, value, child) {
                    return CircularProgressIndicator(
                      value: maxLevel ? 1.0 : value,
                      strokeWidth: 12,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(Colors.white),
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
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    '$nivel',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 56,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              )
            ],
          ),
          const SizedBox(height: 24),
          Text(
            maxLevel
                ? 'Nível Máximo Alcançado!'
                : '$xpAtual / $xpTotalProxNivel XP',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            maxLevel
                ? 'Você é um mestre da saúde!'
                : 'Faltam ${xpTotalProxNivel - xpAtual} XP para o próximo nível',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 18,
              fontWeight: FontWeight.w600,
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
        Expanded(
          child: _buildStatItem(
            'Pontos Totais',
            '$pontosGlobais',
            Icons.star_rounded,
            const Color(0xFFFFB300),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatItem(
            'Dias Seguidos',
            '$streak',
            Icons.local_fire_department_rounded,
            AppTheme.alertOrange,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
        border: Border.all(color: color.withOpacity(0.3), width: 2),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 40),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 32,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.textMedium,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeListTile({
    required String id,
    required String nome,
    required String descricao,
    required IconData icone,
    required Color cor,
    required List<String> badgesUsuario,
  }) {
    final bool isUnblocked = badgesUsuario.contains(id);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isUnblocked ? Colors.white : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isUnblocked
            ? [
                BoxShadow(
                  color: cor.withOpacity(0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ]
            : [],
        border: Border.all(
          color: isUnblocked ? cor : Colors.grey.shade300,
          width: isUnblocked ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isUnblocked ? cor.withOpacity(0.1) : Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isUnblocked ? icone : Icons.lock_outline_rounded,
              size: 40,
              color: isUnblocked ? cor : Colors.grey.shade500,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nome,
                  style: TextStyle(
                    color: isUnblocked ? AppTheme.textDark : Colors.grey.shade700,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isUnblocked ? descricao : 'Conquista bloqueada. Continue tomando seus remédios!',
                  style: TextStyle(
                    color: isUnblocked ? AppTheme.textMedium : Colors.grey.shade600,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
