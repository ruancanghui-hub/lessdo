import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';

class PurchaseService {
  static const productIds = {'lessdo_premium_monthly', 'lessdo_premium_yearly'};

  Future<List<ProductDetails>> loadProducts() async {
    if (!await InAppPurchase.instance.isAvailable()) return const [];
    final response = await InAppPurchase.instance.queryProductDetails(
      productIds,
    );
    return response.productDetails;
  }

  Future<void> buy(ProductDetails product) {
    return InAppPurchase.instance.buyNonConsumable(
      purchaseParam: PurchaseParam(productDetails: product),
    );
  }

  Future<void> restore() => InAppPurchase.instance.restorePurchases();
}
