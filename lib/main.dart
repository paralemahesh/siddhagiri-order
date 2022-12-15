import 'package:url_launcher/url_launcher.dart' as url_launcher;
import 'package:flutter_launch/flutter_launch.dart' as flutter_launch;
import 'package:html/parser.dart' show parse;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class Product {
  const Product({required this.id, required this.name, required this.url, required this.purchaseOptions});

  final int id;
  final String name;
  final String? url;
  final List<PurchaseOption> purchaseOptions;
}

class PurchaseOption {
  const PurchaseOption({required this.id, required this.quantity, required this.price});

  final int id;
  final String quantity;
  final double price; 
}

typedef CartChangedCallback = Function(Product product, bool inCart);
typedef WhatsappSubmitCallback = Function(String message);
typedef PurchaseOptionChangedCallback = Function(int productId, PurchaseOption purchaseOption);

class ShoppingListItem extends StatelessWidget {
  ShoppingListItem({
    required this.product,
    required this.inCart,
    required this.selectedPurchaseOption,
    required this.onCartChanged,
    required this.onPOCallbackChanged
  }) : super(key: ObjectKey(product));

  final Product product;
  final bool inCart;
  final int selectedPurchaseOption;
  final CartChangedCallback onCartChanged;
  final PurchaseOptionChangedCallback onPOCallbackChanged;

  Color _getColor(BuildContext context) {
    // The theme depends on the BuildContext because different
    // parts of the tree can have different themes.
    // The BuildContext indicates where the build is
    // taking place and therefore which theme to use.

    return inCart
        ? Colors.black54
        : Theme.of(context).primaryColor;
  }

  TextStyle? _getTextStyle(BuildContext context) {
    if (!inCart) return null;

    return const TextStyle(
      color: Colors.black54,
      decoration: TextDecoration.lineThrough,
    );
  }

  
  Widget _getIcon(BuildContext context) {
    return product.url != null ? (
        Image.network(product.url!)
    ) : 
    (
      CircleAvatar(
        backgroundColor: _getColor(context),
        child: Text(product.name[0]),
      )
    );
  }

  DropdownButton _buildDropDown(int productId, int selectedOption, List<PurchaseOption> purchaseOptions) {
    return DropdownButton<PurchaseOption>(
      value: purchaseOptions.firstWhere((element) => element.id == selectedOption),
      icon: const Icon(Icons.arrow_downward),
      elevation: 16,
      style: const TextStyle(color: Colors.deepPurple),
      underline: Container(
        height: 2,
        color: Colors.deepPurpleAccent,
      ),
      onChanged: (PurchaseOption? newValue) {
        if(newValue != null) onPOCallbackChanged(productId, newValue);
      },
      items: purchaseOptions.map((value) {
        return DropdownMenuItem<PurchaseOption>(
          value: value,
          child: Text('${value.price} - ${value.quantity}')
        );
      }).toList()
    );
  }


  @override
  Widget build(BuildContext context) {
    return Row(
      children : [
        Column(
          children : [
            Container(
              child: 
                _getIcon(context)
              
            ),

          ],
        ),
        Expanded(
          child: Column(
            children: [
              Text(
                product.name,
                style: _getTextStyle(context),
              ),
              _buildDropDown(product.id, selectedPurchaseOption, product.purchaseOptions),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [Text("Quantity - 0"), Text("Rs. 0")]
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  FloatingActionButton(
                    onPressed: () {},
                    child: const Icon(Icons.add),
                  ),
                  FloatingActionButton(
                    onPressed: () {},
                    child: const Icon(Icons.remove),
                  )
                ]
              )
            ]
          )
        )
      ],
    );
  }
}

class ShoppingList extends StatefulWidget {
  const ShoppingList({super.key});

  @override
  State<ShoppingList> createState() => _ShoppingListState();
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return 
        ShoppingList();
  }
}

class _ShoppingListState extends State<ShoppingList> {
  late Future<List<Product>> _shoppingCart;

