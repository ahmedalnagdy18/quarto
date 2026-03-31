import 'package:flutter/material.dart';
import 'package:quarto/features/cafe/data/model/cafe_tabels_model.dart';
import 'package:quarto/features/cafe/data/model/order_model.dart';
import 'package:quarto/features/cafe/domain/repository/cafe_repository.dart';
import 'package:quarto/features/cafe/presentation/utils/cafe_order_utils.dart';
import 'package:quarto/features/dashboard/presentation/widgets/button_widget.dart';
import 'package:quarto/injection_container.dart';

class OrdersDetailsPage extends StatefulWidget {
  const OrdersDetailsPage({super.key});

  @override
  State<OrdersDetailsPage> createState() => _OrdersDetailsPageState();
}

class _OrdersDetailsPageState extends State<OrdersDetailsPage> {
  final CafeRepository _cafeRepository = sl<CafeRepository>();
  List<OrderModel> _orders = const [];
  Map<String, CafeTableModel> _tablesById = const {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
    });

    final orders = await _cafeRepository.getOrders();
    final tables = await _cafeRepository.getTables();

    if (mounted) {
      setState(() {
        _orders = finalizedCafeOrders(orders, tables);
        _tablesById = {for (final table in tables) table.id: table};
        _isLoading = false;
      });
    }
  }

  String _tableLabel(OrderModel order) {
    if (order.tableId == null || order.tableId!.isEmpty) {
      return order.orderType == 'takeaway' ? 'Takeaway' : 'Staff';
    }

    return _tablesById[order.tableId]?.tableName ?? 'Table ${order.tableId}';
  }

  String _orderBadgeText(OrderModel order) {
    if (order.orderType == 'table') {
      return 'Delivered';
    }
    if (order.orderType == 'takeaway') {
      return 'Takeaway';
    }
    return 'Staff order';
  }

  Color _orderBadgeColor(OrderModel order) {
    if (order.orderType == 'table') {
      return const Color(0xFF2CCB63);
    }
    if (order.orderType == 'takeaway') {
      return const Color(0xFF3D6BFF);
    }
    return const Color(0xFFF4A51C);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: Image.asset('images/bg.png', fit: BoxFit.cover),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Image.asset('images/quarto_logo.png', scale: 4),
                      const Spacer(),
                      ExportButtonsWidget(
                        title: 'Export Orders history',
                        icon: Icons.download_outlined,
                        onPressed: () {},
                      ),
                      const SizedBox(width: 14),
                      ExportButtonsWidget(
                        title: 'Filter',
                        icon: Icons.tune,
                        onPressed: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      InkWell(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Recent Cafe Orders',
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 80),
                      child: Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    )
                  else
                    _OrdersStyledTable(
                      orders: _orders,
                      tableLabelBuilder: _tableLabel,
                      badgeTextBuilder: _orderBadgeText,
                      badgeColorBuilder: _orderBadgeColor,
                    ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrdersStyledTable extends StatefulWidget {
  const _OrdersStyledTable({
    required this.orders,
    required this.tableLabelBuilder,
    required this.badgeTextBuilder,
    required this.badgeColorBuilder,
  });

  final List<OrderModel> orders;
  final String Function(OrderModel order) tableLabelBuilder;
  final String Function(OrderModel order) badgeTextBuilder;
  final Color Function(OrderModel order) badgeColorBuilder;

  @override
  State<_OrdersStyledTable> createState() => _OrdersStyledTableState();
}

class _OrdersStyledTableState extends State<_OrdersStyledTable> {
  static const int _rowsPerPage = 6;
  static const double _rowHeight = 68;
  int _currentPage = 0;

  int get _totalPages {
    if (widget.orders.isEmpty) {
      return 1;
    }
    return (widget.orders.length / _rowsPerPage).ceil();
  }

  List<OrderModel> get _currentPageOrders {
    final start = _currentPage * _rowsPerPage;
    final end = (start + _rowsPerPage).clamp(0, widget.orders.length);
    if (start >= widget.orders.length) {
      return const [];
    }
    return widget.orders.sublist(start, end);
  }

  @override
  void didUpdateWidget(covariant _OrdersStyledTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_currentPage >= _totalPages) {
      _currentPage = _totalPages - 1;
    }
  }

  void _goToPage(int page) {
    if (page < 0 || page >= _totalPages) return;
    setState(() {
      _currentPage = page;
    });
  }

  List<int> get _visiblePages {
    if (_totalPages <= 4) {
      return List.generate(_totalPages, (index) => index);
    }

    if (_currentPage <= 1) {
      return [0, 1, 2, _totalPages - 1];
    }

    if (_currentPage >= _totalPages - 2) {
      return [0, _totalPages - 3, _totalPages - 2, _totalPages - 1];
    }

    return [0, _currentPage, _currentPage + 1, _totalPages - 1];
  }

  @override
  Widget build(BuildContext context) {
    final bodyHeight = _rowsPerPage * _rowHeight;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0x1F2B2F68),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            decoration: const BoxDecoration(
              color: Color(0x8A31346C),
              borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: const Row(
              children: [
                _HeaderCell(flex: 1, text: '#'),
                _HeaderCell(flex: 3, text: 'Date'),
                _HeaderCell(flex: 3, text: 'Table'),
                _HeaderCell(flex: 3, text: 'Order'),
                _HeaderCell(flex: 2, text: 'Payment Method'),
                _HeaderCell(flex: 2, text: 'Total cost'),
                _HeaderCell(flex: 1, text: 'Action'),
              ],
            ),
          ),
          SizedBox(
            height: bodyHeight,
            child: widget.orders.isEmpty
                ? const Center(
                    child: Text(
                      'No cafe orders yet',
                      style: TextStyle(color: Colors.white70),
                    ),
                  )
                : Column(
                    children: List.generate(_rowsPerPage, (rowIndex) {
                      if (rowIndex >= _currentPageOrders.length) {
                        return Expanded(
                          child: Container(
                            decoration: const BoxDecoration(
                              border: Border(
                                top: BorderSide(color: Colors.white24),
                              ),
                            ),
                          ),
                        );
                      }

                      final order = _currentPageOrders[rowIndex];
                      final globalIndex =
                          (_currentPage * _rowsPerPage) + rowIndex;
                      final badgeColor = widget.badgeColorBuilder(order);

                      return Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: globalIndex.isEven
                                ? const Color(0x332B2F57)
                                : const Color(0x22232846),
                            border: const Border(
                              top: BorderSide(color: Colors.white24),
                            ),
                          ),
                          child: Row(
                            children: [
                              _BodyCell(
                                flex: 1,
                                child: _PlainText('${globalIndex + 1}'),
                              ),
                              _BodyCell(
                                flex: 3,
                                child: _PlainText(
                                  '${formatOrderDate(order.orderTime)} - ${formatOrderTime(order.orderTime)}',
                                ),
                              ),
                              _BodyCell(
                                flex: 3,
                                child: _PlainText(
                                  widget.tableLabelBuilder(order),
                                ),
                              ),
                              _BodyCell(
                                flex: 3,
                                child: Align(
                                  alignment: Alignment.center,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 7,
                                    ),
                                    decoration: BoxDecoration(
                                      color: badgeColor,
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    child: Text(
                                      '${widget.badgeTextBuilder(order)} (${order.items.length} items)',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ),
                              const _BodyCell(
                                flex: 2,
                                child: Align(
                                  alignment: Alignment.center,
                                  child: _PaymentChip(label: '--'),
                                ),
                              ),
                              _BodyCell(
                                flex: 2,
                                child: _PlainText(
                                  '${calculateOrderTotal(order).toStringAsFixed(0)} EGP',
                                ),
                              ),
                              const _BodyCell(
                                flex: 1,
                                child: Align(
                                  alignment: Alignment.center,
                                  child: Icon(
                                    Icons.remove_red_eye_outlined,
                                    color: Color(0xFFFFC400),
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: _currentPage == 0
                      ? null
                      : () => _goToPage(_currentPage - 1),
                  child: Icon(
                    Icons.arrow_back,
                    color: _currentPage == 0 ? Colors.white30 : Colors.white70,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                ..._buildPageButtons(),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _currentPage >= _totalPages - 1
                      ? null
                      : () => _goToPage(_currentPage + 1),
                  child: Icon(
                    Icons.arrow_forward,
                    color: _currentPage >= _totalPages - 1
                        ? Colors.white30
                        : Colors.white70,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPageButtons() {
    if (_totalPages == 0) {
      return [const _PageChip(label: '1', active: true)];
    }

    final widgets = <Widget>[];
    final pages = _visiblePages;
    var previous = -1;

    for (final page in pages) {
      if (previous != -1 && page - previous > 1) {
        widgets.add(const _PageChip(label: '...'));
        widgets.add(const SizedBox(width: 8));
      }

      widgets.add(
        GestureDetector(
          onTap: () => _goToPage(page),
          child: _PageChip(
            label: '${page + 1}',
            active: page == _currentPage,
          ),
        ),
      );
      widgets.add(const SizedBox(width: 8));
      previous = page;
    }

    if (widgets.isNotEmpty) {
      widgets.removeLast();
    }

    return widgets;
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell({required this.flex, required this.text});

  final int flex;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _BodyCell extends StatelessWidget {
  const _BodyCell({required this.flex, required this.child});

  final int flex;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Expanded(flex: flex, child: child);
  }
}

class _PlainText extends StatelessWidget {
  const _PlainText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class _PaymentChip extends StatelessWidget {
  const _PaymentChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2F38C9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _PageChip extends StatelessWidget {
  const _PageChip({required this.label, this.active = false});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active ? const Color(0xFFFFC400) : const Color(0x1FFFFFFF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white24),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: active ? Colors.black : Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
