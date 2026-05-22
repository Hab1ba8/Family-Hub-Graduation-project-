import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/services/api_service.dart';
import '../core/theme/theme_provider.dart';

// Task Model
class TaskItem {
  String id;
  String title;
  String description;
  bool isMandatory;
  String status;
  int points;
  String rewardType;
  double moneyReward;
  String? deadline;
  double progress;
  bool isSelectedToDelete;

  TaskItem({
    required this.id,
    required this.title,
    required this.description,
    this.isMandatory = false,
    this.status = 'assigned',
    this.points = 0,
    this.rewardType = 'points',
    this.moneyReward = 0,
    this.deadline,
    this.progress = 0.0,
    this.isSelectedToDelete = false,
  });

  factory TaskItem.fromJson(Map<String, dynamic> json) {
    double progress = 0.0;
    String status = json['status'] ?? 'assigned';
    if (status == 'completed' || status == 'approved') {
      progress = 1.0;
    } else if (status == 'pending_approval') {
      progress = 0.8;
    } else if (status == 'in_progress') {
      progress = 0.5;
    }

    return TaskItem(
      id: json['_id'] ?? '',
      title: json['task_id']?['title'] ?? json['title'] ?? 'Unknown Task',
      description: json['task_id']?['description'] ?? json['description'] ?? '',
      isMandatory: json['task_id']?['is_mandatory'] ?? json['is_mandatory'] ?? false,
      status: status,
      points: json['assigned_points'] ?? 0,
      rewardType: json['task_id']?['reward_type'] ?? json['reward_type'] ?? 'points',
      moneyReward: ((json['task_id']?['money_reward'] ?? json['money_reward'] ?? 0) as num).toDouble(),
      deadline: json['deadline'],
      progress: progress,
    );
  }

  String get rewardLabel {
    if (rewardType == 'money') {
      return '${moneyReward.toStringAsFixed(2)} EGP';
    }
    if (rewardType == 'both') {
      return '$points pts + ${moneyReward.toStringAsFixed(2)} EGP';
    }
    return '$points pts';
  }