  @override
  void initState() {
    super.initState();
    _shoppingCart = _getProducts();
  }

  Future<String> fetchhtml() async {
    final uri = Uri.https('siddhagirinaturals.com', '/shop/all-vegetables-and-fruits');
    final response = await http.get(uri);

    if (response.statusCode == 200)
      return response.body;
    else
      throw Exception('Failed');
  }

  Future<List<Product>> _getProducts() async {
    final List<Product> products = [];

    final data = await fetchhtml();
    final parsedData = parse(data);
    final figureDetails = parsedData.querySelectorAll('.testimonial-1.mobile_section');
    final figureDetailsCount = figureDetails.length;
    debugPrint("count of veggies in view : $figureDetailsCount");
    
    final veggieNames = figureDetails.map((element) => element.children[0].children[1].children[0].children[0]!.text);
    figureDetails.asMap().forEach((index, fd) {
      var parentRow = fd.children[0];
      var imageSection = parentRow.children[0];
      var detailsSection = parentRow.children[1];

      var imageAnchor = imageSection.children[0];
      var imageTag = imageAnchor.children[0];
      var imageSrc = imageTag.attributes['data-src'];
      debugPrint('-------------- item details ----------------');
      debugPrint('image href $imageSrc');

      var name = detailsSection.children[0].children[0].text;
      var rawPurchaseOptions = detailsSection.children[1].children[0].children.map((po) => po.text);
      debugPrint('name $name');

      List<PurchaseOption> purchaseOptions = [];
      rawPurchaseOptions.toList().asMap().forEach((index, e) {
        var details = e.split('---------');
        var quantity = details[0].trim();
        var priceDetails = details[1].trim();
        var price = double.parse(priceDetails.split(' ')[1]);
        
        purchaseOptions.add(PurchaseOption(id:index, quantity: quantity, price: price));
      });
      
      purchaseOptions.forEach((element) {
        debugPrint('quantity ${element.quantity}');
        debugPrint('price ${element.price}');
      });

      products.add(Product(id: index, name: name, url: imageSrc, purchaseOptions: purchaseOptions));
    });

    return products;
  }

  void _handleCartChanged(Product product, bool inCart) {
    setState(() {
      // When a user changes what's in the cart, you need
      // to change _shoppingCart inside a setState call to
      // trigger a rebuild.
      // The framework then calls build, below,
      // which updates the visual appearance of the app.
    });
  }

  void handleOnSendMessageBtnClick() async {
    flutter_launch.FlutterLaunch.launchWhatsapp(phone: "91**********", message: "Hello\nveggie\t");
  }

  final ButtonStyle style =
      ElevatedButton.styleFrom(textStyle: const TextStyle(fontSize: 20));

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Siddhagiri Order',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Siddhagiri Order'),
        ),
        body: FutureBuilder<List<Product>>(
          future: _shoppingCart,
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data?.isNotEmpty == true) {
              List<Product> data = snapshot.requireData;
              return Column (
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: data.length,
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      shrinkWrap: true,
                      itemBuilder: (context, index) {
                        return ShoppingListItem(
                          product: data[index],
                          inCart: false, 
                          selectedPurchaseOption: 0,
                          onCartChanged: _handleCartChanged,
                          onPOCallbackChanged: ((productId, purchaseOption) {
                            debugPrint(
                                'Purchase option for $productId changed to ${purchaseOption.price } - ${purchaseOption.quantity}');
                          }),
                        );
                      }
                    ),
                  ),
                  ElevatedButton(
                    style: style,
                    onPressed: handleOnSendMessageBtnClick,
                    child: const Text('Send to 9503782370'),
                  ),
                ]
              );
            } else if (snapshot.hasError) {
              return Text('${snapshot.error}');
            }

            // By default, show a loading spinner.
            return const CircularProgressIndicator();
          },
        ),
      ),
    );
  }
}

void main() {
  runApp(const MaterialApp(
    title: 'Shopping App',
    home: const HomePage()
  ));
}
