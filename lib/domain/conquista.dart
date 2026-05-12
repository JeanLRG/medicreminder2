import 'package:flutter/material.dart';

class Conquista {
  final String id;
  final String titulo;
  final String descricao;
  final IconData icone;
  final Color cor;

  const Conquista({
    required this.id,
    required this.titulo,
    required this.descricao,
    required this.icone,
    required this.cor,
  });

  static const List<Conquista> todas = [
    Conquista(
      id: 'level_up',
      titulo: 'Subiu de Nível',
      descricao: 'Você alcançou um novo nível de experiência!',
      icone: Icons.trending_up,
      cor: Colors.blue,
    ),
    Conquista(
      id: 'primeira_tomada',
      titulo: '1ª Tomada',
      descricao: 'Você marcou seu 1º remédio tomado!',
      icone: Icons.star_rounded,
      cor: Colors.amber,
    ),
    Conquista(
      id: 'em_chamas',
      titulo: 'Em Chamas',
      descricao: 'Mantendo uso em dia por 3 dias seguidos.',
      icone: Icons.local_fire_department_rounded,
      cor: Colors.orange,
    ),
    Conquista(
      id: 'semana_perfeita',
      titulo: 'Semana Perfeita',
      descricao: 'Incrível! 7 dias garantindo sua saúde.',
      icone: Icons.emoji_events_rounded,
      cor: Colors.purple,
    ),
    Conquista(
      id: 'mestre_da_saude',
      titulo: 'Mestre da Saúde',
      descricao: 'Alcançou o impressionante Nível 10.',
      icone: Icons.diamond_rounded,
      cor: Colors.cyanAccent,
    ),
    Conquista(
      id: 'quinzena_perfeita',
      titulo: 'Quinze Dias',
      descricao: 'Mantendo uso em dia por 15 dias seguidos.',
      icone: Icons.star_border_purple500,
      cor: Colors.deepPurpleAccent,
    ),
    Conquista(
      id: 'mes_perfeito',
      titulo: 'Mês Perfeito',
      descricao: 'Incrível! 30 dias garantindo sua saúde.',
      icone: Icons.workspace_premium,
      cor: Colors.teal,
    ),
    Conquista(
      id: 'veterano',
      titulo: 'Veterano',
      descricao: 'Alcançou o Nível 25.',
      icone: Icons.shield,
      cor: Colors.indigo,
    ),
    Conquista(
      id: 'lenda',
      titulo: 'Lenda da Saúde',
      descricao: 'Alcançou o Nível 50.',
      icone: Icons.local_police,
      cor: Colors.redAccent,
    ),
  ];
}
