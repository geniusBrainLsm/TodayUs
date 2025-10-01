import 'package:flutter/material.dart';

import '../../services/store_service.dart';

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  late Future<StoreOverview> _overviewFuture;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _overviewFuture = StoreService.fetchOverview();
  }

  Future<void> _refresh() async {
    setState(() {
      _overviewFuture = StoreService.fetchOverview();
    });
    await _overviewFuture;
  }

  Future<void> _purchase(StoreRobot robot) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final overview = await StoreService.purchaseRobot(robot.id);
      if (!mounted) return;
      setState(() {
        _overviewFuture = Future.value(overview);
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('새 로봇을 구매했어요.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('구매에 실패했어요: $error')));
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _activate(StoreRobot robot) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final overview = await StoreService.activateRobot(robot.id);
      if (!mounted) return;
      setState(() {
        _overviewFuture = Future.value(overview);
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('선택한 로봇을 적용했어요.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('로봇 전환에 실패했어요: $error')));
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI 로봇 상점'),
        actions: [
          IconButton(
            onPressed: _busy ? null : _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<StoreOverview>(
        future: _overviewFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('상점 정보를 불러오지 못했어요.'),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _refresh,
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            );
          }

          final overview = snapshot.data!;

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _BalanceTile(balance: overview.oilBalance),
                const SizedBox(height: 20),
                for (final robot in overview.robots)
                  _RobotTile(
                    robot: robot,
                    busy: _busy,
                    oilBalance: overview.oilBalance,
                    onPurchase: () => _purchase(robot),
                    onActivate: () => _activate(robot),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _BalanceTile extends StatelessWidget {
  final int balance;
  const _BalanceTile({required this.balance});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFF111827),
      ),
      child: Row(
        children: [
          const Icon(Icons.opacity, size: 32, color: Colors.amber),
          const SizedBox(width: 12),
          Text(
            ' OIL',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _RobotTile extends StatelessWidget {
  final StoreRobot robot;
  final bool busy;
  final int oilBalance;
  final VoidCallback onPurchase;
  final VoidCallback onActivate;

  const _RobotTile({
    required this.robot,
    required this.busy,
    required this.oilBalance,
    required this.onPurchase,
    required this.onActivate,
  });

  @override
  Widget build(BuildContext context) {
    final owned = robot.owned;
    final canBuy = oilBalance >= robot.priceOil;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: robot.active
              ? Theme.of(context).colorScheme.primary
              : Colors.grey.shade200,
        ),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _RobotAvatar(url: robot.imageUrl),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      robot.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    if ((robot.tagline ?? '').isNotEmpty)
                      Text(robot.tagline!, style: const TextStyle(color: Colors.black54)),
                  ],
                ),
              ),
              _PriceChip(price: robot.priceOil),
            ],
          ),
          if ((robot.description ?? '').isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(robot.description!, style: const TextStyle(fontSize: 13)),
          ],
          const SizedBox(height: 12),
          FilledButton(
            onPressed: busy
                ? null
                : owned
                    ? (robot.active ? null : onActivate)
                    : (canBuy ? onPurchase : null),
            child: Text(
              owned
                  ? (robot.active ? '사용 중' : '이 로봇 사용하기')
                  : (canBuy ? '구매하기' : '오일이 부족해요'),
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceChip extends StatelessWidget {
  final int price;
  const _PriceChip({required this.price});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.amber.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.opacity, size: 16, color: Colors.deepOrange),
          const SizedBox(width: 4),
          Text(
            '',
            style: const TextStyle(
              color: Colors.deepOrange,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _RobotAvatar extends StatelessWidget {
  final String? url;
  const _RobotAvatar({this.url});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: url != null && url!.isNotEmpty
          ? Image.network(
              url!,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _placeholder(),
            )
          : _placeholder(),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 60,
      height: 60,
      color: Colors.grey.shade200,
      alignment: Alignment.center,
      child: const Icon(Icons.smart_toy, color: Colors.black45),
    );
  }
}
