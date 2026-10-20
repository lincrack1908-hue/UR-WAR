import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../core/theme.dart';

class CreditsScreen extends StatelessWidget {
  const CreditsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CRÉDITOS Y COMUNIDAD')),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          const Center(
            child: Icon(
              Icons.code_rounded,
              size: 64,
              color: AppTheme.accentColor,
            ),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              'Proyecto Open Source',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
          const Center(
            child: Text(
              'Desarrollado con Flutter para todas las plataformas',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          const SizedBox(height: 32),
          const Card(
            color: AppTheme.surfaceColor,
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Forja el futuro del reino',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.accentColor,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'UR WAR es un juego abierto a la comunidad. Puedes agregar nuevos niveles, mejorar el diseño, implementar mecánicas de batalla o agregar soporte multijugador enviando tus Pull Requests.',
                    style: TextStyle(color: Colors.white70, height: 1.4),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Card(
            color: AppTheme.surfaceColor,
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Licencia',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Distribuido bajo la Licencia MIT.',
                    style: TextStyle(color: Colors.white60),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Arte y tipografía',
                    style: TextStyle(
                      fontFamily: 'Cinzel',
                      color: AppTheme.accentColor,
                      fontSize: 17,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Ilustraciones del reino, guardianes y territorios generadas con IA para UR WAR. Figuras y animaciones de combate dibujadas en Canvas. Tipografía Cinzel bajo SIL Open Font License.',
                    style: TextStyle(
                      color: AppTheme.muted,
                      height: 1.5,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          Center(
            child: Text(
              'Versión ${AppConstants.appVersion}',
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
