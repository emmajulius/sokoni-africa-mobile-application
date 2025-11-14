import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../utils/helpers.dart';
import '../../services/analytics_service.dart';
import '../../services/auth_service.dart';
import '../../services/language_service.dart';

class SalesAnalyticsScreen extends StatefulWidget {
  const SalesAnalyticsScreen({super.key});

  @override
  State<SalesAnalyticsScreen> createState() => _SalesAnalyticsScreenState();
}

class _SalesAnalyticsScreenState extends State<SalesAnalyticsScreen> {
  final AnalyticsService _analyticsService = AnalyticsService();
  final AuthService _authService = AuthService();
  final LanguageService _languageService = LanguageService();
  
  Map<String, dynamic>? _analyticsData;
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedPeriod = 'all';
  
  final List<String> _periods = ['daily', 'weekly', 'monthly', 'yearly', 'all'];

  @override
  void initState() {
    super.initState();
    _languageService.addListener(_onLanguageChanged);
    _loadAnalytics();
  }

  @override
  void dispose() {
    _languageService.removeListener(_onLanguageChanged);
    super.dispose();
  }

  void _onLanguageChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadAnalytics() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.initialize();
      if (!_authService.isAuthenticated || !_authService.canSell) {
        final l10n = AppLocalizations.of(context);
        setState(() {
          _isLoading = false;
          _errorMessage = l10n?.needToBeLoggedInAsSeller ?? 'You need to be logged in as a seller to view sales analytics.';
        });
        return;
      }

      final data = await _analyticsService.getSalesAnalytics(period: _selectedPeriod);
      if (mounted) {
        setState(() {
          _analyticsData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        setState(() {
          _isLoading = false;
          _errorMessage = l10n != null 
              ? '${l10n.failedToLoadAnalytics}: ${e.toString()}'
              : 'Failed to load analytics: ${e.toString()}';
        });
      }
    }
  }

