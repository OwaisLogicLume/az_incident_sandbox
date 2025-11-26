import 'package:az_incident_alert/providers/incidents_provider.dart';
import 'package:az_incident_alert/utils/extensions/context_ext.dart';
import 'package:az_incident_alert/utils/styles.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class UnitSelectionBottomSheet extends StatefulWidget {
  final Set<String> currentlySelectedUnits;
  final Function(List<String>) onUnitsSelected;

  const UnitSelectionBottomSheet({
    required this.currentlySelectedUnits,
    required this.onUnitsSelected,
    super.key,
  });

  @override
  State<UnitSelectionBottomSheet> createState() =>
      _UnitSelectionBottomSheetState();
}

class _UnitSelectionBottomSheetState extends State<UnitSelectionBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  Map<String, List<String>> _categorizedUnits = {};
  Map<String, List<String>> _filteredUnits = {};
  Set<String> _tempSelectedUnits = {};
  Map<String, bool> _expandedCategories = {};

  @override
  void initState() {
    super.initState();
    _tempSelectedUnits = Set.from(widget.currentlySelectedUnits);
    _loadUnits();
    _searchController.addListener(_filterUnits);
  }

  void _loadUnits() {
    final provider = context.read<IncidentsProvider>();
    _categorizedUnits = provider.getCategorizedUnits();
    _filteredUnits = Map.from(_categorizedUnits);

    // Initialize all categories as expanded
    _expandedCategories = {
      for (var category in _categorizedUnits.keys) category: true
    };
    setState(() {});
  }

  void _filterUnits() {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) {
      _filteredUnits = Map.from(_categorizedUnits);
    } else {
      _filteredUnits = {};
      _categorizedUnits.forEach((category, units) {
        final filtered = units
            .where((unit) => unit.toLowerCase().contains(query))
            .toList();
        if (filtered.isNotEmpty) {
          _filteredUnits[category] = filtered;
        }
      });
    }
    setState(() {});
  }

  void _selectAll() {
    _filteredUnits.forEach((category, units) {
      _tempSelectedUnits.addAll(units);
    });
    setState(() {});
  }

  void _deselectAll() {
    _filteredUnits.forEach((category, units) {
      _tempSelectedUnits.removeAll(units);
    });
    setState(() {});
  }

  void _toggleUnit(String unit) {
    if (_tempSelectedUnits.contains(unit)) {
      _tempSelectedUnits.remove(unit);
    } else {
      _tempSelectedUnits.add(unit);
    }
    setState(() {});
  }

  void _toggleCategory(String category) {
    _expandedCategories[category] = !(_expandedCategories[category] ?? true);
    setState(() {});
  }

  void _done() {
    widget.onUnitsSelected(_tempSelectedUnits.toList());
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height,
      decoration: BoxDecoration(
        color: context.appColors.bgColor,
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            _buildActionButtons(),
            Expanded(child: _buildUnitList()),
            _buildManualEntryButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Select Units',
            style: textStyle20Bold,
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search units...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _selectAll,
              child: const Text('Select All'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton(
              onPressed: _deselectAll,
              child: const Text('Clear'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton(
              onPressed: _done,
              style: ElevatedButton.styleFrom(
                backgroundColor: context.appColors.secondaryColor,
              ),
              child: Text('Done (${_tempSelectedUnits.length})'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnitList() {
    if (_filteredUnits.isEmpty) {
      return const Center(
        child: Text('No units found'),
      );
    }

    return ListView(
      children: [
        for (var entry in _filteredUnits.entries)
          _buildCategorySection(entry.key, entry.value),
      ],
    );
  }

  Widget _buildCategorySection(String category, List<String> units) {
    final isExpanded = _expandedCategories[category] ?? true;
    final selectedInCategory =
        units.where((unit) => _tempSelectedUnits.contains(unit)).length;

    return Column(
      children: [
        ListTile(
          leading: Icon(
            isExpanded
                ? Icons.keyboard_arrow_down
                : Icons.keyboard_arrow_right,
          ),
          title: Text(
            '$category - ${units.length} units',
            style: textStyle16Bold,
          ),
          subtitle: selectedInCategory > 0
              ? Text('$selectedInCategory selected')
              : null,
          onTap: () => _toggleCategory(category),
        ),
        if (isExpanded) ...units.map((unit) => _buildUnitCheckbox(unit)),
        const Divider(),
      ],
    );
  }

  Widget _buildUnitCheckbox(String unit) {
    final isSelected = _tempSelectedUnits.contains(unit);
    return CheckboxListTile(
      value: isSelected,
      title: Text(unit),
      onChanged: (value) => _toggleUnit(unit),
      controlAffinity: ListTileControlAffinity.leading,
    );
  }

  Widget _buildManualEntryButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: OutlinedButton.icon(
        onPressed: _showManualEntryDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Custom Unit (Manual Entry)'),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 50),
        ),
      ),
    );
  }

  void _showManualEntryDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Custom Unit'),
        content: TextField(
          controller: controller,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            hintText: 'Enter unit code (e.g., E191)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                _tempSelectedUnits.add(controller.text.trim().toUpperCase());
                setState(() {});
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
