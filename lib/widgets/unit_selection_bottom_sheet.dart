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

  // Admin mode activation state
  int _tapCount = 0;
  DateTime? _lastTapTime;

  @override
  void initState() {
    super.initState();
    _tempSelectedUnits = Set.from(widget.currentlySelectedUnits);
    _searchController.addListener(() => setState(() {})); // Rebuild on text change

    // Load admin mode from SharedPrefs
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<IncidentsProvider>().loadAdminMode();
    });
  }

  void _clearAll() {
    _tempSelectedUnits.clear();
    setState(() {});
    Fluttertoast.showToast(msg: 'All selections cleared');
  }

  void _handleTitleTap() {
    final now = DateTime.now();

    // Reset counter if more than 3 seconds have passed since last tap
    if (_lastTapTime == null || now.difference(_lastTapTime!) > const Duration(seconds: 3)) {
      _tapCount = 1;
    } else {
      _tapCount++;
    }

    _lastTapTime = now;

    // Activate admin mode after 7 taps
    if (_tapCount >= 7) {
      final provider = context.read<IncidentsProvider>();
      provider.toggleAdminMode();

      Fluttertoast.showToast(
        msg: provider.isAdminMode
            ? 'Admin mode enabled - Full wildcard access granted'
            : 'Admin mode disabled',
        backgroundColor: provider.isAdminMode ? Colors.green : Colors.orange,
        toastLength: Toast.LENGTH_LONG,
        timeInSecForIosWeb: 4,
      );

      _tapCount = 0; // Reset counter
      _lastTapTime = null;
    }
  }

  void _addManualUnit() {
    final unit = _searchController.text.trim().toUpperCase();
    if (unit.isEmpty) return;

    // Dismiss keyboard
    FocusScope.of(context).unfocus();

    final provider = context.read<IncidentsProvider>();
    final isAdmin = provider.isAdminMode;

    // Handle wildcards
    if (unit.contains('*')) {
      // Admin: Allow all wildcards via textfield
      if (isAdmin) {
        // Wildcard validation passed, proceed to add
        // (Will be handled by existing conflict detection logic below)
      }
      // Normal user: Block all wildcards in textfield
      else {
        if (unit.startsWith('BC')) {
          Fluttertoast.showToast(
            msg: 'Use the "All Battalion Chiefs" button to add BC wildcards',
            backgroundColor: Colors.orange,
            toastLength: Toast.LENGTH_LONG,
            timeInSecForIosWeb: 4,
          );
        } else {
          Fluttertoast.showToast(
            msg: 'Wildcard access requires admin mode',
            backgroundColor: Colors.red,
            toastLength: Toast.LENGTH_LONG,
            timeInSecForIosWeb: 4,
          );
        }
        return;
      }
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
      final provider = context.read<IncidentsProvider>();
      final isAdmin = provider.isAdminMode;

      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info_outline, size: 64, color: Theme.of(context).disabledColor),
              const SizedBox(height: 16),
              Text(
                'No units selected',
                style: textStyle16Bold.copyWith(color: Theme.of(context).hintColor),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  isAdmin
                      ? 'Type units in the search field or use wildcards (e.g., E*, BC*, MED*)'
                      : 'Type individual units in the search field or use the "All Battalion Chiefs" button',
                  style: textStyle14.copyWith(color: Theme.of(context).hintColor),
                  textAlign: TextAlign.center,
                ),
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

                final isDark = Theme.of(context).brightness == Brightness.dark;

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  color: isDark
                      ? Colors.grey[850]
                      : Colors.grey[100],
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                      color: isDark
                          ? Colors.grey[700]!
                          : Colors.grey[300]!,
                      width: 1,
                    ),
                  ),
                  child: ListTile(
                    leading: Icon(
                      isWildcard ? Icons.star : Icons.circle,
                      color: context.appColors.primaryColor,
                    ),
                    title: Text(
                      displayName,
                      style: textStyle16Bold.copyWith(
                        color: isWildcard
                            ? context.appColors.primaryColor
                            : null,
                      ),
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.close, color: Theme.of(context).colorScheme.error),
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
          GestureDetector(
            onTap: _handleTitleTap,
            child: Text(
              'Select Units',
              style: textStyle20Bold,
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: textStyle16Bold.copyWith(
                color: Theme.of(context).hintColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    final provider = context.watch<IncidentsProvider>();
    final isAdmin = provider.isAdminMode;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _searchController,
        textCapitalization: TextCapitalization.characters,
        inputFormatters: [
          // Allow both uppercase and lowercase letters, numbers, and asterisk (asterisk only for admin)
          FilteringTextInputFormatter.allow(
            isAdmin ? RegExp(r'[A-Za-z0-9*]') : RegExp(r'[A-Za-z0-9]')
          ),
          // Convert all input to uppercase
          TextInputFormatter.withFunction((oldValue, newValue) {
            return TextEditingValue(
              text: newValue.text.toUpperCase(),
              selection: newValue.selection,
            );
          }),
          // Custom formatter to ensure asterisk rules (only applies to admin)
          TextInputFormatter.withFunction((oldValue, newValue) {
            final text = newValue.text;

            // If text contains asterisk, validate its position and count
            if (text.contains('*')) {
              // Non-admin users should never get here due to first formatter,
              // but double-check for safety
              if (!isAdmin) {
                return oldValue;
              }

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
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: Text(
                'Done (${_tempSelectedUnits.length} selected)',
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
    final isAdmin = provider.isAdminMode;

    // Determine which wildcard to show
    String wildcard;
    String label;

    // Normal users: ONLY show BC* (All Battalion Chiefs), never dynamic wildcards
    if (!isAdmin) {
      wildcard = 'BC*';
      final isSelected = _tempSelectedUnits.contains(wildcard);
      label = isSelected ? 'Following All Battalion Chiefs' : 'Follow All Battalion Chiefs';
    }
    // Admin users: Show dynamic wildcards for any text pattern
    else if (searchText.isEmpty) {
      // Default for admin: Show BC* when textfield is empty
      wildcard = 'BC*';
      final isSelected = _tempSelectedUnits.contains(wildcard);
      label = isSelected ? 'Following All Battalion Chiefs' : 'Follow All Battalion Chiefs';
    } else {
      // Admin: Show dynamic wildcard based on input
      wildcard = searchText.endsWith('*') ? searchText : '$searchText*';
      final isSelected = _tempSelectedUnits.contains(wildcard);

      if (searchText == 'BC' || searchText == 'BC*') {
        label = isSelected ? 'Following All Battalion Chiefs' : 'Follow All Battalion Chiefs';
      } else if (searchText.startsWith('BC')) {
        final displayText = searchText.endsWith('*') ? searchText : '$searchText*';
        label = isSelected ? 'Following $displayText Wildcard' : 'Follow $displayText Wildcard';
      } else {
        // Admin wildcard for non-BC units (E*, MED*, etc.)
        final displayText = searchText.endsWith('*') ? searchText : '$searchText*';
        label = isSelected ? 'Following $displayText Wildcard' : 'Follow $displayText Wildcard';
      }
    }

    // Hide if BC* is already selected (unless typing a more specific BC wildcard)
    if (_tempSelectedUnits.contains('BC*') && wildcard == 'BC*') {
      return const SizedBox.shrink();
    }

    final isSelected = _tempSelectedUnits.contains(wildcard);

    final textColor = Theme.of(context).colorScheme.onPrimary;

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
                    color: textColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      label,
                      style: textStyle16Bold.copyWith(
                        color: textColor,
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
              color: textColor,
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
          backgroundColor: context.appColors.primaryColor,
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
                backgroundColor: context.appColors.primaryColor,
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: context.appColors.primaryColor,
            ),
            child: const Text('Replace'),
          ),
        ],
      ),
    );
  }




}
