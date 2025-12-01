import 'package:az_incident_alert/providers/incidents_provider.dart';
import 'package:az_incident_alert/utils/app_colors.dart';
import 'package:az_incident_alert/utils/extensions/context_ext.dart';
import 'package:az_incident_alert/utils/styles.dart';
import 'package:flutter/material.dart';
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

    if (_tempSelectedUnits.contains(unit)) {
      Fluttertoast.showToast(msg: '$unit is already selected');
      return;
    }

    _tempSelectedUnits.add(unit);
    _searchController.clear();
    setState(() {});
    Fluttertoast.showToast(
      msg: 'Added $unit',
      backgroundColor: context.appColors.primaryColor,
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
                  child: ListTile(
                    leading: Icon(
                      isWildcard ? Icons.star : Icons.person,
                      color: isWildcard
                          ? context.appColors.primaryColor
                          : Colors.grey[600],
                    ),
                    title: Text(
                      displayName,
                      style: textStyle16Bold.copyWith(
                        color: isWildcard
                            ? context.appColors.primaryColor
                            : null,
                      ),
                    ),
                    subtitle: isWildcard ? Text('Wildcard: $unit') : null,
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
            _buildQuickFollowSection(),
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







  Widget _buildQuickFollowSection() {
    const commonCategories = ['E', 'BC', 'AM', 'L', 'SQ', 'R', 'HM'];
    final provider = context.read<IncidentsProvider>();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('Quick Follow', style: textStyle16Bold),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: commonCategories.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final prefix = commonCategories[index];
                final wildcard = '$prefix*';
                final isSelected = _tempSelectedUnits.contains(wildcard);

                return isSelected
                    ? ElevatedButton.icon(
                        icon: const Icon(Icons.star, size: 16),
                        label: Text(provider.getWildcardDisplayName(wildcard)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.dPrimary,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => _toggleWildcard(wildcard),
                      )
                    : OutlinedButton.icon(
                        icon: const Icon(Icons.star_border, size: 16),
                        label: Text(provider.getWildcardDisplayName(wildcard)),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppColors.dPrimary),
                          foregroundColor: AppColors.dPrimary,
                        ),
                        onPressed: () => _toggleWildcard(wildcard),
                      );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicWildcard() {
    final searchText = _searchController.text.trim().toUpperCase();
    if (searchText.isEmpty) return const SizedBox.shrink();

    final provider = context.read<IncidentsProvider>();
    final wildcard = '$searchText*';
    final matchCount = provider.getWildcardMatchCount(wildcard);
    final isSelected = _tempSelectedUnits.contains(wildcard);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.dPrimary.withOpacity(0.2)
            : AppColors.dPrimary.withOpacity(0.1),
        border: Border.all(
          color: AppColors.dPrimary,
          width: isSelected ? 3 : 2,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(
          isSelected ? Icons.star : Icons.star_border,
          color: AppColors.dPrimary,
          size: 32,
        ),
        title: Text(
          isSelected
              ? 'Following ALL $searchText units'
              : 'Follow ALL $searchText units',
          style: textStyle16Bold.copyWith(
            color: AppColors.dPrimary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
          ),
        ),
        subtitle: matchCount != null && matchCount > 0
            ? Text('Currently ~$matchCount active units')
            : Text('Wildcard: $wildcard'),
        trailing: Icon(
          isSelected ? Icons.check_circle : Icons.add_circle,
          color: AppColors.dPrimary,
          size: 32,
        ),
        onTap: () => _toggleWildcard(wildcard),
      ),
    );
  }

  void _toggleWildcard(String wildcard) {
    final provider = context.read<IncidentsProvider>();
    final displayName = provider.getWildcardDisplayName(wildcard);

    if (_tempSelectedUnits.contains(wildcard)) {
      // Remove wildcard
      _tempSelectedUnits.remove(wildcard);
      setState(() {});
      Fluttertoast.showToast(
        msg: 'Stopped following $displayName',
        backgroundColor: Colors.grey[700],
      );
    } else {
      // Add wildcard
      _tempSelectedUnits.add(wildcard);
      setState(() {});
      Fluttertoast.showToast(
        msg: 'Now following $displayName',
        backgroundColor: AppColors.dPrimary,
      );
    }
  }




}
