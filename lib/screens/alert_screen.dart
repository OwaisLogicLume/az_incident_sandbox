import 'dart:developer';

import 'package:az_incident_alert/providers/incidents_provider.dart';
import 'package:az_incident_alert/services/firabse_service.dart';
import 'package:az_incident_alert/utils/app_colors.dart';
import 'package:az_incident_alert/utils/app_constants.dart';
import 'package:az_incident_alert/utils/extensions/context_ext.dart';
import 'package:az_incident_alert/utils/styles.dart';
import 'package:az_incident_alert/widgets/app_scaffold.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';

class AlertScreen extends StatefulWidget {
  const AlertScreen({super.key});

  @override
  State<AlertScreen> createState() => _AlertScreenState();
}

class _AlertScreenState extends State<AlertScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final FocusNode _unitsFieldFocus = FocusNode();
  final TextEditingController _unitController = TextEditingController();
  

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      context.read<IncidentsProvider>().changeShowUnitsField(false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<IncidentsProvider>(builder: (context, provider, _) {
      return AppScaffold(
        appbarTitle: 'Alerts',
        appbarActions: [
          IconButton(
            onPressed: () {
              log('changing showUnits to => ${!provider.showUnitsField}');
              provider.changeShowUnitsField(!provider.showUnitsField);
              if (provider.showUnitsField) _unitsFieldFocus.requestFocus();
            },
            icon: Icon(!provider.showUnitsField ? Icons.add : Icons.clear),
          )
        ],
        appbarBottom: (provider.showUnitsField)
            ? _buildUnitsField(provider)
            : const PreferredSize(preferredSize: Size.zero, child: SizedBox()),
        body: provider.selectedUnits.isEmpty
            ? Center(
                child: Text(
                  'No units added.',
                  style: textStyle14,
                ),
              )
            : ListView.builder(
                itemCount: provider.selectedUnits.length,
                itemBuilder: (context, index) {
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border(
                        top: index == 0
                            ? BorderSide(color: context.appColors.primaryColor)
                            : BorderSide.none,
                        bottom:
                            BorderSide(color: context.appColors.primaryColor),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          provider.selectedUnits.toList()[index],
                          style: textStyle16Bold,
                        ),
                        IconButton(
                          onPressed: () {
                            provider.removeSelectedUnit(
                                provider.selectedUnits.toList()[index]);
                          },
                          icon: const Icon(Icons.remove),
                        )
                      ],
                    ),
                  );
                },
              ),
      );
    });
  }

  _buildUnitsField(IncidentsProvider provider) => PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: Container(
          color: context.appColors.bgColor,
          child: Form(
            key: _formKey,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _unitController,
                      focusNode: _unitsFieldFocus,
                      keyboardType: TextInputType.text,
                      textCapitalization: TextCapitalization.characters,
                      inputFormatters: [UppercaseAndNumericInputFormatter()],
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Add the unit number you want to alert for',
                      ),
                      onFieldSubmitted: (_) {
                        if (_formKey.currentState?.validate() == true) {
                          provider.addSelectedUnit(
                            _unitController.text.trim(),
                            () {
                              Fluttertoast.showToast(
                                msg: 'The unit is already saved for alerts.',
                              );
                            },
                          );
                          _unitController.clear();
                          provider.changeShowUnitsField(false);
                        }
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty == true) {
                          return 'Enter valid ubit nember';
                        }
                        return null;
                      },
                    ),
                  ),
                  10.horizontalSpace,
                  SizedBox.square(
                    dimension: 55,
                    child: IconButton(
                      onPressed: () {
                        if (_formKey.currentState?.validate() == true) {
                          provider.addSelectedUnit(
                            _unitController.text.trim(),
                            () {
                              Fluttertoast.showToast(
                                msg: 'The unit is already saved for alerts.',
                              );
                            },
                          );
                          _unitController.clear();
                          provider.changeShowUnitsField(false);
                        }
                      },
                      style: IconButton.styleFrom(
                        backgroundColor: context.appColors.primaryColor,
                        foregroundColor:
                            context.isDark ? AppColors.black : AppColors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(CupertinoIcons.check_mark),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      );
}

class UppercaseAndNumericInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    log('newValue => ${newValue..text.toUpperCase()}');
    log('oldValue => $oldValue');

    String newText = newValue.text.toUpperCase();

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}
