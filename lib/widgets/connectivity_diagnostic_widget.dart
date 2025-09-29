import 'package:flutter/material.dart';
import '../services/api_service_improved.dart';
import '../config/app_config.dart';

/// Widget para diagnosticar problemas de conectividad
class ConnectivityDiagnosticWidget extends StatefulWidget {
  const ConnectivityDiagnosticWidget({super.key});

  @override
  State<ConnectivityDiagnosticWidget> createState() => _ConnectivityDiagnosticWidgetState();
}

class _ConnectivityDiagnosticWidgetState extends State<ConnectivityDiagnosticWidget> {
  Map<String, dynamic>? _diagnostic;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _runDiagnostic();
  }

  Future<void> _runDiagnostic() async {
    setState(() {
      _isLoading = true;
      _diagnostic = null;
    });

    try {
      final apiService = ApiService();
      final result = await apiService.diagnoseConnectivity();
      setState(() {
        _diagnostic = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _diagnostic = {
          'error': e.toString(),
          'suggestions': ['❌ Error al ejecutar diagnóstico: $e'],
        };
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Diagnóstico de Conectividad'),
        actions: [
          IconButton(
            onPressed: _runDiagnostic,
            icon: const Icon(Icons.refresh),
            tooltip: 'Ejecutar diagnóstico nuevamente',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildConfigurationCard(),
            const SizedBox(height: 16),
            _buildDiagnosticCard(),
            const SizedBox(height: 16),
            _buildSuggestionsCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigurationCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '⚙️ Configuración Actual',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildConfigItem('URL Base', AppConfig.baseUrl),
            _buildConfigItem('Timeout', '${AppConfig.defaultTimeout.inSeconds}s'),
            _buildConfigItem('Máx. Reintentos', '${AppConfig.maxRetries}'),
            _buildConfigItem('Delay entre reintentos', '${AppConfig.retryDelay.inSeconds}s'),
            _buildConfigItem('Diagnóstico habilitado', '${AppConfig.enableConnectivityCheck}'),
            const SizedBox(height: 12),
            const Text(
              'URLs Alternativas:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            ...AppConfig.alternativeUrls.map((url) => Padding(
              padding: const EdgeInsets.only(left: 16, top: 4),
              child: Text('• $url'),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildDiagnosticCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  '🔬 Resultado del Diagnóstico',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (_isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (_diagnostic != null) ...[
              _buildDiagnosticItem(
                '🌐 Conexión a Internet',
                _diagnostic!['internetConnection'] ?? false,
              ),
              _buildDiagnosticItem(
                '🖥️ Servidor Principal',
                _diagnostic!['primaryServerReachable'] ?? false,
              ),
              if (_diagnostic!['alternativeUrlFound'] != null)
                _buildDiagnosticItem(
                  '🔄 URL Alternativa',
                  _diagnostic!['alternativeUrlFound'] ?? false,
                ),
              if (_diagnostic!['endpointTest'] != null) ...[
                _buildDiagnosticItem(
                  '🎯 Test de Endpoint',
                  _diagnostic!['endpointTest']['success'] ?? false,
                ),
                if (_diagnostic!['endpointTest']['responseTime'] != null)
                  _buildDiagnosticDetail(
                    'Tiempo de respuesta',
                    '${_diagnostic!['endpointTest']['responseTime']}ms',
                  ),
              ],
              const Divider(),
              _buildDiagnosticDetail('Plataforma', _diagnostic!['platform'] ?? 'N/A'),
              _buildDiagnosticDetail('Es Emulador', '${_diagnostic!['isEmulator'] ?? 'N/A'}'),
              if (_diagnostic!['totalDiagnosticTime'] != null)
                _buildDiagnosticDetail(
                  'Tiempo total',
                  '${_diagnostic!['totalDiagnosticTime']}ms',
                ),
              if (_diagnostic!['timestamp'] != null)
                _buildDiagnosticDetail(
                  'Ejecutado',
                  _formatTimestamp(_diagnostic!['timestamp']),
                ),
            ] else if (_isLoading) ...[
              const Center(child: Text('Ejecutando diagnóstico...')),
            ] else ...[
              const Center(child: Text('No hay datos de diagnóstico')),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDiagnosticItem(String label, bool status) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            status ? Icons.check_circle : Icons.error,
            color: status ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
          Text(
            status ? 'OK' : 'FALLO',
            style: TextStyle(
              color: status ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiagnosticDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildSuggestionsCard() {
    if (_diagnostic == null || _diagnostic!['suggestions'] == null) {
      return const SizedBox.shrink();
    }

    final suggestions = _diagnostic!['suggestions'] as List<String>;
    if (suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '💡 Sugerencias',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...suggestions.map((suggestion) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                  Expanded(child: Text(suggestion)),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      return '${dateTime.hour.toString().padLeft(2, '0')}:'
             '${dateTime.minute.toString().padLeft(2, '0')}:'
             '${dateTime.second.toString().padLeft(2, '0')}';
    } catch (e) {
      return timestamp;
    }
  }
}