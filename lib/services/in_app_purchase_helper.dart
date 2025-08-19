import 'dart:async';
import 'dart:developer';
import 'package:in_app_purchase/in_app_purchase.dart';

class InAppPurchaseHelper {
  final InAppPurchase _iap = InAppPurchase.instance;
  List<ProductDetails> products = [];
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  Future<bool> checkAvailability() async {
    return await _iap.isAvailable();
  }

  Future<void> initializeProducts() async {
    // Define product IDs matching App Store Connect and Google Play Console
    const Set<String> _productIds = {
      'com_incident_monthly',
      'com_incident_six_monthly',
      'com_incident_yearly'
    };
    final ProductDetailsResponse response =
        await _iap.queryProductDetails(_productIds);
         log("Products found: ${response.productDetails}");

    if (response.notFoundIDs.isNotEmpty) {
     
    }
    products = response.productDetails;


    products.sort((a, b) => _productIds
        .toList()
        .indexOf(a.id)
        .compareTo(_productIds.toList().indexOf(b.id)));

    // Listen to purchase updates
    _subscription?.cancel();
    _subscription = _iap.purchaseStream.listen(_handlePurchaseUpdates);
  }

  void _handlePurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (var purchase in purchases) {
      if (purchase.status == PurchaseStatus.purchased) {
        print("Purchase successful: ${purchase.productID}");
        await _iap.completePurchase(purchase);
      } else if (purchase.status == PurchaseStatus.error) {
        print("Purchase error: ${purchase.error}");
      } else if (purchase.status == PurchaseStatus.canceled) {
        print("Purchase canceled by user");
      }
    }
  }
    startListening() async {
    _subscription = _iap.purchaseStream.listen(
      (purchaseDetailsList) {
        _handlePurchaseUpdates(purchaseDetailsList);
        log("Purchase details===>ttt: ${purchaseDetailsList.first.purchaseID}");
      },
      onDone: () {
        log("Subscription listening completed.");
      },
      onError: (error) {
        log("Error in purchase stream: $error");
      },
      cancelOnError: true,
    );
    log("Started listening for purchases.");
  }


  Future<void> buySubscription(ProductDetails product) async {
    final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);
    await _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  void dispose() {
    _subscription?.cancel();
  }
}
