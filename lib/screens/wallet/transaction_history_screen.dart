import 'package:flutter/material.dart';
import '../../services/wallet_service.dart';
import '../../services/language_service.dart';
import '../../models/wallet_model.dart';
import '../../utils/helpers.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  final WalletService _walletService = WalletService();
  final LanguageService _languageService = LanguageService();
  List<WalletTransactionModel> _transactions = [];
  bool _isLoading = true;
  String? _error;
  WalletTransactionType? _selectedType;
  WalletTransactionStatus? _selectedStatus;
  int _skip = 0;
  final int _limit = 20;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _languageService.addListener(_onLanguageChanged);
    _loadTransactions();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _languageService.removeListener(_onLanguageChanged);
    _scrollController.dispose();
    super.dispose();
  }

  void _onLanguageChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent * 0.8 &&
        !_isLoading &&
        _hasMore) {
      _loadMoreTransactions();
    }
  }

  Future<void> _loadTransactions({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _skip = 0;
        _transactions = [];
        _hasMore = true;
      });
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final transactions = await _walletService.getTransactions(
        skip: _skip,
        limit: _limit,
        transactionType: _selectedType,
        status: _selectedStatus,
      );

      setState(() {
        if (refresh) {
          _transactions = transactions;
        } else {
          _transactions.addAll(transactions);
        }
        _hasMore = transactions.length == _limit;
        _skip += transactions.length;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreTransactions() async {
    if (_isLoading || !_hasMore) return;
    await _loadTransactions();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n?.transactionHistory ?? 'Transaction History'),
            if (_selectedType != null || _selectedStatus != null)
              Text(
                _getActiveFiltersText(l10n),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                ),
              ),
          ],
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: Icon(
                  (_selectedType != null || _selectedStatus != null)
                      ? Icons.filter_list
                      : Icons.filter_list_outlined,
                ),
                onPressed: _showFilterDialog,
                tooltip: l10n?.filterTransactions ?? 'Filter transactions',
              ),
              if (_selectedType != null || _selectedStatus != null)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 8,
                      minHeight: 8,
                    ),
                  ),
                ),
            ],
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'delete_all') {
                _showDeleteAllDialog();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'delete_all',
                child: Row(
                  children: [
                    const Icon(Icons.delete_sweep, color: Colors.red),
                    const SizedBox(width: 8),
                    Text(l10n?.deleteAll ?? 'Delete All'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadTransactions(refresh: true),
        child: _error != null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      l10n?.errorLoadingTransactions ?? 'Error loading transactions',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => _loadTransactions(refresh: true),
                      child: Text(l10n?.retry ?? 'Retry'),
                    ),
                  ],
                ),
              )
            : _transactions.isEmpty && !_isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n?.noTransactionsYet ?? 'No transactions found',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n?.yourTransactionHistoryWillAppearHere ?? 'Your transaction history will appear here',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _transactions.length + (_hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _transactions.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      final transaction = _transactions[index];
                      
                      return Dismissible(
                        key: Key('transaction_${transaction.id}'),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.delete,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        confirmDismiss: (direction) async {
                          return await _confirmDeleteTransaction(transaction);
                        },
                        onDismissed: (direction) {
                          _deleteTransaction(transaction.id);
                        },
                        child: _buildTransactionItem(transaction, l10n),
                      );
                    },
                  ),
      ),
    );
  }

  Widget _buildTransactionItem(WalletTransactionModel transaction, AppLocalizations? l10n) {
    final isDebit = transaction.transactionType == WalletTransactionType.purchase ||
        transaction.transactionType == WalletTransactionType.cashout ||
        transaction.transactionType == WalletTransactionType.fee;
    final isCompleted = transaction.status == WalletTransactionStatus.completed;

    Color statusColor;
    switch (transaction.status) {
      case WalletTransactionStatus.completed:
        statusColor = Colors.green;
        break;
      case WalletTransactionStatus.failed:
        statusColor = Colors.red;
        break;
      case WalletTransactionStatus.pending:
        statusColor = Colors.orange;
        break;
      case WalletTransactionStatus.cancelled:
        statusColor = Colors.grey;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: isDebit ? Colors.red[100] : Colors.green[100],
          child: Icon(
            isDebit ? Icons.arrow_downward : Icons.arrow_upward,
            color: isDebit ? Colors.red : Colors.green,
            size: 20,
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              flex: 1,
              child: Text(
                _getTransactionTitle(transaction, l10n),
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: isCompleted ? null : Colors.grey,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              Helpers.formatDateTime(transaction.createdAt),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    transaction.status.name.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '${isDebit ? '-' : '+'}${transaction.sokocoinAmount.toStringAsFixed(2)} SOK',
                  style: TextStyle(
                    color: isDebit ? Colors.red : Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow(l10n?.type ?? 'Type', transaction.transactionType.name),
                if (transaction.localCurrencyAmount != null)
                  _buildDetailRow(
                    l10n?.amount ?? 'Amount',
                    '${transaction.localCurrencyAmount!.toStringAsFixed(2)} ${transaction.localCurrencyCode ?? ''}',
                  ),
                if (transaction.exchangeRate != null)
                  _buildDetailRow(
                    l10n?.exchangeRate ?? 'Exchange Rate',
                    transaction.exchangeRate!.toStringAsFixed(4),
                  ),
                if (transaction.paymentReference != null)
                  _buildDetailRow(
                    l10n?.reference ?? 'Reference',
                    transaction.paymentReference!,
                  ),
                if (transaction.description != null)
                  _buildDetailRow(l10n?.description ?? 'Description', transaction.description!),
                if (transaction.completedAt != null)
                  _buildDetailRow(
                    l10n?.completed ?? 'Completed',
                    Helpers.formatDateTime(transaction.completedAt!),
                  ),
                // Always show delete button for all transactions
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _confirmDeleteTransaction(transaction).then((confirmed) {
                      if (confirmed == true) {
                        _deleteTransaction(transaction.id);
                      }
                    }),
                    icon: const Icon(Icons.delete, color: Colors.red),
                    label: Text(
                      l10n?.deleteTransaction ?? 'Delete Transaction',
                      style: const TextStyle(color: Colors.red),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  String _getTransactionTitle(WalletTransactionModel transaction, AppLocalizations? l10n) {
    switch (transaction.transactionType) {
      case WalletTransactionType.topup:
        return l10n?.topUpTransaction ?? 'Top-up';
      case WalletTransactionType.cashout:
        return l10n?.cashoutTransaction ?? 'Cashout';
      case WalletTransactionType.purchase:
        return l10n?.purchaseTransaction ?? 'Purchase';
      case WalletTransactionType.earn:
        return l10n?.earnedTransaction ?? 'Earned';
      case WalletTransactionType.refund:
        return l10n?.refundTransaction ?? 'Refund';
      case WalletTransactionType.fee:
        return l10n?.feeTransaction ?? 'Fee';
    }
  }

  String _getActiveFiltersText(AppLocalizations? l10n) {
    List<String> filters = [];
    if (_selectedType != null) {
      filters.add(_getTransactionTypeLabel(_selectedType!, l10n));
    }
    if (_selectedStatus != null) {
      filters.add(_getStatusLabel(_selectedStatus!, l10n));
    }
    return filters.isEmpty ? '' : '${l10n?.filtered ?? 'Filtered'}: ${filters.join(', ')}';
  }

  Future<void> _showFilterDialog() async {
    final l10n = AppLocalizations.of(context);
    WalletTransactionType? selectedType = _selectedType;
    WalletTransactionStatus? selectedStatus = _selectedStatus;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(l10n?.filterTransactions ?? 'Filter Transactions'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Transaction Type Filter
                Text(
                  l10n?.transactionType ?? 'Transaction Type',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                RadioListTile<WalletTransactionType?>(
                  title: Text(l10n?.allTypes ?? 'All Types'),
                  value: null,
                  groupValue: selectedType,
                  onChanged: (value) {
                    setDialogState(() {
                      selectedType = value;
                    });
                  },
                ),
                ...WalletTransactionType.values.map((type) {
                  return RadioListTile<WalletTransactionType?>(
                    title: Text(_getTransactionTypeLabel(type, l10n)),
                    value: type,
                    groupValue: selectedType,
                    onChanged: (value) {
                      setDialogState(() {
                        selectedType = value;
                      });
                    },
                  );
                }),

                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),

                // Status Filter
                Text(
                  l10n?.status ?? 'Status',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                RadioListTile<WalletTransactionStatus?>(
                  title: Text(l10n?.allStatuses ?? 'All Statuses'),
                  value: null,
                  groupValue: selectedStatus,
                  onChanged: (value) {
                    setDialogState(() {
                      selectedStatus = value;
                    });
                  },
                ),
                ...WalletTransactionStatus.values.map((status) {
                  return RadioListTile<WalletTransactionStatus?>(
                    title: Text(_getStatusLabel(status, l10n)),
                    value: status,
                    groupValue: selectedStatus,
                    onChanged: (value) {
                      setDialogState(() {
                        selectedStatus = value;
                      });
                    },
                  );
                }),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, {
                  'type': null,
                  'status': null,
                });
              },
              child: Text(l10n?.clearAll ?? 'Clear All'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n?.cancel ?? 'Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, {
                  'type': selectedType,
                  'status': selectedStatus,
                });
              },
              child: Text(l10n?.apply ?? 'Apply'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedType = result['type'] as WalletTransactionType?;
        _selectedStatus = result['status'] as WalletTransactionStatus?;
      });
      _loadTransactions(refresh: true);
    }
  }

  String _getTransactionTypeLabel(WalletTransactionType type, AppLocalizations? l10n) {
    switch (type) {
      case WalletTransactionType.topup:
        return l10n?.topUpTransaction ?? 'Top-up';
      case WalletTransactionType.cashout:
        return l10n?.cashoutTransaction ?? 'Cashout';
      case WalletTransactionType.purchase:
        return l10n?.purchaseTransaction ?? 'Purchase';
      case WalletTransactionType.earn:
        return l10n?.earnedTransaction ?? 'Earned';
      case WalletTransactionType.refund:
        return l10n?.refundTransaction ?? 'Refund';
      case WalletTransactionType.fee:
        return l10n?.feeTransaction ?? 'Fee';
    }
  }

  String _getStatusLabel(WalletTransactionStatus status, AppLocalizations? l10n) {
    switch (status) {
      case WalletTransactionStatus.completed:
        return l10n?.completed ?? 'Completed';
      case WalletTransactionStatus.pending:
        return l10n?.pending ?? 'Pending';
      case WalletTransactionStatus.failed:
        return l10n?.failed ?? 'Failed';
      case WalletTransactionStatus.cancelled:
        return l10n?.cancelled ?? 'Cancelled';
    }
  }

  Future<bool?> _confirmDeleteTransaction(WalletTransactionModel transaction) async {
    final l10n = AppLocalizations.of(context);
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n?.deleteTransaction ?? 'Delete Transaction'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n?.areYouSureDeleteTransaction ?? 'Are you sure you want to delete this transaction?'),
            const SizedBox(height: 16),
            Text(
              '${l10n?.type ?? 'Type'}: ${_getTransactionTypeLabel(transaction.transactionType, l10n)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              '${l10n?.amount ?? 'Amount'}: ${transaction.sokocoinAmount.toStringAsFixed(2)} SOK',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              '${l10n?.status ?? 'Status'}: ${_getStatusLabel(transaction.status, l10n)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (transaction.status == WalletTransactionStatus.completed) ...[
              const SizedBox(height: 16),
              Text(
                l10n?.noteCompletedTransactionsCannotBeDeleted ?? 'Note: This is a completed transaction. Deleting it will remove it from your history but may affect your records.',
                style: const TextStyle(fontSize: 12, color: Colors.orange),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n?.cancel ?? 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text(l10n?.delete ?? 'Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteTransaction(int transactionId) async {
    try {
      setState(() {
        _isLoading = true;
      });

      final result = await _walletService.deleteTransaction(transactionId);

      if (result['success'] == true) {
        // Remove transaction from list
        setState(() {
          _transactions.removeWhere((t) => t.id == transactionId);
        });

        if (mounted) {
          final l10n = AppLocalizations.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n?.transactionDeletedSuccessfully ?? 'Transaction deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting transaction: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showDeleteAllDialog() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n?.deleteAllTransactions ?? 'Delete All Transactions'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n?.areYouSureDeleteAllTransactions ?? 'Are you sure you want to delete all transactions?',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              l10n?.thisWillDeleteAllFailedCancelledPending ?? 'This will delete all failed, cancelled, and pending transactions.',
            ),
            const SizedBox(height: 8),
            Text(
              l10n?.noteCompletedTransactionsWillBeKept ?? 'Note: Completed transactions will be kept as they affect your wallet balance.',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Text(
              '${l10n?.totalTransactions ?? 'Total transactions'}: ${_transactions.length}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n?.cancel ?? 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text(l10n?.deleteAll ?? 'Delete All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteAllTransactions();
    }
  }

  Future<void> _deleteAllTransactions() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final result = await _walletService.deleteAllTransactions();

      if (result['success'] == true) {
        final deletedCount = result['deleted_count'] as int? ?? 0;

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Deleted $deletedCount transaction(s)'),
              backgroundColor: Colors.green,
            ),
          );
        }

        // Reload transactions
        await _loadTransactions(refresh: true);
        
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting transactions: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

}

