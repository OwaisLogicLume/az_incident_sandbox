import 'package:az_incident_alert/providers/incidents_provider.dart';
import 'package:az_incident_alert/utils/app_colors.dart';
import 'package:az_incident_alert/utils/extensions/context_ext.dart';
import 'package:az_incident_alert/utils/styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
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
  Set<String> _tempSelectedUnits = {};

  @override
  void initState() {
    super.initState();
    _tempSelectedUnits = Set.from(widget.currentlySelectedUnits);
    _searchController.addListener(() => setState(() {})); // Rebuild on text change
  }

  void _clearAll() {
    _tempSelectedUnits.clear();
    setState(() {});
    Fluttertoast.showToast(msg: 'All selections cleared');
  }

  void _addManualUnit() {
    final unit = _searchController.text.trim().toUpperCase();
    if (unit.isEmpty) return;

    // Dismiss keyboard
    FocusScope.of(context).unfocus();

    // Block any wildcards - they should use the dynamic wildcard card
    if (unit.contains('*')) {
      if (unit.startsWith('BC')) {
        Fluttertoast.showToast(
          msg: 'Use the wildcard option shown below to add BC wildcards',
          backgroundColor: Colors.orange,
          toastLength: Toast.LENGTH_LONG,
          timeInSecForIosWeb: 4,
        );
      } else {
        Fluttertoast.showToast(
          msg: 'Wildcards are only available for Battalion Chiefs',
          backgroundColor: Colors.red,
          toastLength: Toast.LENGTH_LONG,
          timeInSecForIosWeb: 4,
        );
      }
      return;
    }

    if (_tempSelectedUnits.contains(unit)) {
      Fluttertoast.showToast(
        msg: '$unit is already selected',
        timeInSecForIosWeb: 3,
      );
      return;
    }

    // Check if this individual BC unit is covered by existing wildcards
    if (unit.startsWith('BC')) {
      final coveringWildcards = _checkIndividualUnitConflicts(unit);
      if (coveringWildcards.isNotEmpty) {
        final provider = context.read<IncidentsProvider>();
        final wildcardName = provider.getWildcardDisplayName(coveringWildcards.first);
        Fluttertoast.showToast(
          msg: 'Already following $wildcardName which includes $unit',
          backgroundColor: Colors.orange,
          toastLength: Toast.LENGTH_LONG,
          timeInSecForIosWeb: 4,
        );
        return;
      }
    }

    _tempSelectedUnits.add(unit);
    _searchController.clear();
    setState(() {});
    Fluttertoast.showToast(
      msg: 'Added $unit',
      backgroundColor: context.appColors.primaryColor,
      timeInSecForIosWeb: 3,
    );
  }

  Widget _buildSelectedUnitsList() {
    if (_tempSelectedUnits.isEmpty) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info_outline, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No units selected',
                style: textStyle16Bold.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Text(
                'Use Quick Follow, wildcards, or type to add units',
                style: textStyle14.copyWith(color: Colors.grey[500]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Selected Units (${_tempSelectedUnits.length})',
              style: textStyle16Bold,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: _tempSelectedUnits.length,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemBuilder: (context, index) {
                final unit = _tempSelectedUnits.toList()[index];
                final provider = context.read<IncidentsProvider>();
                final isWildcard = provider.isWildcard(unit);
                final displayName = isWildcard
                    ? provider.getWildcardDisplayName(unit)
                    : unit;

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  color: Theme.of(context).scaffoldBackgroundColor,
                  elevation: 1,
                  child: ListTile(
                    leading: Icon(
                      isWildcard ? Icons.star : Icons.circle,
                      color: context.appColors.primaryColor,
                    ),
                    title: Text(
                      isWildcard ? '$displayName ($unit)' : displayName,
                      style: textStyle16Bold.copyWith(
                        color: isWildcard
                            ? context.appColors.primaryColor
                            : null,
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () {
                        _tempSelectedUnits.remove(unit);
                        setState(() {});
                        Fluttertoast.showToast(
                          msg: 'Removed ${isWildcard ? displayName : unit}',
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
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
            _buildDynamicWildcard(),
            const SizedBox(height: 16),
            _buildSelectedUnitsList(),
            _buildActionButtons(),
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
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: textStyle16Bold.copyWith(
                color: Colors.grey[600],
              ),
            ),
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
        textCapitalization: TextCapitalization.characters,
        inputFormatters: [
          // Allow only letters, numbers, and asterisk
          FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9*]')),
          // Custom formatter to ensure asterisk rules
          TextInputFormatter.withFunction((oldValue, newValue) {
            final text = newValue.text;

            // If text contains asterisk, validate its position and count
            if (text.contains('*')) {
              // Count asterisks
              final asteriskCount = text.split('*').length - 1;

              // Only allow one asterisk
              if (asteriskCount > 1) {
                return oldValue;
              }

              // Asterisk must be at the end
              if (!text.endsWith('*')) {
                return oldValue;
              }
            }

            return newValue;
          }),
        ],
        decoration: InputDecoration(
          hintText: 'Type unit to add manually (e.g., E191, BC3)...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          suffixIcon: _searchController.text.trim().isNotEmpty
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.add_circle, color: context.appColors.primaryColor),
                      onPressed: () => _addManualUnit(),
                      tooltip: 'Add this unit',
                    ),
                  ],
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _clearAll,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Clear All'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _done,
              style: ElevatedButton.styleFrom(
                backgroundColor: context.appColors.primaryColor,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: Text(
                'Done (${_tempSelectedUnits.length} selected)',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }






  Widget _buildDynamicWildcard() {
    final searchText = _searchController.text.trim().toUpperCase();
    final provider = context.read<IncidentsProvider>();

    // Determine which wildcard to show
    String wildcard;
    String label;

    if (searchText.isEmpty || !searchText.startsWith('BC')) {
      // Default: Show BC* (All Battalion Chiefs)
      wildcard = 'BC*';
      final isSelected = _tempSelectedUnits.contains(wildcard);
      label = isSelected ? 'Following All Battalion Chiefs' : 'Follow All Battalion Chiefs';
    } else {
      // Show dynamic wildcard based on BC input
      // Don't add * if user already typed it
      wildcard = searchText.endsWith('*') ? searchText : '$searchText*';
      final isSelected = _tempSelectedUnits.contains(wildcard);

      if (searchText == 'BC' || searchText == 'BC*') {
        label = isSelected ? 'Following All Battalion Chiefs' : 'Follow All Battalion Chiefs';
      } else {
        final displayText = searchText.endsWith('*') ? searchText : '$searchText*';
        label = isSelected ? 'Following $displayText Wildcard' : 'Follow $displayText Wildcard';
      }
    }

    // Hide if BC* is already selected (unless typing a more specific BC wildcard)
    if (_tempSelectedUnits.contains('BC*') && wildcard == 'BC*') {
      return const SizedBox.shrink();
    }

    final isSelected = _tempSelectedUnits.contains(wildcard);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(
          color: context.appColors.primaryColor,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(8),
        color: isSelected
            ? context.appColors.primaryColor
            : context.appColors.primaryColor.withOpacity(0.9),
      ),
      child: InkWell(
        onTap: () => _toggleWildcard(wildcard),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Icon(
                    isSelected ? Icons.star : Icons.star_border,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      label,
                      style: textStyle16Bold.copyWith(
                        color: Colors.white,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle : Icons.add_circle_outline,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }

  void _toggleWildcard(String wildcard) {
    // Dismiss keyboard
    FocusScope.of(context).unfocus();

    final provider = context.read<IncidentsProvider>();
    final displayName = provider.getWildcardDisplayName(wildcard);

    if (_tempSelectedUnits.contains(wildcard)) {
      // Remove wildcard
      _tempSelectedUnits.remove(wildcard);
      setState(() {});
      Fluttertoast.showToast(
        msg: 'Stopped following $displayName',
        backgroundColor: Colors.grey[700],
        timeInSecForIosWeb: 3,
      );
    } else {
      // Check for superset/subset conflicts before adding
      final conflicts = _checkWildcardConflicts(wildcard);

      if (conflicts['subsets']!.isNotEmpty) {
        // Adding a superset - show confirmation to replace subsets
        _showSupersetConfirmation(wildcard, conflicts['subsets']!);
      } else if (conflicts['supersets']!.isNotEmpty) {
        // Trying to add a subset when superset exists - show error
        final supersetName = provider.getWildcardDisplayName(conflicts['supersets']!.first);
        Fluttertoast.showToast(
          msg: 'Already following $supersetName which includes ${wildcard.replaceAll('*', '')}* units',
          backgroundColor: Colors.orange,
          toastLength: Toast.LENGTH_LONG,
          timeInSecForIosWeb: 4,
        );
      } else {
        // No conflicts - add normally
        _tempSelectedUnits.add(wildcard);
        setState(() {});
        Fluttertoast.showToast(
          msg: 'Now following $displayName',
          backgroundColor: AppColors.dPrimary,
          timeInSecForIosWeb: 3,
        );
      }
    }
  }

  Map<String, List<String>> _checkWildcardConflicts(String wildcard) {
    final wildcardPrefix = wildcard.replaceAll('*', '');
    final subsets = <String>[];
    final supersets = <String>[];

    for (final selected in _tempSelectedUnits) {
      if (selected.contains('*')) {
        // Check wildcard-to-wildcard conflicts
        final selectedPrefix = selected.replaceAll('*', '');

        // Check if selected is a subset of wildcard (wildcard is more general)
        if (selectedPrefix.startsWith(wildcardPrefix) && selectedPrefix != wildcardPrefix) {
          subsets.add(selected);
        }

        // Check if selected is a superset of wildcard (selected is more general)
        if (wildcardPrefix.startsWith(selectedPrefix) && wildcardPrefix != selectedPrefix) {
          supersets.add(selected);
        }
      } else {
        // Check wildcard-to-individual unit conflicts
        // If individual unit starts with wildcard prefix, it's covered by the wildcard
        if (selected.startsWith(wildcardPrefix)) {
          subsets.add(selected);
        }
      }
    }

    return {'subsets': subsets, 'supersets': supersets};
  }

  List<String> _checkIndividualUnitConflicts(String unit) {
    // Check if this individual unit is covered by any existing wildcards
    final coveringWildcards = <String>[];

    for (final selected in _tempSelectedUnits) {
      if (!selected.contains('*')) continue; // Skip non-wildcards

      final wildcardPrefix = selected.replaceAll('*', '');

      // If unit starts with wildcard prefix, it's covered by that wildcard
      if (unit.startsWith(wildcardPrefix)) {
        coveringWildcards.add(selected);
      }
    }

    return coveringWildcards;
  }

  void _showSupersetConfirmation(String wildcard, List<String> subsets) {
    final provider = context.read<IncidentsProvider>();
    final wildcardName = provider.getWildcardDisplayName(wildcard);

    // Format subset names (handle both wildcards and individual units)
    final subsetNames = subsets.map((s) {
      if (s.contains('*')) {
        return provider.getWildcardDisplayName(s);
      } else {
        return s; // Individual unit
      }
    }).join(', ');

    // Count wildcards vs individual units
    final wildcardCount = subsets.where((s) => s.contains('*')).length;
    final unitCount = subsets.length - wildcardCount;

    String itemsType = '';
    if (wildcardCount > 0 && unitCount > 0) {
      itemsType = 'wildcards and units';
    } else if (wildcardCount > 0) {
      itemsType = 'wildcard${wildcardCount > 1 ? 's' : ''}';
    } else {
      itemsType = 'unit${unitCount > 1 ? 's' : ''}';
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Replace $itemsType?'),
        content: Text(
          '$wildcardName includes the following $itemsType you\'re currently following:\n\n$subsetNames\n\nWould you like to replace them with $wildcardName?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Remove all subsets and add the superset
              for (final subset in subsets) {
                _tempSelectedUnits.remove(subset);
              }
              _tempSelectedUnits.add(wildcard);
              setState(() {});
              Navigator.pop(context);
              Fluttertoast.showToast(
                msg: 'Now following $wildcardName',
                backgroundColor: AppColors.dPrimary,
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.dPrimary,
            ),
            child: const Text('Replace'),
          ),
        ],
      ),
    );
  }




}
