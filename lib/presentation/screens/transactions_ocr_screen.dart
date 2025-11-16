import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:local_ocr/core/service_locator.dart';
import 'package:local_ocr/cubit/transaction_ocr/transaction_ocr_cubit.dart';
import 'package:local_ocr/cubit/transaction_ocr/transaction_ocr_state.dart';
import 'package:local_ocr/model/transaction_ocr_model.dart';
import 'package:local_ocr/presentation/widgets/transaction_ocr_card.dart';

class TransactionsOcrScreen extends StatefulWidget {
  const TransactionsOcrScreen({super.key});

  @override
  State<TransactionsOcrScreen> createState() => _TransactionsOcrScreenState();
}

class _TransactionsOcrScreenState extends State<TransactionsOcrScreen> {
  bool isSearching = false;
  int currentTabIndex = 0;
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    sl<TransactionOcrCubit>().loadTransactions();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TransactionOcrCubit, TransactionOcrState>(
      listener: (context, state) {
        if (state.action == "deleted") {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.error != null ? state.error! : "تم حذف المعاملة",
              ),
              backgroundColor: state.error != null ? Colors.red : Colors.orange,
            ),
          );
          sl<TransactionOcrCubit>().resetStatus();
        } else if (state.action == "deleted-all") {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.error != null ? state.error! : "تم حذف جميع المعاملات",
              ),
              backgroundColor: state.error != null ? Colors.red : Colors.orange,
            ),
          );
          sl<TransactionOcrCubit>().resetStatus();
        }
      },
      builder: (context, state) {
        return DefaultTabController(
          length: 4,
          initialIndex: 0,
          child: Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              title:
                  isSearching
                      ? TextField(
                        inputFormatters: [LengthLimitingTextInputFormatter(11)],
                        controller: searchController,
                        autofocus: true,
                        decoration: const InputDecoration(
                          hintText: "ابحث برقم الهاتف...",
                          border: InputBorder.none,
                        ),
                        onChanged: (_) => setState(() {}),
                      )
                      : const Text("المعاملات - OCR"),
              bottom: TabBar(
                onTap: (index) {
                  setState(() {
                    currentTabIndex = index;
                    if (index != 0) {
                      isSearching = false;
                      searchController.clear();
                    }
                  });

                  switch (index) {
                    case 0:
                      sl<TransactionOcrCubit>().setFilter(
                        TransactionFilter.all,
                      );
                      break;
                    case 1:
                      sl<TransactionOcrCubit>().setFilter(
                        TransactionFilter.reviewed,
                      );
                      break;
                    case 2:
                      sl<TransactionOcrCubit>().setFilter(
                        TransactionFilter.notReviewed,
                      );
                      break;
                    case 3:
                      sl<TransactionOcrCubit>().setFilter(
                        TransactionFilter.failed,
                      );
                      break;
                  }
                },
                tabs: const [
                  Tab(text: "الكل"),
                  Tab(text: "تمت المراجعة"),
                  Tab(text: "لم تُراجع"),
                  Tab(text: "فاشل"),
                ],
              ),
              actions: [
                if (currentTabIndex == 0)
                  IconButton(
                    icon: Icon(isSearching ? Icons.close : Icons.search),
                    onPressed: () {
                      setState(() {
                        if (isSearching) searchController.clear();
                        isSearching = !isSearching;
                      });
                    },
                  ),
                if (state.transactions.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.delete_sweep),
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder:
                            (context) => AlertDialog(
                              title: const Text('حذف الكل'),
                              content: const Text(
                                'هل تريد حذف جميع المعاملات؟',
                              ),
                              actions: [
                                TextButton(
                                  onPressed:
                                      () => Navigator.pop(context, false),
                                  child: const Text('إلغاء'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.red,
                                  ),
                                  child: const Text('حذف الكل'),
                                ),
                              ],
                            ),
                      );
                      if (confirmed == true) {
                        sl<TransactionOcrCubit>().deleteAllTransactions();
                      }
                    },
                  ),
              ],
            ),
            backgroundColor: const Color.fromRGBO(247, 247, 247, 1),
            body:
                state.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: BlocBuilder<
                        TransactionOcrCubit,
                        TransactionOcrState
                      >(
                        buildWhen:
                            (prev, curr) =>
                                prev.transactions != curr.transactions ||
                                prev.filter != curr.filter,
                        builder: (context, state) {
                          List<TransactionOcrModel> filtered =
                              state.transactions;

                          if (state.filter == TransactionFilter.reviewed) {
                            filtered =
                                filtered
                                    .where(
                                      (tx) =>
                                          tx.isReviewed &&
                                          tx.status == 'success',
                                    )
                                    .toList();
                          } else if (state.filter ==
                              TransactionFilter.notReviewed) {
                            filtered =
                                filtered
                                    .where(
                                      (tx) =>
                                          !tx.isReviewed &&
                                          tx.status == 'success',
                                    )
                                    .toList();
                          } else if (state.filter == TransactionFilter.failed) {
                            filtered =
                                filtered
                                    .where((tx) => tx.status == 'failed')
                                    .toList();
                          } else if (state.filter == TransactionFilter.all) {
                            filtered =
                                filtered
                                    .where((tx) => tx.status == 'success')
                                    .toList();
                          }

                          if (currentTabIndex == 0 &&
                              isSearching &&
                              searchController.text.isNotEmpty) {
                            final query = searchController.text.trim();
                            filtered =
                                filtered
                                    .where((tx) => tx.phone.contains(query))
                                    .toList();
                          }

                          return filtered.isNotEmpty
                              ? ListView.builder(
                                itemCount: filtered.length,
                                itemBuilder: (context, index) {
                                  final tx = filtered[index];
                                  return TransactionOcrCard(tx);
                                },
                              )
                              : Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.inbox,
                                      size: 80,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'لا يوجد معاملات',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                        },
                      ),
                    ),
          ),
        );
      },
    );
  }
}
