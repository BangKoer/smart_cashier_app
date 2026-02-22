import 'package:flutter/material.dart';
import 'package:smart_cashier_app/constant/global_variables.dart';
import 'package:smart_cashier_app/constant/utils.dart';
import 'package:smart_cashier_app/models/product.dart';
import 'package:smart_cashier_app/models/category.dart' as categoryProduct;
import 'package:smart_cashier_app/module/products/screens/categories_screen.dart';
import 'package:smart_cashier_app/module/products/services/products_services.dart';
import 'package:smart_cashier_app/utils/format_rupiah.dart' as format;

class ProdutcsScreen extends StatefulWidget {
  const ProdutcsScreen({super.key});

  @override
  State<ProdutcsScreen> createState() => _ProdutcsScreenState();
}

class _ProdutcsScreenState extends State<ProdutcsScreen> {
  final TextEditingController _searchProductController =
      TextEditingController();
  final TextEditingController _barcodeController = TextEditingController();
  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();
  final TextEditingController _purchasedPriceController =
      TextEditingController();
  List<TextEditingController> _unitControllers = [TextEditingController()];
  List<TextEditingController> _unitPriceControllers = [TextEditingController()];
  final ProductServices productServices = ProductServices();
  List<categoryProduct.Category> categories = [];
  String? id_category;
  List<Product> products = [];
  String _searchQuery = '';
  String _selectedCategoryFilter = 'all';
  String _selectedStockFilter = 'all';
  String _selectedSortFilter = 'name_asc';
  static const int _lowStockThreshold = 10;

  Future<void> _refreshProductsScreen() async {
    await getAllProduct();
    await getAllCategories();
  }

  getAllProduct() async {
    products = await productServices.fetchAllProducts(context: context);
    setState(() {});
  }

  getAllCategories() async {
    categories = await productServices.fetchAllCategories(context: context);
    setState(() {});
  }

  void _addUnitField() {
    _unitControllers.add(TextEditingController());
    _unitPriceControllers.add(TextEditingController());
  }

  void _removeUnitField(int index) {
    _unitControllers[index].dispose();
    _unitPriceControllers[index].dispose();
    _unitControllers.removeAt(index);
    _unitPriceControllers.removeAt(index);
  }

  void _resetAddProductForm() {
    _barcodeController.clear();
    _productNameController.clear();
    _stockController.clear();
    _purchasedPriceController.clear();
    id_category = null;

    for (final controller in _unitControllers) {
      controller.dispose();
    }
    for (final controller in _unitPriceControllers) {
      controller.dispose();
    }

    _unitControllers = [TextEditingController()];
    _unitPriceControllers = [TextEditingController()];
  }

  List<Product?> _getFilteredProducts() {
    final filtered = products.where((product) {
      final matchesSearch = _searchQuery.isEmpty ||
          product.productName
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          product.barcode.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesCategory = _selectedCategoryFilter == 'all' ||
          product.idCategory.toString() == _selectedCategoryFilter;

      final matchesStock = switch (_selectedStockFilter) {
        'out_of_stock' => product.stock <= 0,
        'low_stock' => product.stock > 0 && product.stock <= _lowStockThreshold,
        'available' => product.stock > 0,
        _ => true,
      };

      return matchesSearch && matchesCategory && matchesStock;
    }).toList();

    switch (_selectedSortFilter) {
      case 'name_desc':
        filtered.sort((a, b) => b.productName.compareTo(a.productName));
        break;
      case 'price_asc':
        filtered.sort((a, b) => a.purchasedPrice.compareTo(b.purchasedPrice));
        break;
      case 'price_desc':
        filtered.sort((a, b) => b.purchasedPrice.compareTo(a.purchasedPrice));
        break;
      case 'stock_asc':
        filtered.sort((a, b) => a.stock.compareTo(b.stock));
        break;
      case 'stock_desc':
        filtered.sort((a, b) => b.stock.compareTo(a.stock));
        break;
      default:
        filtered.sort((a, b) => a.productName.compareTo(b.productName));
    }

    return filtered.cast<Product?>().toList();
  }

