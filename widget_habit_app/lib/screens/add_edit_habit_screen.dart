import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/habit.dart';
import '../providers.dart';

class AddEditHabitScreen extends ConsumerStatefulWidget {
  final Habit? habit;

  const AddEditHabitScreen({super.key, this.habit});

  @override
  ConsumerState<AddEditHabitScreen> createState() => _AddEditHabitScreenState();
}

class _AddEditHabitScreenState extends ConsumerState<AddEditHabitScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _targetController = TextEditingController();

  late HabitType _selectedType;
  late int _iconId;
  late String _colorHex;
  late List<int> _frequency;
  late String? _selectedUnit;
  late double _completionThreshold;

  // Date range variables (Phase 3A.2.2)
  DateTime? _startDate;
  DateTime? _endDate;

  // Available units for measurable habits
  final List<String> _availableUnits = [
    'glasses',
    'cups',
    'liters',
    'steps',
    'minutes',
    'hours',
    'pages',
    'exercises',
    'reps',
    'sets',
    'km',
    'miles',
  ];

  // Unit emojis for better UX
  final Map<String, String> _unitEmojis = {
    'glasses': '🥛',
    'cups': '☕',
    'liters': '💧',
    'steps': '👣',
    'minutes': '⏱️',
    'hours': '🕐',
    'pages': '📄',
    'exercises': '🏃‍♂️',
    'reps': '💪',
    'sets': '🏋️‍♂️',
    'km': '🚗',
    'miles': '🚗',
  };

  // Color options
  final List<Color> _colorOptions = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.pink,
    Colors.teal,
    Colors.indigo,
  ];

  @override
  void initState() {
    super.initState();
    final habit = widget.habit;

    _nameController.text = habit?.name ?? '';
    _selectedType = habit?.type ?? HabitType.simple;
    _iconId = habit?.iconId ?? 0;
    _colorHex = habit?.colorHex ?? '#FF2196F3'; // Default blue
    _frequency = habit?.frequency ?? [1, 2, 3, 4, 5, 6, 7]; // All days default
    _selectedUnit = habit?.unit;
    _completionThreshold = habit?.completionThreshold ?? 1.0;

    if (habit?.targetValue != null) {
      _targetController.text = habit!.targetValue.toString();
    }

    // Date range variables (Phase 3A.2.2)
    _startDate = habit?.startDate ?? DateTime.now();
    _endDate = habit?.endDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      // Validate start date is required
      if (_startDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a start date'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Validate measurable habit specific fields
      if (_selectedType == HabitType.measurable) {
        if (_targetController.text.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enter a target value')),
          );
          return;
        }
        if (_selectedUnit == null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Please select a unit')));
          return;
        }
      }

      final targetValue = _selectedType == HabitType.measurable
          ? int.tryParse(_targetController.text)
          : null;

      final newHabit = Habit(
        id: widget.habit?.id ?? const Uuid().v4(),
        name: _nameController.text.trim(),
        iconId: _iconId,
        colorHex: _colorHex,
        frequency: _frequency,
        creationDate: widget.habit?.creationDate ?? DateTime.now(),
        type: _selectedType,
        targetValue: targetValue,
        unit: _selectedType == HabitType.measurable ? _selectedUnit : null,
        completionThreshold: _completionThreshold,
        // Date range (Phase 3A.2.2)
        startDate: _startDate,
        endDate: _endDate,
        // Preserve existing data if editing
        completedDates: widget.habit?.completedDates,
        missedDates: widget.habit?.missedDates,
        dailyValues: widget.habit?.dailyValues,
      );

      if (widget.habit == null) {
        ref.read(habitsProvider.notifier).addHabit(newHabit);
      } else {
        ref.read(habitsProvider.notifier).updateHabit(newHabit);
      }

      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.habit == null ? 'Add Habit' : 'Edit Habit'),
        actions: [IconButton(icon: const Icon(Icons.save), onPressed: _submit)],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Habit Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Habit Name',
                  hintText: 'e.g., Drink Water, Exercise, Read',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a habit name';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Habit Type Selection
              Text(
                'Habit Type',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              _buildHabitTypeSelector(),

              const SizedBox(height: 24),

              // Conditional fields for measurable habits
              if (_selectedType == HabitType.measurable) ...[
                _buildMeasurableFields(),
                const SizedBox(height: 24),
              ],

              // Color Selection
              Text('Color', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              _buildColorSelector(),

              const SizedBox(height: 24),

              // Frequency Selection
              Text('Frequency', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              _buildFrequencySelector(),

              const SizedBox(height: 24),

              // Date Range Selection (Phase 3A.2.2)
              Text(
                'Date Range',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              _buildDateRangeSelector(),

              const SizedBox(height: 32),

              // Preview
              _buildPreview(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHabitTypeSelector() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          RadioListTile<HabitType>(
            title: const Text('Simple'),
            subtitle: const Text('Complete or miss (✓/✗)'),
            value: HabitType.simple,
            groupValue: _selectedType,
            onChanged: (value) {
              setState(() {
                _selectedType = value!;
              });
            },
          ),
          const Divider(height: 1),
          RadioListTile<HabitType>(
            title: const Text('Measurable'),
            subtitle: const Text('Track progress with numbers (3/8 glasses)'),
            value: HabitType.measurable,
            groupValue: _selectedType,
            onChanged: (value) {
              setState(() {
                _selectedType = value!;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMeasurableFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _targetController,
                decoration: const InputDecoration(
                  labelText: 'Target',
                  hintText: '8',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (_selectedType == HabitType.measurable) {
                    if (value == null || value.isEmpty) {
                      return 'Required';
                    }
                    final intValue = int.tryParse(value);
                    if (intValue == null || intValue <= 0) {
                      return 'Enter a positive number';
                    }
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 3,
              child: DropdownButtonFormField<String>(
                value: _selectedUnit,
                decoration: const InputDecoration(
                  labelText: 'Unit',
                  border: OutlineInputBorder(),
                ),
                hint: const Text('Select unit'),
                items: _availableUnits.map((unit) {
                  final emoji = _unitEmojis[unit] ?? '';
                  return DropdownMenuItem(
                    value: unit,
                    child: Text('$emoji $unit'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedUnit = value;
                  });
                },
                validator: (value) {
                  if (_selectedType == HabitType.measurable && value == null) {
                    return 'Select a unit';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildColorSelector() {
    return Wrap(
      spacing: 8,
      children: _colorOptions.map((color) {
        final isSelected =
            _colorHex ==
            '#FF${color.value.toRadixString(16).substring(2).toUpperCase()}';
        return GestureDetector(
          onTap: () {
            setState(() {
              _colorHex =
                  '#FF${color.value.toRadixString(16).substring(2).toUpperCase()}';
            });
          },
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: isSelected
                  ? Border.all(color: Colors.white, width: 3)
                  : null,
            ),
            child: isSelected
                ? const Icon(Icons.check, color: Colors.white, size: 20)
                : null,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFrequencySelector() {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return Wrap(
      spacing: 8,
      children: List.generate(7, (index) {
        final dayIndex = index + 1;
        final isSelected = _frequency.contains(dayIndex);
        return FilterChip(
          label: Text(days[index]),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _frequency.add(dayIndex);
              } else {
                _frequency.remove(dayIndex);
              }
              _frequency.sort();
            });
          },
        );
      }),
    );
  }

  Widget _buildDateRangeSelector() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Start Date Picker
          ListTile(
            leading: const Icon(Icons.event_note),
            title: const Text('Start Date'),
            subtitle: Text(
              _startDate == null
                  ? 'Select start date'
                  : _formatDate(_startDate!),
            ),
            trailing: _startDate != null
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => setState(() => _startDate = null),
                  )
                : null,
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _startDate ?? DateTime.now(),
                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                lastDate:
                    _endDate?.subtract(const Duration(days: 1)) ??
                    DateTime.now().add(const Duration(days: 365)),
              );
              if (date != null) {
                setState(() => _startDate = date);
              }
            },
          ),
          const Divider(height: 1),
          // End Date Picker
          ListTile(
            leading: const Icon(Icons.event_available),
            title: Text(
              _endDate == null ? 'Active until (optional)' : 'Active until',
            ),
            subtitle: Text(
              _endDate == null ? 'No end date' : _formatDate(_endDate!),
            ),
            trailing: _endDate != null
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => setState(() => _endDate = null),
                  )
                : null,
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate:
                    _endDate ??
                    (_startDate?.add(const Duration(days: 30)) ??
                        DateTime.now().add(const Duration(days: 30))),
                firstDate:
                    _startDate?.add(const Duration(days: 1)) ?? DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (date != null) {
                // Phase 3A.2.2: Validate end date is not in the past
                if (date.isBefore(
                  DateTime.now().subtract(const Duration(days: 1)),
                )) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Bro, which idiot is gonna end a habit in the fucking past?",
                      ),
                      duration: Duration(seconds: 3),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                setState(() => _endDate = date);
              }
            },
          ),
        ],
      ),
    );
  }

  // Helper method for date formatting
  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return "${months[date.month - 1]} ${date.day}${date.year != DateTime.now().year ? ', ${date.year}' : ''}";
  }

  Widget _buildPreview() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[600]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Preview', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Color(int.parse(_colorHex.substring(1), radix: 16)),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _nameController.text.isEmpty
                      ? 'Habit Name'
                      : _nameController.text,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              if (_selectedType == HabitType.measurable &&
                  _targetController.text.isNotEmpty &&
                  _selectedUnit != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[700],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '0/${_targetController.text} ${_unitEmojis[_selectedUnit] ?? ''} $_selectedUnit',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ],
          ),
          // Date range preview
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 16,
                color: _startDate == null ? Colors.red : Colors.grey,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _getDateRangePreviewText(),
                  style: TextStyle(
                    fontSize: 12,
                    color: _startDate == null ? Colors.red : Colors.grey,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getDateRangePreviewText() {
    if (_startDate == null) {
      return 'Please select start date';
    } else if (_endDate == null) {
      return 'Starts ${_formatDate(_startDate!)}';
    } else {
      return 'Active from ${_formatDate(_startDate!)} to ${_formatDate(_endDate!)}';
    }
  }
}
