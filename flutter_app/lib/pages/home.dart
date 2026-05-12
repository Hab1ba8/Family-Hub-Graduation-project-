import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/services/api_service.dart';
import '../core/models/member_model.dart';
import '../core/localization/app_i18n.dart';
import 'setting.dart';
import 'signup_login.dart';
import 'manage_accounts_page.dart';

class HomePage extends StatefulWidget {
  final String? userName;
  final String? familyTitle;
  final VoidCallback? onLogout;

  const HomePage({
    super.key,
    this.userName,
    this.familyTitle,
    this.onLogout,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ApiService _apiService = ApiService();
  String _t(String en, String ar) => AppI18n.t(context, en, ar);
  
  int _activeTab = 0;
  bool _locationSharing = true;

  static const _avatarColors = [
    Color(0xFF1565C0), Color(0xFF6A1B9A), Color(0xFFAD1457),
    Color(0xFFE65100), Color(0xFF00695C), Color(0xFF2E7D32),
  ];
  static const _avatarBgs = [
    Color(0xFFE3F2FD), Color(0xFFF3E5F5), Color(0xFFFCE4EC),
    Color(0xFFFFF3E0), Color(0xFFE0F2F1), Color(0xFFE8F5E9),
  ];
  bool _protectionSetting = false;
  List<Member> _familyMembers = [];
  String _familyTitle = '';
  String _userName = '';
  List<Map<String, dynamic>> _savedProfiles = [];
  String _activeProfileKey = '';
  bool _hasActiveProfile = false;
  bool _loading = true;
  bool _walletLoading = true;
  Map<String, dynamic> _walletSummary = {};

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadSavedProfiles();
    _fetchFamilyMembers();
    _loadWalletSummary();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userName = prefs.getString('username') ?? widget.userName ?? '';
    final familyTitle = prefs.getString('familyTitle') ?? widget.familyTitle ?? '';
    final activeProfileKey = prefs.getString('activeProfileKey') ?? '';
    
    setState(() {
      _userName = userName;
      _familyTitle = familyTitle;
      _activeProfileKey = activeProfileKey;
      _hasActiveProfile = activeProfileKey.isNotEmpty;
    });
  }

  Future<void> _loadSavedProfiles() async {
    final profiles = await _apiService.getSavedProfiles();
    if (!mounted) return;
    setState(() {
      _savedProfiles = profiles;
    });
  }

  Future<void> _loadWalletSummary() async {
    try {
      final summary = await _apiService.getCombinedBalance();
      if (!mounted) return;
      setState(() {
        _walletSummary = summary;
        _walletLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _walletSummary = {};
        _walletLoading = false;
      });
    }
  }

  Future<void> _switchProfileFromHome(String profileKey) async {
    try {
      await _apiService.switchProfile(profileKey);
      await _loadUserData();
      await _loadSavedProfiles();
      await _fetchFamilyMembers();
      await _loadWalletSummary();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_t('Switched account', 'تم تبديل الحساب'))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_t('Failed to switch account', 'فشل تبديل الحساب')}: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showAccountSwitcherSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  _t('Accounts', 'الحسابات'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                if (_savedProfiles.isNotEmpty)
                  Builder(builder: (_) {
                    Map<String, dynamic>? active;
                    for (final p in _savedProfiles) {
                      if (p['profileKey']?.toString() == _activeProfileKey) {
                        active = p;
                        break;
                      }
                    }

                    if (active == null) return const SizedBox.shrink();

                    final activeFamily = active['familyTitle']?.toString() ?? _t('Family', 'العائلة');
                    final activeUser = active['username']?.toString() ?? _t('Member', 'عضو');
                    final activeMail = active['mail']?.toString() ?? '';
                    final initial = (activeUser.isNotEmpty ? activeUser[0] : 'A').toUpperCase();

                    return Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3FAF2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFBFE5C2)),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: const Color(0xFFE8F5E9),
                            child: Text(
                              initial,
                              style: const TextStyle(
                                color: Color(0xFF2E7D32),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _t('Current account', 'الحساب الحالي'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF2E7D32),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '$activeFamily ($activeUser)',
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                                Text(activeMail, style: const TextStyle(fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                if (_savedProfiles.isEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(_t('No saved accounts yet', 'لا توجد حسابات محفوظة بعد')),
                  ),
                if (_savedProfiles.isNotEmpty)
                  ..._savedProfiles.map((profile) {
                    final key = profile['profileKey']?.toString() ?? '';
                    final familyTitle = profile['familyTitle']?.toString() ?? _t('Family', 'العائلة');
                    final username = profile['username']?.toString() ?? _t('Member', 'عضو');
                    final mail = profile['mail']?.toString() ?? '';
                    final isActive = key == _activeProfileKey;

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFFE8F5E9),
                        child: Text(
                          (username.isNotEmpty ? username[0] : 'A').toUpperCase(),
                          style: const TextStyle(
                            color: Color(0xFF2E7D32),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      title: Text('$familyTitle ($username)'),
                      subtitle: Text(mail),
                      trailing: isActive
                          ? const Icon(Icons.check_circle, color: Color(0xFF4CAF50))
                          : null,
                      onTap: () async {
                        Navigator.of(sheetContext).pop();
                        if (!isActive) {
                          await _switchProfileFromHome(key);
                        }
                      },
                    );
                  }),
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  child: Column(
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(sheetContext).pop();
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const LoginPage()),
                          );
                        },
                        icon: const Icon(Icons.add),
                        label: Text(_t('Add New Account', 'إضافة حساب جديد')),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF2E7D32),
                          side: const BorderSide(color: Color(0xFF4CAF50)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () async {
                          Navigator.of(sheetContext).pop();
                          final changed = await Navigator.of(context).push<bool>(
                            MaterialPageRoute(builder: (_) => const ManageAccountsPage()),
                          );
                          if (changed == true) {
                            await _loadUserData();
                            await _loadSavedProfiles();
                            await _fetchFamilyMembers();
                            await _loadWalletSummary();
                          }
                        },
                        icon: const Icon(Icons.manage_accounts),
                        label: Text(_t('Manage Accounts', 'إدارة الحسابات')),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _sectionHeader(String en, String ar) {
    return Text(
      _t(en, ar),
      style: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: const Color(0xFF666666),
      ),
    );
  }

  Future<void> _fetchFamilyMembers() async {
    try {
      final members = await _apiService.getAllMembers();
      setState(() {
        _familyMembers = members.map((m) => Member.fromJson(m)).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${_t('Error loading members', 'خطأ في تحميل الأعضاء')}: $e')),
        );
      }
    }
  }

  Future<void> _handleLogout() async {
    await _apiService.logout();
    
    if (widget.onLogout != null) {
      widget.onLogout!();
    } else if (mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  Future<void> _handleLogoutAll() async {
    await _apiService.logoutAllProfiles();

    if (widget.onLogout != null) {
      widget.onLogout!();
    } else if (mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  void _showAddMemberDialog() {
    final emailController = TextEditingController();
    final usernameController = TextEditingController();
    final birthdateController = TextEditingController();
    final newMemberTypeController = TextEditingController();
    String? selectedMemberType;
    List<Map<String, dynamic>> memberTypes = [];
    bool isLoading = false;
    bool isLoadingTypes = true;
    bool showNewTypeField = false;
    String? loadError;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            // Fetch member types from database when dialog opens
            if (isLoadingTypes && memberTypes.isEmpty && loadError == null) {
              _apiService.getAllMemberTypes().then((types) {
                print('✅ Loaded ${types.length} member types: $types');
                setDialogState(() {
                  memberTypes = List<Map<String, dynamic>>.from(types);
                  isLoadingTypes = false;
                });
              }).catchError((e) {
                print('❌ Error loading member types: $e');
                setDialogState(() {
                  loadError = e.toString();
                  isLoadingTypes = false;
                });
              });
            }
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                width: 500,
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Add New Member',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Mail field
                    const Text('Mail', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: emailController,
                      decoration: InputDecoration(
                        hintText: 'Enter email address',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Username field
                    const Text('Username', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: usernameController,
                      decoration: InputDecoration(
                        hintText: 'Enter username',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Birth Date field
                    const Text('Birth Date', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: birthdateController,
                      readOnly: true,
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: dialogContext,
                          initialDate: DateTime(2000),
                          firstDate: DateTime(1950),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          birthdateController.text =
                              "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                        }
                      },
                      decoration: InputDecoration(
                        hintText: 'mm/dd/yyyy',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        suffixIcon: const Icon(Icons.calendar_today),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Member Type dropdown
                    const Text('Member Type', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    isLoadingTypes
                        ? Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(color: const Color(0xFF4CAF50), width: 2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFF4CAF50),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text('Loading member types...'),
                              ],
                            ),
                          )
                        : loadError != null
                            ? Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.red, width: 2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Error: ${loadError!.replaceAll('Exception: ', '')}',
                                  style: const TextStyle(color: Colors.red),
                                ),
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  DropdownButtonFormField<String>(
                                    value: selectedMemberType,
                                    decoration: InputDecoration(
                                      hintText: 'Select Type',
                                      hintStyle: const TextStyle(color: Color(0xFF4CAF50)),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 2),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 2),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    ),
                                    items: [
                                      ...memberTypes.map((typeObj) => DropdownMenuItem(
                                            value: typeObj['type'].toString(),
                                            child: Text(typeObj['type'].toString()),
                                          )),
                                      const DropdownMenuItem(
                                        value: '__CREATE_NEW__',
                                        child: Row(
                                          children: [
                                            Icon(Icons.add_circle_outline, color: Color(0xFF4CAF50), size: 20),
                                            SizedBox(width: 8),
                                            Text(
                                              'Create new member type +',
                                              style: TextStyle(
                                                color: Color(0xFF4CAF50),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                    onChanged: (value) {
                                      setDialogState(() {
                                        if (value == '__CREATE_NEW__') {
                                          selectedMemberType = null;
                                          showNewTypeField = true;
                                        } else {
                                          selectedMemberType = value;
                                          showNewTypeField = false;
                                          newMemberTypeController.clear();
                                        }
                                      });
                                    },
                                  ),
                                  if (showNewTypeField) ...[
                                    const SizedBox(height: 12),
                                    TextField(
                                      controller: newMemberTypeController,
                                      decoration: InputDecoration(
                                        hintText: 'Enter new member type name',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        prefixIcon: const Icon(Icons.person_add, color: Color(0xFF4CAF50)),
                                      ),
                                      onChanged: (value) {
                                        setDialogState(() {});
                                      },
                                    ),
                                  ],
                                ],
                              ),
                    const SizedBox(height: 24),
                    // Add Member button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: isLoading
                            ? null
                            : () async {
                                // Validation
                                if (emailController.text.trim().isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Please enter email address')),
                                  );
                                  return;
                                }
                                if (usernameController.text.trim().isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Please enter username')),
                                  );
                                  return;
                                }
                                if (birthdateController.text.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Please select birth date')),
                                  );
                                  return;
                                }
                                
                                // Get the member type (either selected or newly created)
                                String? finalMemberType = selectedMemberType;
                                
                                if (showNewTypeField) {
                                  if (newMemberTypeController.text.trim().isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Please enter new member type name')),
                                    );
                                    return;
                                  }
                                  finalMemberType = newMemberTypeController.text.trim();
                                } else if (selectedMemberType == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Please select member type')),
                                  );
                                  return;
                                }

                                setDialogState(() {
                                  isLoading = true;
                                });

                                try {
                                  final memberData = {
                                    'mail': emailController.text.trim(),
                                    'username': usernameController.text.trim(),
                                    'birth_date': birthdateController.text,
                                    'member_type': finalMemberType,
                                  };

                                  print('📝 Creating member with data: $memberData');
                                  final result = await _apiService.createMember(memberData);
                                  print('✅ Member created successfully: $result');

                                  if (mounted) {
                                    Navigator.pop(dialogContext);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Member added successfully!'),
                                        backgroundColor: Colors.green,
                                        duration: Duration(seconds: 3),
                                      ),
                                    );
                                    // Refresh family members
                                    _fetchFamilyMembers();
                                  }
                                } catch (e) {
                                  print('❌ Error creating member: $e');
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Failed to add member: ${e.toString().replaceAll('Exception: ', '')}'),
                                        backgroundColor: Colors.red,
                                        duration: const Duration(seconds: 5),
                                      ),
                                    );
                                  }
                                } finally {
                                  if (mounted) {
                                    setDialogState(() {
                                      isLoading = false;
                                    });
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFA8D5BA),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Add Member',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE8F5E9),
              Color(0xFFF3F4F6),
              Color(0xFFE8F5E9),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 30),
                      if (_familyMembers.isNotEmpty) _buildFamilyMembers(),
                      const SizedBox(height: 30),
                      _buildQuickActions(),
                      const SizedBox(height: 18),
                      _buildWalletOverviewCard(),
                      const SizedBox(height: 30),
                      _buildUpcomingActivities(),
                      const SizedBox(height: 30),
                      _buildSafetySettings(),
                      const SizedBox(height: 100), // Space for bottom nav
                    ],
                  ),
                ),
              ),
            ],
          ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              GestureDetector(
                onLongPress: _showAccountSwitcherSheet,
                onTap: _showAccountSwitcherSheet,
                child: Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF43A047), Color(0xFF1B5E20)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2E7D32).withOpacity(0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.family_restroom, color: Colors.white, size: 32),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _familyTitle.isNotEmpty
                          ? (_t('$_familyTitle Family', 'عائلة $_familyTitle'))
                          : _t('Family Hub', 'فاميلي هب'),
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _t('Welcome $_userName', 'مرحباً $_userName'),
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: const Color(0xFF666666),
                      ),
                    ),
                    if (_hasActiveProfile) const SizedBox(height: 6),
                    if (_hasActiveProfile)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF4CAF50).withOpacity(0.35),
                          ),
                        ),
                        child: Text(
                          _t('Active profile', 'الحساب النشط'),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF2E7D32).withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
          ),
          child: IconButton(
            onPressed: () async {
              final selected = await showDialog<String>(
                context: context,
                builder: (dialogContext) {
                  return AlertDialog(
                    title: Text(_t('Logout options', 'خيارات تسجيل الخروج')),
                    content: Text(_t('Choose logout scope for this device.', 'اختر نطاق تسجيل الخروج لهذا الجهاز.')),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop('cancel'),
                        child: Text(_t('Cancel', 'إلغاء')),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop('current'),
                        child: Text(_t('Logout current', 'تسجيل خروج الحساب الحالي')),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop('all'),
                        child: Text(_t('Logout all', 'تسجيل خروج جميع الحسابات'), style: const TextStyle(color: Colors.red)),
                      ),
                    ],
                  );
                },
              );

              if (selected == 'current') {
                await _handleLogout();
              } else if (selected == 'all') {
                await _handleLogoutAll();
              }
            },
            icon: const Icon(Icons.logout_outlined, size: 22, color: Color(0xFF2E7D32)),
            tooltip: _t('Logout', 'خروج'),
          ),
        ),
      ],
    );
  }

  Widget _buildWalletOverviewCard() {
    final moneyBalance = ((_walletSummary['money_balance'] ?? 0) as num).toDouble();
    final pointsBalance = ((_walletSummary['points_balance'] ?? 0) as num).toDouble();
    final totalValue = ((_walletSummary['total_value_in_money'] ?? moneyBalance) as num).toDouble();
    final conversionRate = _walletSummary['conversionRate'];
    final moneyToPointsRate = conversionRate is Map && conversionRate['money_to_points_rate'] != null
        ? (conversionRate['money_to_points_rate'] as num).toDouble()
        : 10.0;
    final pointsToMoneyRate = conversionRate is Map && conversionRate['points_to_money_rate'] != null
        ? (conversionRate['points_to_money_rate'] as num).toDouble()
        : 0.05;

    return InkWell(
      onTap: () => Navigator.of(context).pushNamed('/wallet-details'),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.18)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, 6)),
          ],
        ),
        child: _walletLoading
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 18),
                  child: CircularProgressIndicator(color: Color(0xFF1B5E20)),
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1B5E20).withOpacity(0.10),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.account_balance_wallet_outlined, color: Color(0xFF1B5E20), size: 19),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _t('Wallet Snapshot', 'ملخص المحفظة'),
                        style: const TextStyle(color: Color(0xFF1A1A1A), fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => Navigator.of(context).pushNamed('/combined-wallet'),
                        style: TextButton.styleFrom(foregroundColor: const Color(0xFF1B5E20)),
                        child: Text(_t('Open Wallet', 'فتح المحفظة')),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _miniStatTile(
                          label: _t('Money balance', 'رصيد المال'),
                          value: '${moneyBalance.toStringAsFixed(2)} EGP',
                          accent: const Color(0xFF1B5E20),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _miniStatTile(
                          label: _t('Points balance', 'رصيد النقاط'),
                          value: '${pointsBalance.toStringAsFixed(0)} pts',
                          accent: const Color(0xFFF57C00),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _miniStatTile(
                          label: _t('Total value', 'القيمة الكلية'),
                          value: '${totalValue.toStringAsFixed(2)} EGP',
                          accent: const Color(0xFF1565C0),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _miniStatTile(
                          label: _t('Rates', 'أسعار التحويل'),
                          value: '1 EGP = ${moneyToPointsRate.toStringAsFixed(0)} pts\n1 pt = ${pointsToMoneyRate.toStringAsFixed(2)} EGP',
                          accent: const Color(0xFF4CAF50),
                          multiline: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pushNamed('/wallet-details'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF1B5E20),
                            side: const BorderSide(color: Color(0xFF1B5E20)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          child: Text(_t('Balance details', 'تفاصيل الرصيد')),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pushNamed('/combined-wallet'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1B5E20),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          child: Text(_t('Wallet view', 'عرض المحفظة')),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  Widget _miniStatTile({
    required String label,
    required String value,
    required Color accent,
    bool multiline = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withOpacity(0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey[700], fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: multiline ? 11 : 14,
              height: multiline ? 1.25 : 1.1,
              color: accent,
              fontWeight: FontWeight.w800,
            ),
            maxLines: multiline ? 2 : 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildFamilyMembers() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('FAMILY MEMBERS', 'أفراد العائلة'),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)))
              : Wrap(
                  spacing: 15,
                  runSpacing: 15,
                  children: _familyMembers.asMap().entries
                      .map((e) => _buildMemberCard(e.value, e.key))
                      .toList(),
                ),
        ),
      ],
    );
  }

  Widget _buildMemberCard(Member member, int index) {
    final avatarColor = _avatarColors[index % _avatarColors.length];
    final avatarBg = _avatarBgs[index % _avatarBgs.length];
    return GestureDetector(
      onTap: () => _showMemberOptionsDialog(member, index),
      child: SizedBox(
        width: 72,
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: avatarBg,
                    shape: BoxShape.circle,
                    border: Border.all(color: avatarColor.withOpacity(0.25), width: 2),
                  ),
                  child: Center(
                    child: Text(
                      member.getAvatarEmoji(),
                      style: const TextStyle(fontSize: 30),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              member.username,
              style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF333333), fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              member.memberType?.type ?? _t('Member', 'عضو'),
              style: TextStyle(
                fontSize: 10,
                color: avatarColor,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showMemberOptionsDialog(Member member, int index) {
    final avatarColor = _avatarColors[index % _avatarColors.length];
    final avatarBg = _avatarBgs[index % _avatarBgs.length];
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            width: 350,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Member Avatar
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: avatarBg,
                    shape: BoxShape.circle,
                    border: Border.all(color: avatarColor.withOpacity(0.3), width: 2),
                  ),
                  child: Center(
                    child: Text(
                      member.getAvatarEmoji(),
                      style: const TextStyle(fontSize: 40),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Member Name
                Text(
                  member.username,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                
                // Member Type Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    member.memberType?.type ?? _t('Member', 'عضو'),
                    style: const TextStyle(
                      color: Color(0xFF4CAF50),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                
                // Member Email
                Text(
                  member.mail,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF666666),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Action Buttons
                Row(
                  children: [
                    // Close Button
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: const BorderSide(color: Color(0xFF4CAF50)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Close',
                          style: TextStyle(color: Color(0xFF4CAF50)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Remove Button
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          _showDeleteMemberConfirmation(member);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_remove, size: 18, color: Colors.white),
                            SizedBox(width: 6),
                            Text(
                              'Remove',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDeleteMemberConfirmation(Member member) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        bool isDeleting = false;
        
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
                  SizedBox(width: 8),
                  Text('Remove Member'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Are you sure you want to remove "${member.username}" from your family?',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.red, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'This action cannot be undone. All member data including points and wishlist will be deleted.',
                            style: TextStyle(fontSize: 12, color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isDeleting ? null : () => Navigator.pop(dialogContext),
                  child: Text(_t('Cancel', 'إلغاء')),
                ),
                ElevatedButton(
                  onPressed: isDeleting
                      ? null
                      : () async {
                          setDialogState(() {
                            isDeleting = true;
                          });
                          
                          try {
                            await _apiService.deleteMember(member.id);
                            
                            if (mounted) {
                              Navigator.pop(dialogContext);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${member.username} has been removed from your family'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              // Refresh family members list
                              _fetchFamilyMembers();
                            }
                          } catch (e) {
                            if (mounted) {
                              Navigator.pop(dialogContext);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to remove member: ${e.toString().replaceAll('Exception: ', '')}'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  child: isDeleting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Remove',
                          style: TextStyle(color: Colors.white),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      {
        'label_en': 'Add Member', 'label_ar': 'إضافة عضو',
        'icon': Icons.person_add_alt_1_outlined,
        'color': const Color(0xFF2E7D32), 'bg': const Color(0xFFE8F5E9),
        'onTap': _showAddMemberDialog,
      },
      {
        'label_en': 'Tasks', 'label_ar': 'المهام',
        'icon': Icons.assignment_outlined,
        'color': const Color(0xFF1565C0), 'bg': const Color(0xFFE3F2FD),
        'onTap': () => Navigator.pushNamed(context, '/task-management'),
      },
      {
        'label_en': 'Planning AI', 'label_ar': 'المساعد الذكي',
        'icon': Icons.smart_toy_outlined,
        'color': const Color(0xFF6A1B9A), 'bg': const Color(0xFFF3E5F5),
        'onTap': () => Navigator.pushNamed(context, '/planning-chat'),
      },
      {
        'label_en': 'Budget', 'label_ar': 'الميزانية',
        'icon': Icons.account_balance_wallet_outlined,
        'color': const Color(0xFFE65100), 'bg': const Color(0xFFFFF3E0),
        'onTap': () => Navigator.pushNamed(context, '/budget'),
      },
      {
        'label_en': 'Inventory', 'label_ar': 'المخزون',
        'icon': Icons.inventory_2_outlined,
        'color': const Color(0xFF00695C), 'bg': const Color(0xFFE0F2F1),
        'onTap': () => Navigator.pushNamed(context, '/inventory'),
      },
      {
        'label_en': 'Food Hub', 'label_ar': 'مركز الطعام',
        'icon': Icons.restaurant_outlined,
        'color': const Color(0xFFF57F17), 'bg': const Color(0xFFFFFDE7),
        'onTap': () => Navigator.pushNamed(context, '/food-hub'),
      },
      {
        'label_en': 'Rewards', 'label_ar': 'المكافآت',
        'icon': Icons.emoji_events_outlined,
        'color': const Color(0xFFAD1457), 'bg': const Color(0xFFFCE4EC),
        'onTap': () => Navigator.pushNamed(context, '/rewards'),
      },
      {
        'label_en': 'Family Map', 'label_ar': 'خريطة العائلة',
        'icon': Icons.map_outlined,
        'color': const Color(0xFF1B5E20), 'bg': const Color(0xFFE8F5E9),
        'onTap': () => Navigator.pushNamed(context, '/family-map'),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('QUICK ACTIONS', 'إجراءات سريعة'),
        const SizedBox(height: 14),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.4,
          ),
          itemCount: actions.length,
          itemBuilder: (context, i) {
            final a = actions[i];
            return _buildActionCard(
              labelEn: a['label_en'] as String,
              labelAr: a['label_ar'] as String,
              icon: a['icon'] as IconData,
              color: a['color'] as Color,
              bg: a['bg'] as Color,
              onTap: a['onTap'] as VoidCallback,
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required String labelEn,
    required String labelAr,
    required IconData icon,
    required Color color,
    required Color bg,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 3)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 10),
            Text(
              _t(labelEn, labelAr),
              style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF1A1A1A)),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingActivities() {
    final activities = [
      {'title': 'Requirements Gathering', 'date': 'Mon, 8pm', 'icon': '📄'},
      {'title': 'Family Movie Night', 'date': 'Fri, 8pm', 'icon': '🎬'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('UPCOMING ACTIVITIES', 'الأنشطة القادمة'),
        const SizedBox(height: 15),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Mini Calendar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildCalendarColumn('Sat', [1, 2, 3, 4]),
                  _buildCalendarColumn('Mon', [5, 6, 7, 8]),
                  _buildCalendarColumn('Tue', [9, 10, 11, 12]),
                  _buildCalendarColumn('Wed', [13, 14, 15, 16]),
                  _buildCalendarColumn('Thu', [17, 18, 19, 20], selectedDay: 20),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 15),
              // Activities List
              ...activities.map((activity) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F9F6),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              activity['icon']!,
                              style: const TextStyle(fontSize: 20),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                activity['title']!,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1A1A1A),
                                ),
                              ),
                              Text(
                                activity['date']!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF999999),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Checkbox(
                          value: false,
                          onChanged: (value) {},
                          activeColor: const Color(0xFF4CAF50),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarColumn(String day, List<int> dates, {int? selectedDay}) {
    return Column(
      children: [
        Text(
          day,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF666666),
          ),
        ),
        const SizedBox(height: 8),
        ...dates.map((date) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: date == selectedDay ? const Color(0xFF4CAF50) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    date.toString(),
                    style: TextStyle(
                      fontSize: 12,
                      color: date == selectedDay ? Colors.white : const Color(0xFF666666),
                      fontWeight: date == selectedDay ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            )),
      ],
    );
  }

  Widget _buildSafetySettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('SAFETY & CONNECTION', 'الأمان والتواصل'),
        const SizedBox(height: 15),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildSettingItem(
                icon: Icons.location_on,
                title: 'Location Sharing On',
                subtitle: 'App Access Control',
                value: _locationSharing,
                onChanged: (value) {
                  setState(() {
                    _locationSharing = value;
                  });
                },
              ),
              const SizedBox(height: 15),
              _buildSettingItem(
                icon: Icons.shield,
                title: 'View Protection Setting',
                subtitle: null,
                value: _protectionSetting,
                onChanged: (value) {
                  setState(() {
                    _protectionSetting = value;
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF4CAF50), size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF999999),
                  ),
                ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: const Color(0xFF4CAF50),
        ),
      ],
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 14,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home_rounded, Icons.home_outlined, 'Home', 'الرئيسية', 0),
              _buildNavItem(Icons.emoji_events, Icons.emoji_events_outlined, 'Rewards', 'المكافآت', 1),
              _buildNavItem(Icons.restaurant, Icons.restaurant_outlined, 'Food Hub', 'الطعام', 2),
              _buildNavItem(Icons.map, Icons.map_outlined, 'Map', 'الخريطة', 3),
              _buildNavItem(Icons.settings, Icons.settings_outlined, 'Settings', 'الإعدادات', 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData filledIcon, IconData outlinedIcon, String labelEn, String labelAr, int index) {
    final isActive = _activeTab == index;
    return GestureDetector(
      onTap: () {
        switch (index) {
          case 0:
            setState(() => _activeTab = index);
            break;
          case 1:
            Navigator.pushNamed(context, '/rewards');
            break;
          case 2:
            Navigator.pushNamed(context, '/food-hub');
            break;
          case 3:
            Navigator.pushNamed(context, '/family-map');
            break;
          case 4:
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SettingPage(onLogout: widget.onLogout),
              ),
            );
            break;
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: EdgeInsets.symmetric(horizontal: isActive ? 14 : 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF2E7D32).withOpacity(0.11) : Colors.transparent,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? filledIcon : outlinedIcon,
              color: isActive ? const Color(0xFF2E7D32) : const Color(0xFF999999),
              size: 22,
            ),
            if (isActive) ...[
              const SizedBox(width: 6),
              Text(
                _t(labelEn, labelAr),
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: const Color(0xFF2E7D32),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}