  void _onPeriodChanged(String period) {
    setState(() {
      _selectedPeriod = period;
    });
    _loadAnalytics();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    
    return Scaffold(
      backgroundColor: isDark 
          ? const Color(0xFF121212)
          : const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(l10n?.salesAnalytics ?? 'Sales Analytics'),
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadAnalytics,
            tooltip: l10n?.refresh ?? 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? Scaffold(
              backgroundColor: isDark 
                  ? const Color(0xFF121212)
                  : const Color(0xFFF5F7FA),
              body: Center(
                child: CircularProgressIndicator(
                  color: Theme.of(context).primaryColor,
                ),
              ),
            )
          : _errorMessage != null
              ? _buildErrorState(isDark)
              : _analyticsData == null
                  ? _buildEmptyState(isDark)
                  : RefreshIndicator(
                      onRefresh: _loadAnalytics,
                      child: CustomScrollView(
                        slivers: [
                          // Header
                          SliverToBoxAdapter(
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 20.0),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: isDark
                                      ? [
                                          Colors.grey[850]!,
                                          Colors.grey[900]!,
                                        ]
                                      : [
                                          const Color(0xFFF5F7FA),
                                          const Color(0xFFE8ECF1),
                                        ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF9C27B0).withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.analytics_rounded,
                                      size: 32,
                                      color: Color(0xFF9C27B0),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    l10n?.salesAnalytics ?? 'Sales Analytics',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w700,
                                      color: isDark 
                                          ? Colors.white 
                                          : Colors.grey[900],
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    l10n?.trackBusinessPerformance ?? 'Track your business performance',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isDark 
                                          ? Colors.grey[400] 
                                          : Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Period Selector
                          SliverToBoxAdapter(
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: _periods.map((period) {
                                    final isSelected = _selectedPeriod == period;
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 8.0),
                                      child: FilterChip(
                                        label: Text(
                                          _getPeriodLabel(period, l10n),
                                          style: TextStyle(
                                            color: isSelected
                                                ? Colors.white
                                                : (isDark ? Colors.grey[300] : Colors.grey[700]),
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                        ),
                                        selected: isSelected,
                                        onSelected: (selected) {
                                          if (selected) {
                                            _onPeriodChanged(period);
                                          }
                                        },
                                        selectedColor: const Color(0xFF9C27B0),
                                        checkmarkColor: Colors.white,
                                        side: BorderSide(
                                          color: isSelected
                                              ? const Color(0xFF9C27B0)
                                              : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
                                          width: 1,
                                        ),
                                        backgroundColor: isDark 
                                            ? Colors.grey[850]!.withOpacity(0.5)
                                            : Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ),
                          // Summary Cards
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(20.0, 0, 20.0, 16.0),
                              child: _buildSummaryCards(),
                            ),
                          ),
                          // Revenue Chart
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20.0),
                              child: _buildRevenueChart(),
                            ),
                          ),
                          // Order Status Breakdown
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 16.0),
                              child: _buildOrderStatusBreakdown(),
                            ),
                          ),
                          // Top Products
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(20.0, 0, 20.0, 24.0),
                              child: _buildTopProducts(),
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }
  
  String _getPeriodLabel(String period, AppLocalizations? l10n) {
    if (l10n == null) {
      return period[0].toUpperCase() + period.substring(1);
    }
    switch (period) {
      case 'daily':
        return l10n.daily;
      case 'weekly':
        return l10n.weekly;
      case 'monthly':
        return l10n.monthly;
      case 'yearly':
        return l10n.yearly;
      case 'all':
        return l10n.all;
      default:
        return period[0].toUpperCase() + period.substring(1);
    }
  }

  Widget _buildErrorState(bool isDark) {
    final l10n = AppLocalizations.of(context);
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 20.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        Colors.grey[850]!,
                        Colors.grey[900]!,
                      ]
                    : [
                        const Color(0xFFF5F7FA),
                        const Color(0xFFE8ECF1),
                      ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF9C27B0).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.analytics_rounded,
                    size: 32,
                    color: Color(0xFF9C27B0),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n?.salesAnalytics ?? 'Sales Analytics',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: isDark 
                        ? Colors.white 
                        : Colors.grey[900],
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          // Error Content
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.orange[900] : Colors.orange[50])!.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.error_outline_rounded,
                    size: 64,
                    color: isDark ? Colors.orange[300] : Colors.orange[700],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  l10n?.unableToLoadAnalytics ?? 'Unable to load analytics',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.grey[900],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _loadAnalytics,
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(
                      l10n?.retry ?? 'Retry',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF9800),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmptyState(bool isDark) {
    final l10n = AppLocalizations.of(context);
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 20.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        Colors.grey[850]!,
                        Colors.grey[900]!,
                      ]
                    : [
                        const Color(0xFFF5F7FA),
                        const Color(0xFFE8ECF1),
                      ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF9C27B0).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.analytics_rounded,
                    size: 32,
                    color: Color(0xFF9C27B0),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n?.salesAnalytics ?? 'Sales Analytics',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: isDark 
                        ? Colors.white 
                        : Colors.grey[900],
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          // Empty Content
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.grey[850] : Colors.grey[100])!.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.bar_chart_rounded,
                    size: 64,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  l10n?.noAnalyticsDataAvailable ?? 'No analytics data available',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.grey[900],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n?.salesDataWillAppearHere ?? 'Sales data will appear here once you start receiving orders.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    final summary = _analyticsData!['summary'] as Map<String, dynamic>;
    final totalRevenue = (summary['total_revenue'] as num).toDouble();
    final totalOrders = summary['total_orders'] as int;
    final avgOrderValue = (summary['average_order_value'] as num).toDouble();
    final totalProductsSold = summary['total_products_sold'] as int;
    final uniqueCustomers = summary['unique_customers'] as int;
    final revenueGrowth = (summary['revenue_growth'] as num).toDouble();

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: l10n?.totalRevenue ?? 'Total Revenue',
                value: Helpers.formatCurrency(totalRevenue),
                icon: Icons.trending_up_rounded,
                color: const Color(0xFF4CAF50),
                subtitle: revenueGrowth != 0
                    ? '${revenueGrowth >= 0 ? '+' : ''}${revenueGrowth.toStringAsFixed(1)}%'
                    : null,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: l10n?.totalOrders ?? 'Total Orders',
                value: totalOrders.toString(),
                icon: Icons.shopping_bag_rounded,
                color: const Color(0xFF2196F3),
                isDark: isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: l10n?.avgOrderValue ?? 'Avg Order Value',
                value: Helpers.formatCurrency(avgOrderValue),
                icon: Icons.analytics_rounded,
                color: const Color(0xFFFF9800),
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: l10n?.productsSold ?? 'Products Sold',
                value: totalProductsSold.toString(),
                icon: Icons.inventory_2_rounded,
                color: const Color(0xFF9C27B0),
                isDark: isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: l10n?.customers ?? 'Customers',
                value: uniqueCustomers.toString(),
                icon: Icons.people_rounded,
                color: const Color(0xFF00BCD4),
                isDark: isDark,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    String? subtitle,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  Colors.grey[850]!.withOpacity(0.7),
                  Colors.grey[850]!.withOpacity(0.5),
                ]
              : [
                  Colors.white,
                  Colors.grey[50]!,
                ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark 
              ? Colors.grey[800]!
              : Colors.grey[200]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                if (subtitle != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: color.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: color,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                fontWeight: FontWeight.w500,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.grey[900],
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueChart() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final timeSeriesData = _analyticsData!['time_series'];
    
    // Check if time series data is valid
    List<dynamic> timeSeries = [];
    if (timeSeriesData != null && timeSeriesData is List) {
      timeSeries = timeSeriesData;
    }
    
    // Extract revenue values
    final revenues = timeSeries
        .map((item) {
          if (item is! Map) return 0.0;
          final revenue = item['revenue'];
          if (revenue == null) return 0.0;
          if (revenue is num) return revenue.toDouble();
          return 0.0;
        })
        .toList();
    
    // Calculate max revenue (or use 1 if all zeros)
    final maxRevenue = revenues.isNotEmpty && revenues.any((r) => r > 0)
        ? revenues.reduce((a, b) => a > b ? a : b)
        : 1.0;
    
    if (timeSeries.isEmpty || maxRevenue == 0) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    Colors.grey[850]!.withOpacity(0.7),
                    Colors.grey[850]!.withOpacity(0.5),
                  ]
                : [
                    Colors.white,
                    Colors.grey[50]!,
                  ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark 
                ? Colors.grey[800]!
                : Colors.grey[200]!,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.bar_chart_rounded,
                      color: Color(0xFF4CAF50),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    AppLocalizations.of(context)?.salesOverview ?? 'Sales Overview',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.grey[900],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 200,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.bar_chart_rounded,
                        size: 64,
                        color: isDark ? Colors.grey[600] : Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        AppLocalizations.of(context)?.noSalesDataForPeriod ?? 'No sales data available for this period',
                        style: TextStyle(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  Colors.grey[850]!.withOpacity(0.7),
                  Colors.grey[850]!.withOpacity(0.5),
                ]
              : [
                  Colors.white,
                  Colors.grey[50]!,
                ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark 
              ? Colors.grey[800]!
              : Colors.grey[200]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.trending_up_rounded,
                    color: Color(0xFF4CAF50),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  AppLocalizations.of(context)?.salesOverview ?? 'Sales Overview',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.grey[900],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 250,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: maxRevenue > 0 ? (maxRevenue / 5).ceil().toDouble() : 1,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: isDark 
                            ? Colors.grey[700]!.withOpacity(0.3)
                            : Colors.grey[300]!.withOpacity(0.5),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: _selectedPeriod == 'daily' || _selectedPeriod == 'weekly' ? 2 : 1,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < timeSeries.length) {
                            final item = timeSeries[index];
                            if (item is! Map) return const Text('');
                            String label = '';
                            if (item.containsKey('date')) {
                              try {
                                final date = DateTime.parse(item['date'].toString());
                                label = '${date.day}/${date.month}';
                              } catch (e) {
                                label = '';
                              }
                            } else if (item.containsKey('month')) {
                              label = item['month'].toString().split('-').last;
                            } else if (item.containsKey('year')) {
                              label = item['year'].toString();
                            }
                            if (label.isEmpty) return const Text('');
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                label,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isDark ? Colors.grey[500] : Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                        interval: maxRevenue > 0 ? (maxRevenue / 5).ceil().toDouble() : 1,
                        getTitlesWidget: (value, meta) {
                          if (maxRevenue == 0 || value <= 0) return const Text('');
                          // Format without symbol for chart labels (abbreviate large numbers)
                          String formatted;
                          if (value >= 1000000) {
                            formatted = '${(value / 1000000).toStringAsFixed(1)}M';
                          } else if (value >= 1000) {
                            formatted = '${(value / 1000).toStringAsFixed(1)}K';
                          } else {
                            formatted = value.toStringAsFixed(0);
                          }
                          return Text(
                            formatted,
                            style: TextStyle(
                              fontSize: 10,
                              color: isDark ? Colors.grey[500] : Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(
                      color: isDark 
                          ? Colors.grey[700]!
                          : Colors.grey[300]!,
                      width: 1,
                    ),
                  ),
                  minX: 0,
                  maxX: (timeSeries.length - 1).toDouble(),
                  minY: 0,
                  maxY: maxRevenue > 0 ? (maxRevenue * 1.2).ceil().toDouble() : 10,
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (touchedSpot) => isDark 
                          ? Colors.grey[800]! 
                          : Colors.grey[900]!,
                      getTooltipItems: (List<LineBarSpot> touchedSpots) {
                        return touchedSpots.map((LineBarSpot touchedSpot) {
                          final index = touchedSpot.x.toInt();
                          if (index >= 0 && index < timeSeries.length) {
                            final item = timeSeries[index];
                            if (item is! Map) return null;
                            final revenueValue = item['revenue'];
                            if (revenueValue == null) return null;
                            final revenue = revenueValue is num 
                                ? revenueValue.toDouble() 
                                : 0.0;
                            return LineTooltipItem(
                              Helpers.formatCurrency(revenue),
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            );
                          }
                          return null;
                        }).toList();
                      },
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: timeSeries.asMap().entries.map((entry) {
                        final item = entry.value;
                        double revenue = 0.0;
                        if (item is Map) {
                          final revenueValue = item['revenue'];
                          if (revenueValue != null && revenueValue is num) {
                            revenue = revenueValue.toDouble();
                          }
                        }
                        return FlSpot(
                          entry.key.toDouble(),
                          revenue,
                        );
                      }).toList(),
                      isCurved: true,
                      color: const Color(0xFF4CAF50),
                      barWidth: 3.5,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: const Color(0xFF4CAF50),
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            const Color(0xFF4CAF50).withOpacity(0.3),
                            const Color(0xFF4CAF50).withOpacity(0.05),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getStatusLabel(String status, AppLocalizations? l10n) {
    if (l10n == null) {
      final statusLabels = {
        'pending': 'Pending',
        'confirmed': 'Confirmed',
        'processing': 'Processing',
        'shipped': 'Shipped',
        'delivered': 'Delivered',
        'cancelled': 'Cancelled',
      };
      return statusLabels[status] ?? status;
    }
    switch (status) {
      case 'pending':
        return l10n.pending;
      case 'confirmed':
        return l10n.confirmed;
      case 'processing':
        return l10n.processing;
      case 'shipped':
        return l10n.shipped;
      case 'delivered':
        return l10n.delivered;
      case 'cancelled':
        return l10n.cancelled;
      default:
        return status;
    }
  }

  Widget _buildOrderStatusBreakdown() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusBreakdownData = _analyticsData!['order_status_breakdown'];
    if (statusBreakdownData == null || statusBreakdownData is! Map) {
      return const SizedBox.shrink();
    }
    
    final statusBreakdown = statusBreakdownData as Map<String, dynamic>;
    if (statusBreakdown.isEmpty) {
      return const SizedBox.shrink();
    }

    final ordersList = statusBreakdown.values
        .whereType<int>()
        .toList();
    
    if (ordersList.isEmpty) {
      return const SizedBox.shrink();
    }

    final totalOrders = ordersList.reduce((a, b) => a + b);

    final statusColors = {
      'pending': const Color(0xFFFF9800),
      'confirmed': const Color(0xFF2196F3),
      'processing': const Color(0xFF9C27B0),
      'shipped': const Color(0xFF00BCD4),
      'delivered': const Color(0xFF4CAF50),
      'cancelled': const Color(0xFFFF5722),
    };

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  Colors.grey[850]!.withOpacity(0.7),
                  Colors.grey[850]!.withOpacity(0.5),
                ]
              : [
                  Colors.white,
                  Colors.grey[50]!,
                ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark 
              ? Colors.grey[800]!
              : Colors.grey[200]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF9C27B0).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.pie_chart_rounded,
                    color: Color(0xFF9C27B0),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  AppLocalizations.of(context)?.orderStatus ?? 'Order Status',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.grey[900],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...statusBreakdown.entries.map((entry) {
              final status = entry.key;
              final count = entry.value as int;
              final percentage = totalOrders > 0 ? (count / totalOrders * 100) : 0.0;
              final color = statusColors[status] ?? Colors.grey;
              final l10n = AppLocalizations.of(context);
              final label = _getStatusLabel(status, l10n);

              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: color.withOpacity(0.4),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              label,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : Colors.grey[900],
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: color.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            '$count (${percentage.toStringAsFixed(1)}%)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: color,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: percentage / 100,
                        backgroundColor: isDark 
                            ? Colors.grey[800]!.withOpacity(0.3)
                            : Colors.grey[200]!.withOpacity(0.5),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                        minHeight: 10,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTopProducts() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topProductsData = _analyticsData!['top_products'];
    if (topProductsData == null || topProductsData is! List) {
      return const SizedBox.shrink();
    }
    
    final topProducts = topProductsData;
    if (topProducts.isEmpty) {
      return const SizedBox.shrink();
    }

    final rankColors = [
      const Color(0xFFFFD700), // Gold for #1
      const Color(0xFFC0C0C0), // Silver for #2
      const Color(0xFFCD7F32), // Bronze for #3
      const Color(0xFF2196F3), // Blue for others
    ];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  Colors.grey[850]!.withOpacity(0.7),
                  Colors.grey[850]!.withOpacity(0.5),
                ]
              : [
                  Colors.white,
                  Colors.grey[50]!,
                ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark 
              ? Colors.grey[800]!
              : Colors.grey[200]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.star_rounded,
                    color: Color(0xFF4CAF50),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  AppLocalizations.of(context)?.topProducts ?? 'Top Products',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.grey[900],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...topProducts.asMap().entries.map((entry) {
              final index = entry.key;
              final product = entry.value;
              if (product is! Map) return const SizedBox.shrink();
              
              final l10n = AppLocalizations.of(context);
              final name = (product['name'] as String?) ?? (l10n?.unknownProduct ?? 'Unknown Product');
              final quantitySold = (product['quantity_sold'] as num?)?.toInt() ?? 0;
              final revenueValue = product['revenue'];
              final revenue = revenueValue is num ? revenueValue.toDouble() : 0.0;
              final rankColor = index < 3 ? rankColors[index] : rankColors[3];

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark 
                      ? Colors.grey[800]!.withOpacity(0.3)
                      : Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark 
                        ? Colors.grey[700]!
                        : Colors.grey[200]!,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: rankColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: rankColor.withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: rankColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.grey[900],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.shopping_cart_rounded,
                                size: 14,
                                color: isDark ? Colors.grey[500] : Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                l10n != null 
                                    ? l10n.sold.replaceAll('{count}', quantitySold.toString())
                                    : '$quantitySold sold',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Icon(
                                Icons.attach_money_rounded,
                                size: 14,
                                color: isDark ? Colors.grey[500] : Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                Helpers.formatCurrency(revenue),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
