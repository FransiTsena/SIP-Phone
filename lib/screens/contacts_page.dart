import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../api/contacts.dart';

class ContactsPage extends StatefulWidget {
  const ContactsPage({super.key});

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  bool _loading = true;
  bool _error = false;
  String? _errorMsg;
  final List<Map<String, dynamic>> _contacts = [];
  int _page = 1;
  final int _limit = 20;
  int _total = 0;
  final ScrollController _scrollController = ScrollController();
  String _search = '';

  @override
  void initState() {
    super.initState();
    _fetch();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        _loadMore();
      }
    });
  }

  Future<void> _fetch({bool refresh = false}) async {
    try {
      if (refresh) {
        setState(() {
          _page = 1;
          _contacts.clear();
        });
      }
      setState(() {
        _loading = true;
        _error = false;
      });
      final data = await ContactApi.getContacts(page: _page, limit: _limit);
      final List<dynamic> newContacts = data['contacts'] ?? [];
      setState(() {
        _total = data['total'] ?? 0;
        _contacts.addAll(newContacts.cast<Map<String, dynamic>>());
      });
    } catch (e) {
      setState(() {
        _error = true;
        _errorMsg = e.toString();
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_contacts.length >= _total || _loading) return;
    _page += 1;
    await _fetch();
  }

  Future<void> _createOrEdit({Map<String, dynamic>? contact}) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => _ContactDialog(contact: contact),
    );
    if (result != null) {
      try {
        if (contact == null) {
          await ContactApi.createContact(result);
        } else {
          await ContactApi.updateContact(contact['_id'] as String, result);
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                contact == null ? 'Contact created' : 'Contact updated',
              ),
            ),
          );
        }
        await _fetch(refresh: true);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Operation failed: $e')));
        }
      }
    }
  }

  Future<void> _delete(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Contact'),
        content: const Text('Are you sure you want to delete this contact?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await ContactApi.deleteContact(id);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Deleted')));
        }
        await _fetch(refresh: true);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
        }
      }
    }
  }

  List<Map<String, dynamic>> get _filteredContacts {
    if (_search.isEmpty) return _contacts;
    final lower = _search.toLowerCase();
    return _contacts
        .where(
          (c) =>
              (c['name']?.toString().toLowerCase().contains(lower) ?? false) ||
              (c['number']?.toString().toLowerCase().contains(lower) ?? false),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppBar(title: const Text('Contacts')),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 26, 18, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'Search contacts',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(.25),
                      ),
                    ),
                  ),
                  onChanged: (v) => setState(() => _search = v),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                ),
                onPressed: () => _createOrEdit(),
                icon: const Icon(Icons.add),
                label: const Text('New'),
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => _fetch(refresh: true),
            child: _error
                ? ListView(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          _errorMsg ?? 'Error',
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: _filteredContacts.length + (_loading ? 1 : 0),
                    itemBuilder: (ctx, i) {
                      if (i >= _filteredContacts.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final c = _filteredContacts[i];
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                        child: Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 6,
                            ),
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.primary.withOpacity(.12),
                              foregroundColor: Theme.of(
                                context,
                              ).colorScheme.primary,
                              child: Text(
                                (c['name'] ?? '?').toString().isNotEmpty
                                    ? (c['name'] ?? '?')[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            title: Text(
                              c['name'] ?? 'No Name',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryDark,
                              ),
                            ),
                            subtitle: Text(
                              c['number'] ?? '',
                              style: TextStyle(
                                color: AppTheme.primaryDark.withOpacity(.7),
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: 'Edit',
                                  icon: Icon(
                                    Icons.edit,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                  onPressed: () => _createOrEdit(contact: c),
                                ),
                                IconButton(
                                  tooltip: 'Delete',
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.redAccent,
                                  ),
                                  onPressed: () => _delete(c['_id'] as String),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}

class _ContactDialog extends StatefulWidget {
  final Map<String, dynamic>? contact;
  const _ContactDialog({this.contact});
  @override
  State<_ContactDialog> createState() => _ContactDialogState();
}

class _ContactDialogState extends State<_ContactDialog> {
  late TextEditingController _name;
  late TextEditingController _number;
  late TextEditingController _email;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(
      text: widget.contact?['name']?.toString() ?? '',
    );
    _number = TextEditingController(
      text: widget.contact?['number']?.toString() ?? '',
    );
    _email = TextEditingController(
      text: widget.contact?['email']?.toString() ?? '',
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.contact == null ? 'New Contact' : 'Edit Contact'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              TextFormField(
                controller: _number,
                decoration: const InputDecoration(labelText: 'Number'),
                keyboardType: TextInputType.phone,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              TextFormField(
                controller: _email,
                decoration: const InputDecoration(
                  labelText: 'Email (optional)',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              Navigator.pop(context, {
                'name': _name.text.trim(),
                'number': _number.text.trim(),
                'email': _email.text.trim().isEmpty ? null : _email.text.trim(),
              });
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