  void _resetTableFilters() {
    setState(() {
      _selectedCategoryFilter = 'all';
      _selectedStockFilter = 'all';
      _selectedSortFilter = 'name_asc';
    });
  }

  void _prepareFormForEdit(Product product) {
    _barcodeController.text = product.barcode;
    _productNameController.text = product.productName;
    _stockController.text = product.stock.toString();
    _purchasedPriceController.text = product.purchasedPrice.toString();
    id_category = product.idCategory.toString();

    for (final controller in _unitControllers) {
      controller.dispose();
    }
    for (final controller in _unitPriceControllers) {
      controller.dispose();
    }

    if (product.units.isEmpty) {
      _unitControllers = [TextEditingController()];
      _unitPriceControllers = [TextEditingController()];
    } else {
      _unitControllers = product.units
          .map((unit) => TextEditingController(text: unit.nameUnit))
          .toList();
      _unitPriceControllers = product.units
          .map((unit) => TextEditingController(text: unit.price.toString()))
          .toList();
    }
  }

  Future<void> _showAddProductDialog({Product? editingProduct}) async {
    await getAllCategories();
    if (!mounted) return;
    _resetAddProductForm();
    if (editingProduct != null) {
      _prepareFormForEdit(editingProduct);
    }
    bool isSubmitting = false;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
            insetPadding: const EdgeInsets.all(20),
            backgroundColor: GlobalVariables.backgroundColor,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            actions: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5)),
                    ),
                    child: const Text("Batal"),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      if (isSubmitting) return;

                      final barcode = _barcodeController.text.trim();
                      final productName = _productNameController.text.trim();
                      final stock = int.tryParse(_stockController.text.trim());
                      final purchasedPrice = double.tryParse(
                          _purchasedPriceController.text.trim());
                      final selectedCategory = id_category;

                      final units = <Map<String, dynamic>>[];
                      for (int i = 0; i < _unitControllers.length; i++) {
                        final unitName = _unitControllers[i].text.trim();
                        final unitPrice = double.tryParse(
                            _unitPriceControllers[i].text.trim());

                        if (unitName.isEmpty || unitPrice == null) {
                          showSnackBar(
                            context,
                            "Please fill all unit names and prices",
                            bgColor: Colors.red,
                          );
                          return;
                        }

                        units.add({
                          "name_unit": unitName,
                          "price": unitPrice,
                          "conversion": 1,
                        });
                      }

                      if (barcode.isEmpty ||
                          productName.isEmpty ||
                          stock == null ||
                          purchasedPrice == null ||
                          selectedCategory == null) {
                        showSnackBar(
                          context,
                          "Please complete all required fields",
                          bgColor: Colors.red,
                        );
                        return;
                      }

                      setDialogState(() => isSubmitting = true);
                      bool isSuccess = false;
                      if (editingProduct == null) {
                        isSuccess = await productServices.addProduct(
                          context: this.context,
                          barcode: barcode,
                          productName: productName,
                          stock: stock,
                          purchasedPrice: purchasedPrice,
                          idCategory: int.parse(selectedCategory),
                          units: units,
                        );
                      } else {
                        isSuccess = await productServices.updateProduct(
                          context: this.context,
                          id: editingProduct.id,
                          barcode: barcode,
                          productName: productName,
                          stock: stock,
                          purchasedPrice: purchasedPrice,
                          idCategory: int.parse(selectedCategory),
                          units: units,
                        );
                      }
                      if (!mounted) return;
                      setDialogState(() => isSubmitting = false);

                      if (isSuccess) {
                        Navigator.pop(context);
                        await getAllProduct();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5)),
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(editingProduct == null ? "Add" : "Update"),
                  ),
                ],
              ),
            ],
            content: Container(
              width: MediaQuery.of(context).size.width * 0.7,
              height: MediaQuery.of(context).size.height * 0.7,
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    editingProduct == null ? "Add Product" : "Edit Product",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Form(
                        child: Column(
                          children: [
                            TextField(
                              controller: _barcodeController,
                              decoration: const InputDecoration(
                                labelText: "Barcode",
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.line_style_rounded),
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _productNameController,
                              decoration: const InputDecoration(
                                labelText: "Name",
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.abc_rounded),
                              ),
                            ),
                            const SizedBox(height: 10),
                            DropdownButtonFormField<String>(
                              value: categories.any(
                                (item) => item.id.toString() == id_category,
                              )
                                  ? id_category
                                  : null,
                              decoration: const InputDecoration(
                                labelText: "Category",
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.category_rounded),
                              ),
                              items: List.generate(
                                categories.length,
                                (index) {
                                  return DropdownMenuItem<String>(
                                    value: categories[index].id.toString(),
                                    child: Text(categories[index].name),
                                  );
                                },
                              ),
                              onChanged: categories.isEmpty
                                  ? null
                                  : (val) {
                                      setDialogState(() {
                                        id_category = val;
                                      });
                                    },
                            ),
                            if (categories.isEmpty)
                              const Padding(
                                padding: EdgeInsets.only(top: 6),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    "No categories available",
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _stockController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: "Stock",
                                border: OutlineInputBorder(),
                                prefixIcon:
                                    Icon(Icons.add_shopping_cart_rounded),
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _purchasedPriceController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: "Purchased Price",
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.money),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                "Units",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...List.generate(
                              _unitControllers.length,
                              (index) {
                                final isLast =
                                    index == _unitControllers.length - 1;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 3,
                                        child: TextField(
                                          controller: _unitControllers[index],
                                          decoration: const InputDecoration(
                                            labelText: "Unit",
                                            border: OutlineInputBorder(),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        flex: 2,
                                        child: TextField(
                                          controller:
                                              _unitPriceControllers[index],
                                          keyboardType: TextInputType.number,
                                          decoration: const InputDecoration(
                                            labelText: "Price",
                                            border: OutlineInputBorder(),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      if (isLast)
                                        IconButton(
                                          onPressed: () {
                                            setDialogState(_addUnitField);
                                          },
                                          icon: const Icon(
                                            Icons.add_circle,
                                            color: Colors.green,
                                          ),
                                        ),
                                      if (_unitControllers.length > 1)
                                        IconButton(
                                          onPressed: () {
                                            setDialogState(
                                                () => _removeUnitField(index));
                                          },
                                          icon: const Icon(
                                            Icons.remove_circle,
                                            color: Colors.red,
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )),
      ),
    ).then((_) => _resetAddProductForm());
  }

  Future<void> _showDeleteProductDialog(Product product) async {
    final isConfirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: GlobalVariables.backgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          "Delete Product",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Delete "${product.productName}" permanently?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (isConfirmed != true) return;

    final isSuccess = await productServices.deleteProduct(
      context: context,
      id: product.id,
    );
    if (!mounted) return;
    if (isSuccess) {
      await getAllProduct();
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    getAllProduct();
    getAllCategories();
    super.initState();
  }

  @override
  void dispose() {
    _searchProductController.dispose();
    _barcodeController.dispose();
    _productNameController.dispose();
    _stockController.dispose();
    _purchasedPriceController.dispose();
    for (final controller in _unitControllers) {
      controller.dispose();
    }
    for (final controller in _unitPriceControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenSizeWidth = MediaQuery.of(context).size.width;
    bool isWideScreen = screenSizeWidth > 950;
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.symmetric(
            horizontal: isWideScreen ? 50.0 : 12.0, vertical: 10),
        child: Container(
          height: MediaQuery.of(context).size.height,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              const Text(
                "List of Products",
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: GlobalVariables.thirdColor,
                ),
              ),
              const SizedBox(
                height: 10,
              ),

              // Add Product Elevated Button
              Row(
                children: [
                  CustomButtonProductScreen(
                      isWideScreen,
                      screenSizeWidth,
                      Colors.green,
                      "Add Product",
                      Icons.add,
                      _showAddProductDialog),
                  const SizedBox(width: 10),
                  CustomButtonProductScreen(
                    isWideScreen,
                    screenSizeWidth,
                    Colors.orange,
                    "Categories",
                    Icons.category,
                    () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CategoriesScreen(
                            categories: categories,
                          ),
                        ),
                      );
                      if (!mounted) return;
                      await getAllCategories();
                    },
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Textfield for search
              CustomTextfieldProductScreen(),

              const SizedBox(height: 10),

              _buildProductFilters(),

              const SizedBox(height: 10),

              // Tabel products
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refreshProductsScreen,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    scrollDirection: Axis.vertical,
                    child: CustomTabelProductsScreen(
                      isWideScreen: isWideScreen,
                      searchProduct: _getFilteredProducts(),
                      onEditProduct: (product) =>
                          _showAddProductDialog(editingProduct: product),
                      onDeleteProduct: _showDeleteProductDialog,
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  ElevatedButton CustomButtonProductScreen(
      bool isWideScreen,
      double screenSizeWidth,
      Color color,
      String text,
      IconData icon,
      VoidCallback fun) {
    return ElevatedButton(
      onPressed: fun,
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5),
        ),
        fixedSize: Size(
            isWideScreen ? screenSizeWidth * 0.2 : screenSizeWidth * 0.5, 40),
        backgroundColor: color,
      ),
      child: Row(
        children: [
          Icon(icon),
          const SizedBox(
            width: 5,
          ),
          Text(text)
        ],
      ),
    );
  }

  TextField CustomTextfieldProductScreen() {
    return TextField(
      controller: _searchProductController,
      onChanged: (searchItem) {
        _searchQuery = searchItem.trim();
        setState(() {});
      },
      decoration: const InputDecoration(
        labelText: "Search Product",
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.search),
      ),
    );
  }

  Widget _buildProductFilters() {
    return Container(
      width: MediaQuery.of(context).size.width,
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: [
          SizedBox(
            width: 250,
            child: DropdownButtonFormField<String>(
              value: _selectedCategoryFilter,
              decoration: const InputDecoration(
                labelText: "Filter Category",
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: [
                const DropdownMenuItem(
                  value: 'all',
                  child: Text("All Categories"),
                ),
                ...categories.map(
                  (category) => DropdownMenuItem(
                    value: category.id.toString(),
                    child: Text(category.name),
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedCategoryFilter = value ?? 'all';
                });
              },
            ),
          ),
          SizedBox(
            width: 250,
            child: DropdownButtonFormField<String>(
              value: _selectedStockFilter,
              decoration: const InputDecoration(
                labelText: "Filter Stock",
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: const [
                DropdownMenuItem(value: 'all', child: Text("All Stock")),
                DropdownMenuItem(
                    value: 'out_of_stock', child: Text("Out of Stock")),
                DropdownMenuItem(value: 'low_stock', child: Text("Low Stock")),
                DropdownMenuItem(value: 'available', child: Text("Available")),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedStockFilter = value ?? 'all';
                });
              },
            ),
          ),
          SizedBox(
            width: 250,
            child: DropdownButtonFormField<String>(
              value: _selectedSortFilter,
              decoration: const InputDecoration(
                labelText: "Sort By",
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: const [
                DropdownMenuItem(value: 'name_asc', child: Text("Name A-Z")),
                DropdownMenuItem(value: 'name_desc', child: Text("Name Z-A")),
                DropdownMenuItem(
                    value: 'price_asc', child: Text("Price Low-High")),
                DropdownMenuItem(
                    value: 'price_desc', child: Text("Price High-Low")),
                DropdownMenuItem(
                    value: 'stock_asc', child: Text("Stock Low-High")),
                DropdownMenuItem(
                    value: 'stock_desc', child: Text("Stock High-Low")),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedSortFilter = value ?? 'name_asc';
                });
              },
            ),
          ),
          SizedBox(
            child: OutlinedButton.icon(
              onPressed: _resetTableFilters,
              icon: const Icon(Icons.restart_alt),
              label: const Text("Reset"),
            ),
          ),
        ],
      ),
    );
  }
}

class CustomTabelProductsScreen extends StatefulWidget {
  const CustomTabelProductsScreen({
    super.key,
    required this.isWideScreen,
    required this.searchProduct,
    required this.onEditProduct,
    required this.onDeleteProduct,
  });

  final bool isWideScreen;
  final List<Product?> searchProduct;
  final Function(Product) onEditProduct;
  final Function(Product) onDeleteProduct;

  @override
  State<CustomTabelProductsScreen> createState() =>
      _CustomTabelProductsScreenState();
}

class _CustomTabelProductsScreenState extends State<CustomTabelProductsScreen> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: Colors.black),
      ),
      child: LayoutBuilder(builder: (context, constraint) {
        return SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraint.maxWidth),
              child: DataTable(
                  dataRowMinHeight: 48,
                  columns: const [
                    DataColumn(label: Text("No")),
                    DataColumn(label: Text("Barcode")),
                    DataColumn(
                        label: Text("Product Name",
                            overflow: TextOverflow.ellipsis, maxLines: 1)),
                    DataColumn(label: Text("Category")),
                    DataColumn(label: Text("Stock")),
                    DataColumn(label: Text("Units")),
                    DataColumn(label: Text("Sub Total")),
                    DataColumn(
                        label: Text("Seller Purchased",
                            overflow: TextOverflow.ellipsis)),
                    DataColumn(label: Text("Action")),
                  ],
                  rows: List.generate(
                    widget.searchProduct.isEmpty
                        ? 1
                        : widget.searchProduct.length,
                    (index) {
                      if (widget.searchProduct.isEmpty) {
                        return const DataRow(
                          cells: [
                            DataCell(Text('-')),
                            DataCell(Text('-')),
                            DataCell(Text('No products match current filters')),
                            DataCell(Text('-')),
                            DataCell(Text('-')),
                            DataCell(Text('-')),
                            DataCell(Text('-')),
                            DataCell(Text('-')),
                            DataCell(Text('-')),
                          ],
                        );
                      }

                      final item = widget.searchProduct[index];
                      return DataRow(
                        cells: [
                          DataCell(Text('${++index}')),
                          DataCell(Text('${item!.barcode}')),
                          DataCell(Text(item.productName)),
                          DataCell(Text(item.category.name)),
                          DataCell(Text('${item.stock}')),
                          DataCell(SingleChildScrollView(
                            scrollDirection: Axis.vertical,
                            child: Column(
                              children: [
                                Text(item.units
                                    .map((unit) => unit.nameUnit)
                                    .join('\n')),
                              ],
                            ),
                          )),
                          DataCell(SingleChildScrollView(
                            scrollDirection: Axis.vertical,
                            child: Column(
                              children: [
                                Text(item.units
                                    .map((unit) => format.toRupiah(unit.price))
                                    .join('\n')),
                              ],
                            ),
                          )),
                          DataCell(Text(format.toRupiah(item.purchasedPrice))),
                          DataCell(Row(
                            children: [
                              IconButton(
                                onPressed: () {
                                  widget.onEditProduct(item);
                                },
                                icon: const Icon(Icons.edit),
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.yellow,
                                  shape: const RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(5)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 5),
                              IconButton(
                                onPressed: () {
                                  widget.onDeleteProduct(item);
                                },
                                icon: const Icon(Icons.delete_forever),
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  shape: const RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(5)),
                                  ),
                                ),
                              ),
                            ],
                          )),
                        ],
                      );
                    },
                  )),
            ),
          ),
        );
      }),
    );
  }
}
