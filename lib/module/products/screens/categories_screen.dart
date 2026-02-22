import 'package:flutter/material.dart';

import 'package:smart_cashier_app/constant/global_variables.dart';
import 'package:smart_cashier_app/models/category.dart';
import 'package:smart_cashier_app/module/products/services/products_services.dart';

class CategoriesScreen extends StatefulWidget {
  final List<Category> categories;
  const CategoriesScreen({
    Key? key,
    this.categories = const [],
  }) : super(key: key);

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final CategoryServices _categoryServices = CategoryServices();
  final TextEditingController _nameController = TextEditingController();

  List<Category> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _categories = List<Category>.from(widget.categories);
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    setState(() => _isLoading = true);
    final fetched = await _categoryServices.fetchAllCategories(context: context);
    if (!mounted) return;
    setState(() {
      _categories = fetched;
      _isLoading = false;
    });
  }

  Future<void> _showCategoryDialog({Category? category}) async {
    final bool isEdit = category != null;
    _nameController.text = isEdit ? category.name : '';

    final bool? shouldSubmit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? 'Edit Category' : 'Add Category'),
        content: TextField(
          controller: _nameController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Category name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(isEdit ? 'Update' : 'Add'),
          ),
        ],
      ),
    );

    if (shouldSubmit != true) return;
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final isSuccess = isEdit
        ? await _categoryServices.updateCategory(
            context: context,
            id: category.id,
            name: name,
          )
        : await _categoryServices.addCategory(
            context: context,
            name: name,
          );

    _nameController.clear();

    if (isSuccess && mounted) {
      _fetchCategories();
    }
  }

  Future<void> _confirmDeleteCategory(Category category) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text(
            'Delete "${category.name}"?\nThis action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final isSuccess = await _categoryServices.deleteCategory(
      context: context,
      id: category.id,
    );
    if (isSuccess && mounted) {
      _fetchCategories();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenSizeWidth = MediaQuery.of(context).size.width;
    bool isWideScreen = screenSizeWidth > 950;
    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: EdgeInsets.symmetric(
            horizontal: isWideScreen ? 50.0 : 12.0, vertical: 10),
        child: Container(
          height: MediaQuery.of(context).size.height,
          width: isWideScreen ? screenSizeWidth * 0.7 : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              const Text(
                "List of Categories",
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: GlobalVariables.thirdColor,
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: () => _showCategoryDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text("Add Category"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GlobalVariables.thirdColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Categories table
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: Text("No"),
                      title: Text("Category"),
                      trailing: Text("Actions"),
                    ),
                    if (_isLoading)
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(),
                      )
                    else if (_categories.isEmpty)
                      const ListTile(
                        leading: Text('-'),
                        title: Text('No categories found'),
                        trailing: Text('-'),
                      )
                    else
                      ...List.generate(
                        _categories.length,
                        (index) {
                          final category = _categories[index];
                          return ListTile(
                            leading: Text('${index + 1}'),
                            title: Text(category.name),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  onPressed: () =>
                                      _showCategoryDialog(category: category),
                                  icon: const Icon(Icons.edit),
                                  tooltip: 'Edit category',
                                ),
                                IconButton(
                                  onPressed: () =>
                                      _confirmDeleteCategory(category),
                                  icon: const Icon(Icons.delete),
                                  tooltip: 'Delete category',
                                  color: Colors.red,
                                ),
                              ],
                            ),
                          );
                        },
                      )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