  String get rewardEmoji {
    if (rewardType == 'money') return '💰';
    if (rewardType == 'both') return '⭐💰';
    return '⭐';
  }
}

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();

  late TabController _tabController;
  bool _isDeleteMode = false;
  bool _isLoading = true;

  final _taskNameController = TextEditingController();
  final _taskDescriptionController = TextEditingController();

  List<TaskItem> _mandatoryTasks = [];
  List<TaskItem> _availableTasks = [];

  // ─── Theme constants ───────────────────────────────────────────────────────
  static const _primary = Color(0xFF00897B);
  static const _primaryLight = Color(0xFF00ACC1);
  static const _bgLight = Color(0xFFE8F5F5);
  static const _bgDark = Color(0xFF0A1628);
  static const _cardLight = Colors.white;
  static const _cardDark = Color(0xFF122030);
  static const _borderLight = Color(0xFFB2DFDB);
  static const _borderDark = Color(0xFF1E3A4A);
  static const _borderInner = Color(0xFFE0F2F1);
  static const _textPrimaryLight = Color(0xFF00352E);
  static const _textPrimaryDark = Color(0xFFE0F2F1);
  static const _textSecondaryLight = Color(0xFF4DB6AC);
  static const _textSecondaryDark = Color(0xFF80CBC4);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);
    try {
      final tasks = await _apiService.getMyTasks();
      final mandatory = <TaskItem>[];
      final available = <TaskItem>[];

      for (var task in tasks) {
        final taskItem = TaskItem.fromJson(task);
        if (taskItem.isMandatory) {
          mandatory.add(taskItem);
        } else {
          available.add(taskItem);
        }
      }

      setState(() {
        _mandatoryTasks = mandatory;
        _availableTasks = available;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error loading tasks: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _taskNameController.dispose();
    _taskDescriptionController.dispose();
    super.dispose();
  }

  void _deleteSelectedTasks() {
    setState(() {
      _mandatoryTasks.removeWhere((task) => task.isSelectedToDelete);
      _availableTasks.removeWhere((task) => task.isSelectedToDelete);
      _isDeleteMode = false;
    });
  }

  void _toggleDeleteMode() {
    setState(() {
      _isDeleteMode = !_isDeleteMode;
      for (var task in _mandatoryTasks) {
        task.isSelectedToDelete = false;
      }
      for (var task in _availableTasks) {
        task.isSelectedToDelete = false;
      }
    });
  }

  void _addNewTask() {
    if (_taskNameController.text.isNotEmpty) {
      setState(() {
        final newTask = TaskItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: _taskNameController.text,
          description: _taskDescriptionController.text,
          isMandatory: _tabController.index == 0,
          progress: 0.0,
        );

        if (_tabController.index == 0) {
          _mandatoryTasks.add(newTask);
        } else {
          _availableTasks.add(newTask);
        }
      });

      _taskNameController.clear();
      _taskDescriptionController.clear();
      Navigator.pop(context);
    }
  }

  // ─── Status helpers ────────────────────────────────────────────────────────
  Color _statusDotColor(String status) {
    switch (status) {
      case 'approved':
        return const Color(0xFF00BFA5);
      case 'completed':
      case 'pending_approval':
      case 'in_progress':
        return const Color(0xFF1E88E5);
      case 'rejected':
      case 'late':
        return const Color(0xFFFF5252);
      default:
        return const Color(0xFFFB8C00);
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'approved':
        return 'Done ✓';
      case 'pending_approval':
        return 'Waiting';
      case 'completed':
        return 'Review';
      case 'in_progress':
        return 'Active';
      case 'rejected':
        return 'Rejected';
      case 'late':
        return 'Late';
      default:
        return 'Pending';
    }
  }

  String _formatDeadlineShort(String? deadline) {
    if (deadline == null) return '';
    try {
      final date = DateTime.parse(deadline);
      final now = DateTime.now();
      final diff = date.difference(now);
      if (diff.isNegative) return 'Overdue';
      if (diff.inHours < 24) return '${diff.inHours}h left';
      return '${date.day}/${date.month}';
    } catch (_) {
      return '';
    }
  }

  // ─── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;

    final bgColor = isDark ? _bgDark : _bgLight;
    final textPrimary = isDark ? _textPrimaryDark : _textPrimaryLight;
    final textSecondary = isDark ? _textSecondaryDark : _textSecondaryLight;
    final borderColor = isDark ? _borderDark : _borderLight;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'My Tasks',
          style: GoogleFonts.poppins(
              color: textPrimary, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: _primary),
            onPressed: _loadTasks,
          ),
          IconButton(
            icon: Icon(
              _isDeleteMode ? Icons.close : Icons.delete_outline,
              color: _isDeleteMode ? Colors.red : _primary,
            ),
            onPressed: _toggleDeleteMode,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: _primary))
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  children: [
                    // ── Tab Bar ──────────────────────────────────────────
                    Container(
                      margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1A2F42)
                            : _borderInner,
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(color: borderColor),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        indicator: BoxDecoration(
                          color: _primary,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        labelColor: Colors.white,
                        unselectedLabelColor: textSecondary,
                        labelStyle: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600, fontSize: 12),
                        dividerColor: Colors.transparent,
                        tabs: [
                          Tab(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('Mandatory',
                                    style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12)),
                                if (_mandatoryTasks.isNotEmpty) ...[
                                  const SizedBox(width: 6),
                                  _buildTabBadge(
                                      _mandatoryTasks.length,
                                      isRed: true),
                                ],
                              ],
                            ),
                          ),
                          Tab(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('Available',
                                    style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12)),
                                if (_availableTasks.isNotEmpty) ...[
                                  const SizedBox(width: 6),
                                  _buildTabBadge(
                                      _availableTasks.length,
                                      isRed: false),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Section header ───────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _tabController.index == 0
                                ? 'Mandatory Tasks'
                                : 'Available Tasks',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF1A2F42)
                                  : _borderInner,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: borderColor),
                            ),
                            child: Text(
                              '${_tabController.index == 0 ? _mandatoryTasks.length : _availableTasks.length} tasks',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ── Task lists ───────────────────────────────────────
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildTaskList(_mandatoryTasks, isDark,
                              textPrimary, textSecondary, borderColor),
                          _buildTaskList(_availableTasks, isDark,
                              textPrimary, textSecondary, borderColor),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton:
          _isDeleteMode ? _buildDeleteModeButtons() : _buildNormalButtons(),
    );
  }

  Widget _buildTabBadge(int count, {required bool isRed}) {
    return Container(
      width: 17,
      height: 17,
      decoration: BoxDecoration(
        color: isRed ? const Color(0xFFE53935) : _primaryLight,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          '$count',
          style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 8,
              fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final color = _statusDotColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(
        _statusLabel(status),
        style: GoogleFonts.poppins(
            fontSize: 9, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  Widget _buildNormalButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _showAddTaskModal,
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text(
                'Add Task',
                style: GoogleFonts.poppins(
                    color: Colors.white, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 3,
                shadowColor: _primary.withOpacity(0.4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteModeButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _deleteSelectedTasks,
              icon: const Icon(Icons.delete, color: Colors.white),
              label: Text(
                'Delete Selected',
                style: GoogleFonts.poppins(
                    color: Colors.white, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddTaskModal() {
    final isDark = context.read<ThemeProvider>().isDark;
    final cardColor = isDark ? _cardDark : _cardLight;
    final textPrimary = isDark ? _textPrimaryDark : _textPrimaryLight;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: cardColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text(
            'Add New Task',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold, color: textPrimary),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _taskNameController,
                style: GoogleFonts.poppins(color: textPrimary),
                decoration: InputDecoration(
                  labelText: 'Task Name',
                  labelStyle: GoogleFonts.poppins(
                      color: const Color(0xFF4DB6AC)),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                          color: _borderLight)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: _primary, width: 2)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _taskDescriptionController,
                style: GoogleFonts.poppins(color: textPrimary),
                decoration: InputDecoration(
                  labelText: 'Description',
                  labelStyle: GoogleFonts.poppins(
                      color: const Color(0xFF4DB6AC)),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                          color: _borderLight)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: _primary, width: 2)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel',
                  style: GoogleFonts.poppins(
                      color: const Color(0xFF4DB6AC))),
            ),
            ElevatedButton(
              onPressed: _addNewTask,
              style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
              child: Text('Add',
                  style: GoogleFonts.poppins(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTaskList(
    List<TaskItem> tasks,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color borderColor,
  ) {
    final cardColor = isDark ? _cardDark : _cardLight;

    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.task_alt,
                size: 60,
                color: const Color(0xFF4DB6AC).withOpacity(0.45)),
            const SizedBox(height: 16),
            Text(
              'No tasks in this section!',
              style: GoogleFonts.poppins(color: textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding:
          const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 80),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        final dotColor = _statusDotColor(task.status);
        final isSelected = _isDeleteMode && task.isSelectedToDelete;

        return GestureDetector(
          onTap: () {
            if (_isDeleteMode) {
              setState(() {
                task.isSelectedToDelete = !task.isSelectedToDelete;
              });
            }
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.red.withOpacity(0.08)
                  : cardColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isSelected ? Colors.red : borderColor,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isDark
                  ? []
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Colored status dot
                    Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: dotColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Title + description + reward
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.title,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: textPrimary,
                            ),
                          ),
                          if (task.description.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              task.description,
                              style: GoogleFonts.poppins(
                                  fontSize: 10, color: textSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              if (task.deadline != null) ...[
                                Icon(Icons.schedule,
                                    size: 10, color: textSecondary),
                                const SizedBox(width: 3),
                                Text(
                                  _formatDeadlineShort(task.deadline),
                                  style: GoogleFonts.poppins(
                                      fontSize: 9,
                                      color: textSecondary),
                                ),
                                const SizedBox(width: 8),
                              ],
                              Text(task.rewardEmoji,
                                  style: const TextStyle(fontSize: 11)),
                              const SizedBox(width: 4),
                              Text(
                                task.rewardLabel,
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: _primary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Right: delete icon or status badge
                    const SizedBox(width: 8),
                    if (_isDeleteMode)
                      Icon(
                        isSelected
                            ? Icons.check_circle
                            : Icons.circle_outlined,
                        color: isSelected ? Colors.red : textSecondary,
                        size: 22,
                      )
                    else
                      _buildStatusBadge(task.status),
                  ],
                ),

                // Progress bar
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: task.progress,
                    minHeight: 4,
                    backgroundColor: isDark
                        ? const Color(0xFF1E3A4A)
                        : _borderInner,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(dotColor),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Complete: ${(task.progress * 100).toInt()}%',
                  style: GoogleFonts.poppins(
                    fontSize: 9,
                    color: dotColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
