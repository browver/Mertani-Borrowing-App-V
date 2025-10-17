import 'package:flutter/material.dart';
import 'package:user_app/category_model.dart';
import 'package:user_app/firebase_services.dart';
import 'package:user_app/product_by_category.dart';
import 'package:google_fonts/google_fonts.dart'; 
import 'package:shared_preferences/shared_preferences.dart';

class CategoryPage extends StatefulWidget {
  const CategoryPage({super.key});

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  final FirestoreServices firestore = FirestoreServices();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _searchController = TextEditingController(); 
  IconData selectedIcon = Icons.category;
  bool deleteProducts = false;
  String searchText = ''; 
  String? role;

  @override
  void initState() {
    super.initState();
    _loadRole(); 
  }

  void _loadRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      role = prefs.getString('role') ?? 'user';
    });
  }
// Add Category
  void _showAddCategoryDialog() {
    if (role != 'admin') {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text("Hanya admin yang bisa menambahkan kategori.")),
  );
  return;
}
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Add Category'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Category Name'),
                  ),
                  const SizedBox(height: 10),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Add Icon:'),
                  ),
                  DropdownButton<IconData>(
                    value: selectedIcon,
                    items: [
                      Icons.category,
                      Icons.memory,
                      Icons.sensors,
                      Icons.sensor_window,
                      Icons.bolt,
                    ].map((icon) {
                      return DropdownMenuItem(
                        value: icon,
                        child: Row(
                          children: [
                            Icon(icon),
                            const SizedBox(width: 10),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setStateDialog(() {
                        selectedIcon = value!;
                      });
                    },
                  )
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    firestore.addCategory(_nameController.text, selectedIcon.codePoint);
                    Navigator.pop(context);
                    _nameController.clear();
                  },
                  child: const Text('Add'),
              )
            ],
            );
          },
       );
     },
    );
  }

// Edit Category
  Future<void> _editCategoryDialog(CategoryModel category) async {
    final TextEditingController editNameController = TextEditingController(text: category.name);
    IconData editIcon = category.icon;

    if(!mounted) return;
    await showDialog(
      context: context, 
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogInnerContext, setStateDialog) {
            return AlertDialog(
              title: const Text('Edit Category'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: editNameController,
                    decoration: const InputDecoration(labelText: 'New Category Name'),
                  ),
                  const SizedBox(height: 10),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Change Icon:'),
                  ),
                  DropdownButton<IconData>(
                    value: editIcon,
                    items: [
                      Icons.category,
                      Icons.memory,
                      Icons.sensors,
                      Icons.sensor_window,
                      Icons.bolt,
                    ].map((icon) {
                      return DropdownMenuItem(
                        value: icon,
                        child: Row(
                          children: [
                            Icon(icon),
                            const SizedBox(width: 10),
                          ],
                        ));
                    }).toList(),
                    onChanged: (value) {
                      setStateDialog(() {
                        editIcon = value!;
                      });
                    },
                  )
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                  final newName = editNameController.text.trim();
                  if (newName.isNotEmpty) {
                    Navigator.pop(dialogContext);
                    firestore.updateCategory(category.name, newName, editIcon.codePoint);
                  }
                },
                  child: const Text('Save'),
              )
            ],
            );
          });
      });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200], 
      appBar: AppBar(
        title: Text(
          'Categories',
          style: const TextStyle(color: Colors.white,
          fontWeight: FontWeight.bold
          ),
        ),
        backgroundColor: Colors.blue[600], 
      ),
      floatingActionButton: role == 'admin'? FloatingActionButton(
        onPressed: _showAddCategoryDialog,
        backgroundColor: Colors.blue[600], 
        child: const Icon(Icons.add, color: Colors.white),
      ) :null ,
      body: Column( 
        children: [
          Padding( 
            padding: const EdgeInsets.all(10),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search category...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (value) {
                setState(() {
                  searchText = value.toLowerCase();
                });
              },
            ),
          ),
          Expanded( 
            child: StreamBuilder<List<CategoryModel>>(
              stream: firestore.getCategories(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: SingleChildScrollView(
                      child: Text(
                        'Error loading categories:\n${snapshot.error}',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ));
                }
                if (!snapshot.hasData) return const CircularProgressIndicator();

                final filteredCategories = snapshot.data!
                  .where((cat) => cat.name.toLowerCase().contains(searchText)) 
                  .toList(); 

                if (filteredCategories.isEmpty) return const Text("No categories found"); 

                return ListView.builder(
                  itemCount: filteredCategories.length, 
                  itemBuilder: (context, index) {
                    final category = filteredCategories[index]; 
                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14), 
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16), 
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16), 
                            ),
                            tileColor: Colors.white, 
                            leading: Icon(category.icon, color: Colors.blue[600]), 
                            title: Text(
                              category.name,
                              style: GoogleFonts.alexandria( 
                                textStyle: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (role == 'asfnskdf')
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  color: Colors.blue[600],
                                  onPressed: () => _editCategoryDialog(category),
                                ),
                                if (role == 'asfnskdf')
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  color: Colors.blue[600],
                                  onPressed: () async {
                                    bool localDeleteProducts = deleteProducts;

                                    final confirm = await showDialog(
                                      context: context, 
                                      builder:(dialogContext) {
                                        return StatefulBuilder(
                                          builder: (contenxt, setStateDialog) {
                                            return AlertDialog(
                                              title: const Text('Hapus Kategori'),
                                              content: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text('Yakin ingin menghapus kategori "${category.name}" ?'),
                                                  const SizedBox(height: 10),
                                                  CheckboxListTile(
                                                    value: localDeleteProducts, 
                                                    onChanged: (value) {
                                                      setStateDialog(() {
                                                        localDeleteProducts = value!;
                                                      });
                                                    },
                                                    title: const Text('Hapus semua produk dalam kategori ini'),
                                                    controlAffinity: ListTileControlAffinity.leading,
                                                  ),
                                                ],
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(dialogContext,false), 
                                                  child: const Text('Batal')),
                                                TextButton(
                                                  onPressed: () => Navigator.pop(dialogContext, true), 
                                                  child: const Text('Hapus')),
                                              ],
                                            );
                                          },
                                        );
                                      },
                                    );

                                    if (confirm == true) {
                                      if (localDeleteProducts) {
                                        await firestore.deleteCategoryWithProducts(category.name);
                                      } else {
                                        await firestore.deleteCategory(category.name);
                                      }
                                    }
                                  },
                                ),
                                const Icon(Icons.arrow_forward_ios, size: 16),
                              ],
                            ),
                            onTap: () {
                              Navigator.push(
                                context, 
                                MaterialPageRoute(
                                  builder: (context) => ProductByCategoryPage(categoryName: category.name)
                                )
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    );
                  });
              },
            ),
          )
        ],
      ),
    );
  }
}
