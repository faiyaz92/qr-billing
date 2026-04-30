import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/billing_cubit.dart';

class CartWidget extends StatelessWidget {
  const CartWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BillingCubit, BillingState>(
      builder: (context, state) {
        if (state is BillingUpdated) {
          return Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Cart Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: const BoxDecoration(
                    color: Color(0xFF1E40AF),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.shopping_cart, color: Colors.white),
                      const SizedBox(width: 12),
                      Text(
                        'Cart Items (${state.cart.length})',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      if (state.cart.isNotEmpty)
                        TextButton.icon(
                          onPressed: () => context.read<BillingCubit>().clearCart(),
                          icon: const Icon(Icons.clear, size: 16, color: Colors.white),
                          label: const Text('Clear All', style: TextStyle(color: Colors.white)),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: state.cart.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'Your cart is empty',
                              style: TextStyle(fontSize: 20, color: Colors.grey, fontWeight: FontWeight.w500),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Scan product QR codes to add items',
                              style: TextStyle(color: Colors.grey),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: state.cart.length,
                        itemBuilder: (context, index) {
                          final item = state.cart[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  // Product Icon (Centered)
                                  Container(
                                    width: 50,
                                    height: 50,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: Colors.blue[100],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.inventory_2,
                                      color: Color(0xFF1E40AF),
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Product Details Column
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // First Row: Product Name and Price
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                item.product.name ?? 'Unknown Product',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              children: [
                                                // MRP with strike through - only show if original price exists and is higher than selling price
                                                if (item.product.originalPrice != null && item.product.originalPrice! > item.product.sellingPrice) ...[
                                                  Text(
                                                    'MRP: ₹${item.product.originalPrice!.toStringAsFixed(0)}',
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey,
                                                      decoration: TextDecoration.lineThrough,
                                                    ),
                                                  ),
                                                ],
                                                // Effective Price
                                                Text(
                                                  'Price: ₹${(item.product.sellingPrice - item.itemDiscount).toStringAsFixed(0)}',
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w500,
                                                    color: Colors.green,
                                                  ),
                                                ),
                                                // You Save - only show if there's actual savings
                                                Builder(
                                                  builder: (context) {
                                                    final originalPrice = item.product.originalPrice ?? item.product.sellingPrice;
                                                    final effectivePrice = item.product.sellingPrice - item.itemDiscount;
                                                    final savingsPerItem = originalPrice - effectivePrice;
                                                    final totalSavings = savingsPerItem * item.quantity;
                                                    if (totalSavings > 0) {
                                                      return Text(
                                                        'You Save: ₹${totalSavings.toStringAsFixed(0)}',
                                                        style: const TextStyle(
                                                          fontSize: 12,
                                                          color: Colors.orange,
                                                          fontWeight: FontWeight.w500,
                                                        ),
                                                      );
                                                    }
                                                    return const SizedBox.shrink();
                                                  },
                                                ),
                                                if (item.product.tax != null && item.product.tax! > 0) ...[
                                                  Text(
                                                    'Tax: ${item.product.tax!.toStringAsFixed(1)}%',
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.blue,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                                if (state.showProfitLossMode) ...[
                                                  Text(
                                                    'Cost: ₹${(item.product.purchasePrice).toStringAsFixed(0)}',
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.blue,
                                                    ),
                                                  ),
                                                  Text(
                                                    'Profit: ₹${(((item.product.sellingPrice - item.itemDiscount - item.product.purchasePrice) * item.quantity)).toStringAsFixed(0)}',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: (((item.product.sellingPrice - item.itemDiscount - item.product.purchasePrice) * item.quantity)) >= 0 ? Colors.green : Colors.red,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        // Second Row: Plus Minus and Delete Button
                                        Row(
                                          children: [
                                            // Quantity Controls
                                            Container(
                                              decoration: BoxDecoration(
                                                border: Border.all(color: Colors.grey[300]!),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  IconButton(
                                                    icon: const Icon(Icons.remove, size: 16),
                                                    onPressed: () => context.read<BillingCubit>().updateQuantity(index, -1),
                                                    padding: const EdgeInsets.all(2),
                                                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                                  ),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      border: Border.symmetric(
                                                        vertical: BorderSide(color: Colors.grey[300]!),
                                                      ),
                                                    ),
                                                    child: Text(
                                                      '${item.quantity}',
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(Icons.add, size: 16),
                                                    onPressed: () => context.read<BillingCubit>().updateQuantity(index, 1),
                                                    padding: const EdgeInsets.all(2),
                                                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const Spacer(),
                                            IconButton(
                                              icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                              onPressed: () {
                                                showDialog(
                                                  context: context,
                                                  builder: (context) => AlertDialog(
                                                    title: const Text('Remove Item'),
                                                    content: Text('Remove "${item.product.name}" from cart?'),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () => Navigator.pop(context),
                                                        child: const Text('Cancel'),
                                                      ),
                                                      TextButton(
                                                        onPressed: () {
                                                          Navigator.pop(context);
                                                          context.read<BillingCubit>().removeItem(index);
                                                        },
                                                        child: const Text('Remove', style: TextStyle(color: Colors.red)),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              },
                                              padding: const EdgeInsets.all(2),
                                              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        // Item Discount (always visible, read-only)
                                        Row(
                                          children: [
                                            const Text(
                                              'Item Discount:',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: SizedBox(
                                                height: 28,
                                                child: TextField(
                                                  decoration: const InputDecoration(
                                                    hintText: '0.00',
                                                    border: OutlineInputBorder(),
                                                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                    prefixText: '₹',
                                                  ),
                                                  style: const TextStyle(fontSize: 12),
                                                  keyboardType: TextInputType.number,
                                                  onChanged: (value) {
                                                    final discount = double.tryParse(value) ?? 0.0;
                                                    final maxDiscount = item.product.sellingPrice;
                                                    context.read<BillingCubit>().updateItemDiscount(index, discount > maxDiscount ? maxDiscount : discount);
                                                  },
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        // Third Row: Price * Count (left) and Total (right)
                                        Row(
                                          children: [
                                            Text(
                                              '₹${item.product.sellingPrice.toStringAsFixed(0)} × ${item.quantity}',
                                              style: const TextStyle(
                                                color: Colors.grey,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            const Spacer(),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                  '₹${((item.product.sellingPrice - item.itemDiscount) * item.quantity).toStringAsFixed(2)}',
                                                  style: TextStyle(
                                                    color: ((item.product.sellingPrice - item.itemDiscount) * item.quantity) >= (item.product.purchasePrice * item.quantity) ? Colors.green : Colors.orange,
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                if (state.showProfitLossMode && item.itemDiscount > 0) ...[
                                                  Text(
                                                    'After discount',
                                                    style: const TextStyle(
                                                      fontSize: 10,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                ),
              ],
            ),
          );
        }
        return const Center(child: Text('Scan products to start billing'));
      },
    );
  }
}