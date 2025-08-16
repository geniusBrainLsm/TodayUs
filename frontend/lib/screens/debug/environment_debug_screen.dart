import 'package:flutter/material.dart';
import '../../config/environment.dart';
import '../../services/cors_test_service.dart';

/// 환경 설정 디버그 화면
class EnvironmentDebugScreen extends StatefulWidget {
  const EnvironmentDebugScreen({super.key});

  @override
  State<EnvironmentDebugScreen> createState() => _EnvironmentDebugScreenState();
}

class _EnvironmentDebugScreenState extends State<EnvironmentDebugScreen> {
  Map<String, dynamic>? _corsTestResults;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('환경 설정'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '현재 환경 설정',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow('환경', EnvironmentConfig.current.name),
                    _buildInfoRow('Base URL', EnvironmentConfig.baseUrl),
                    _buildInfoRow('로깅 활성화', EnvironmentConfig.enableLogging.toString()),
                    _buildInfoRow('디버그 모드', EnvironmentConfig.enableDebugMode.toString()),
                    _buildInfoRow('API 타임아웃', '${EnvironmentConfig.apiTimeout}ms'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '환경 변경',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildEnvironmentButton(
              title: '개발 환경 (로컬)',
              subtitle: 'http://10.0.2.2:8080 (에뮬레이터)',
              environment: Environment.development,
              color: Colors.blue,
            ),
            const SizedBox(height: 8),
            _buildEnvironmentButton(
              title: '스테이징 환경',
              subtitle: 'Railway 스테이징 서버',
              environment: Environment.staging,
              color: Colors.orange,
            ),
            const SizedBox(height: 8),
            _buildEnvironmentButton(
              title: '프로덕션 환경',
              subtitle: 'Railway 프로덕션 서버',
              environment: Environment.production,
              color: Colors.red,
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),
            const Text(
              '실제 디바이스 테스트',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '실제 Android/iOS 디바이스에서 테스트하려면:\n'
              '1. PC의 IP 주소를 확인하세요 (예: 192.168.1.100)\n'
              '2. environment.dart의 baseUrlRealDevice를 수정하세요\n'
              '3. 백엔드 서버가 해당 IP로 접근 가능한지 확인하세요',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                _showRealDeviceInstructions();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
              ),
              child: const Text('실제 디바이스 설정 가이드'),
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),
            const Text(
              'CORS 테스트',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'API 서버와의 CORS 연결을 테스트합니다.\n'
              '현재 환경에서 서버 연결이 정상적으로 작동하는지 확인하세요.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _runCorsTests(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('CORS 테스트 실행'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _showCorsTestResults(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('테스트 결과 보기'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnvironmentButton({
    required String title,
    required String subtitle,
    required Environment environment,
    required Color color,
  }) {
    final isCurrentEnv = EnvironmentConfig.current == environment;
    
    return Container(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isCurrentEnv ? null : () {
          setState(() {
            EnvironmentConfig.setCurrent(environment);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('환경이 $title으로 변경되었습니다.'),
              backgroundColor: color,
              action: SnackBarAction(
                label: '재시작 필요',
                textColor: Colors.white,
                onPressed: () {
                  // 앱 재시작 안내
                  _showRestartDialog();
                },
              ),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isCurrentEnv ? Colors.grey : color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.all(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                if (isCurrentEnv) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.check_circle, size: 20),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  void _showRealDeviceInstructions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('실제 디바이스 테스트 설정'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '1. PC의 로컬 IP 주소 확인:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('• Windows: cmd에서 "ipconfig" 실행'),
              Text('• Mac/Linux: 터미널에서 "ifconfig" 실행'),
              Text('• 예: 192.168.1.100'),
              SizedBox(height: 12),
              Text(
                '2. 환경 설정 파일 수정:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('• frontend/lib/config/environment.dart 열기'),
              Text('• baseUrlRealDevice를 PC IP로 변경'),
              Text('• 예: "http://192.168.1.100:8080"'),
              SizedBox(height: 12),
              Text(
                '3. 네트워크 설정 확인:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('• PC와 모바일이 같은 WiFi에 연결'),
              Text('• 백엔드 서버가 실행 중인지 확인'),
              Text('• 방화벽이 8080 포트를 허용하는지 확인'),
              SizedBox(height: 12),
              Text(
                '4. 디바이스에서 테스트:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('• Flutter 앱을 실제 디바이스에 설치'),
              Text('• 개발 환경으로 설정 후 테스트'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  void _showRestartDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('앱 재시작 필요'),
        content: const Text(
          '환경 변경을 완전히 적용하려면 앱을 완전히 종료한 후 다시 시작해주세요.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  Future<void> _runCorsTests() async {
    // 로딩 다이얼로그 표시
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('CORS 테스트 실행 중...'),
          ],
        ),
      ),
    );

    try {
      final results = await CorsTestService.runAllTests();
      setState(() {
        _corsTestResults = results;
      });

      Navigator.pop(context); // 로딩 다이얼로그 닫기

      // 결과 다이얼로그 표시
      _showCorsTestResults();
    } catch (e) {
      Navigator.pop(context); // 로딩 다이얼로그 닫기
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('CORS 테스트 중 오류 발생: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showCorsTestResults() {
    if (_corsTestResults == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('먼저 CORS 테스트를 실행해주세요.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('CORS 테스트 결과'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTestSummary(),
              const SizedBox(height: 16),
              _buildTestResult('단순 GET 테스트', _corsTestResults!['simpleGet']),
              const SizedBox(height: 8),
              _buildTestResult('Preflight POST 테스트', _corsTestResults!['preflight']),
              const SizedBox(height: 8),
              _buildTestResult('인증 테스트', _corsTestResults!['auth']),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
          TextButton(
            onPressed: () => _runCorsTests(),
            child: const Text('다시 테스트'),
          ),
        ],
      ),
    );
  }

  Widget _buildTestSummary() {
    final summary = _corsTestResults!['summary'] as Map<String, dynamic>;
    final successCount = summary['successCount'] as int;
    final totalTests = summary['totalTests'] as int;
    final isAllSuccess = successCount == totalTests;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isAllSuccess ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isAllSuccess ? Colors.green : Colors.red,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isAllSuccess ? Icons.check_circle : Icons.error,
            color: isAllSuccess ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '테스트 완료: $successCount/$totalTests 성공',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isAllSuccess ? Colors.green : Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestResult(String testName, Map<String, dynamic> result) {
    final isSuccess = result['success'] as bool;
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isSuccess ? Icons.check : Icons.close,
                color: isSuccess ? Colors.green : Colors.red,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                testName,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (isSuccess) ...[
            if (result['statusCode'] != null)
              Text('상태 코드: ${result['statusCode']}', style: const TextStyle(fontSize: 12)),
          ] else ...[
            Text(
              '오류: ${result['error']}',
              style: const TextStyle(fontSize: 12, color: Colors.red),
            ),
          ],
        ],
      ),
    );
  }
}