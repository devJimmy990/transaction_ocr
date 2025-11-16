import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:local_ocr/cubit/transaction_ocr/transaction_ocr_cubit.dart';
import 'package:local_ocr/model/transaction_ocr_model.dart';

class TransactionOcrCard extends StatelessWidget {
  final TransactionOcrModel transaction;

  const TransactionOcrCard(this.transaction, {super.key});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(transaction.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.red[500],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white, size: 30),
      ),
      onDismissed:
          (_) => context.read<TransactionOcrCubit>().deleteTransaction(
            transaction.id,
          ),
      child: Card(
        color: Colors.white,
        shadowColor: Colors.transparent,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  InkWell(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: transaction.phone));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('تم نسخ رقم الهاتف'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Text(
                            transaction.phone,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          const Text(
                            "نسخ",
                            style: TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${transaction.amount} جنيه",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color:
                                transaction.type == "إستقبال"
                                    ? Colors.green
                                    : Colors.redAccent,
                          ),
                        ),
                        Text(
                          transaction.type,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          transaction.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          transaction.date,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  IconButton(
                    onPressed: () {
                      context.read<TransactionOcrCubit>().toggleReviewStatus(
                        transaction.id,
                      );
                    },
                    icon: Icon(
                      transaction.isReviewed ? Icons.star : Icons.star_border,
                      color: Colors.blue,
                      size: 28,
                    ),
                  ),
                ],
              ),

              if (transaction.reference.isNotEmpty) ...[
                const Divider(height: 20),
                Row(
                  children: [
                    const Icon(Icons.receipt, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      'Reference: ${transaction.reference}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
