import 'package:flutter/material.dart';
import 'package:smart_cashier_app/constant/global_variables.dart';
import 'package:smart_cashier_app/models/supplier.dart';
import 'package:smart_cashier_app/module/report/services/report_services.dart';

class SupplierScreen extends StatefulWidget {
  const SupplierScreen({super.key});

  @override
  State<SupplierScreen> createState() => _SupplierScreenState();
}

class _SupplierScreenState extends State<SupplierScreen> {
  bool _isLoading = true;
  final ReportServices _reportServices = ReportServices();
  List<Supplier> suppliers = [];
  final TextEditingController _nameC = TextEditingController();
  final TextEditingController _phoneC = TextEditingController();
  final TextEditingController _companyC = TextEditingController();
  final TextEditingController _addressC = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchAllSuppliers();
  }

  Future<void> _fetchAllSuppliers() async {
    setState(() {
      _isLoading = true;
    });
    final fetched = await _reportServices.fetchSuppliers(context: context);
    if (!mounted) return;
    setState(() {
      suppliers = fetched;
      _isLoading = false;
    });
  }

  Future<void> _showSupplierDialog({Supplier? supplier}) async {
    final bool isEdit = supplier != null;
    if (isEdit) {
      _nameC.text = supplier.name;
      _phoneC.text = supplier.phone ?? "";
      _companyC.text = supplier.company ?? "";
      _addressC.text = supplier.address ?? "";
    }
    final bool? shouldSubmit = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          insetPadding: const EdgeInsets.all(20),
          backgroundColor: GlobalVariables.backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title:  Text(isEdit ? "Update Supplier" : "Add Supplier"),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.3,
            // height: MediaQuery.of(context).size.height * 0.3,
            child: SingleChildScrollView(
              child: Form(
                child: Column(
                  children: [
                    TextField(
                      controller: _nameC,
                      decoration: const InputDecoration(
                        labelText: "Supplier Name",
                        border: OutlineInputBorder(),
                        icon: Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    TextField(
                      controller: _phoneC,
                      decoration: const InputDecoration(
                        labelText: "Phone Number",
                        border: OutlineInputBorder(),
                        icon: Icon(Icons.phone),
                      ),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    TextField(
                      controller: _companyC,
                      decoration: const InputDecoration(
                        labelText: "Company",
                        border: OutlineInputBorder(),
                        icon: Icon(Icons.location_city_rounded),
                      ),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    TextField(
                      controller: _addressC,
                      decoration: const InputDecoration(
                        labelText: "Address",
                        border: OutlineInputBorder(),
                        icon: Icon(Icons.location_on),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(isEdit ? "Update" : "Add"),
            ),
          ],
        );
      },
    );

    if (shouldSubmit != true || _nameC.text.trim().isEmpty) return;

    final isSuccess = isEdit
        ? await _reportServices.updateSupplier(
            context: context,
            id: supplier.id,
            supplierName: _nameC.text,
            phone: _phoneC.text,
            company: _companyC.text,
            address: _addressC.text,
          )
        : await _reportServices.createSupplier(
            context: context,
            supplierName: _nameC.text,
            phone: _phoneC.text,
            company: _companyC.text,
            address: _addressC.text,
          );

    _nameC.clear();
    _phoneC.clear();
    _companyC.clear();
    _addressC.clear();

    if (isSuccess && mounted) {
      _fetchAllSuppliers();
    }
  }

  Future<void> _confirmDeleteSupplier(Supplier supplier) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Supplier'),
        content:
            Text('Delete "${supplier.name}"?\nThis action cannot be undone.'),
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

    final isSuccess = await _reportServices.deleteSupplier(
      context: context,
      id: supplier.id,
    );
    if (isSuccess && mounted) {
      _fetchAllSuppliers();
    }
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _nameC.dispose();
    _phoneC.dispose();
    _companyC.dispose();
    _addressC.dispose();
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            const Text(
              "List of Suppliers",
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
              alignment: Alignment.centerLeft,
              child: ElevatedButton.icon(
                onPressed: () => _showSupplierDialog(),
                icon: const Icon(Icons.add),
                label: const Text("Add Supplier"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: GlobalVariables.thirdColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 10),
        
            // Categories table
            Card(
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
        
                  child: Column(
                    children: [
                      DataTable(
                        // dataRowMinHeight: 24,
                        columns: const [
                          DataColumn(label: Text("No")),
                          DataColumn(label: Text("Name")),
                          DataColumn(label: Text("Phone")),
                          DataColumn(label: Text("Company")),
                          DataColumn(label: Text("Address")),
                          DataColumn(label: Text("Action")),
                        ],
                        rows: List.generate(
                          suppliers.isEmpty ? 1 : suppliers.length,
                          (index) {
                            if (suppliers.isEmpty) {
                              return const DataRow(cells: [
                                DataCell(Text('-')),
                                DataCell(Text('-')),
                                DataCell(
                                    Text('No Supllier match current filters')),
                                DataCell(Text('-')),
                                DataCell(Text('-')),
                                DataCell(Text('-')),
                              ]);
                            }
                  
                            final supplier = suppliers[index];
                            return DataRow(cells: [
                              DataCell(Text('${++index}')),
                              DataCell(Text('${supplier.name}')),
                              DataCell(Text('${supplier.phone}')),
                              DataCell(Text('${supplier.company}')),
                              DataCell(Text('${supplier.address}')),
                              DataCell(Row(
                                children: [
                                  IconButton(
                                    onPressed: () {
                                      _showSupplierDialog(supplier: supplier);
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
                                      _confirmDeleteSupplier(supplier);
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
                            ]);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
