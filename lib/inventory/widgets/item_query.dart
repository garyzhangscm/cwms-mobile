

import 'package:cwms_mobile/exception/WebAPICallException.dart';
import 'package:cwms_mobile/i18n/localization_intl.dart';
import 'package:cwms_mobile/inventory/models/item.dart';
import 'package:cwms_mobile/inventory/services/item.dart';
import 'package:cwms_mobile/shared/functions.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';


class ItemQuery extends StatefulWidget {
  ItemQuery({required this.itemNumberController,
        this.autofocus = true, required this.onItemSelected,
        required this.focusNode,
        required this.validator, Key? key}) : super(key: key);


  final TextEditingController itemNumberController;
  final bool? autofocus;

  final FocusNode focusNode;

  final FormFieldValidator<String> validator;
  final ValueChanged<Item> onItemSelected;

  @override
  _ItemQueryState createState() => _ItemQueryState();


}

class _ItemQueryState extends State<ItemQuery> {

  void _onItemSelected(Item selectedItem) {
    if (widget.onItemSelected != null) {

      widget.onItemSelected(selectedItem);
    }
  }

  TextEditingController _itemCriteriaInputController = new TextEditingController();

  List<Item> _matchedItemList = [];

  @override
  Widget build(BuildContext context) {

    return Padding(
      padding: const EdgeInsets.only(top: 2.0),
      child:
        TextFormField(
            controller: widget.itemNumberController,
            validator: widget.validator,
            autofocus: widget.autofocus == true? true : false,
            focusNode: widget.focusNode,
            decoration: InputDecoration(
              suffixIcon:
                    IconButton(
                      onPressed: () => _openItemQueryModal(),
                      icon: Icon(Icons.search),
                    ),
                ),
            )
    );
  }

  Future<void> _openItemQueryModal() async {
   _itemCriteriaInputController.text = "";
   await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          _matchedItemList = [];
          return StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return AlertDialog(
                    content:
                    Column(
                        children: <Widget>[
                          // input controller for the user to type in criteria and search

                          Padding(
                              padding: EdgeInsets.only(left: 5, right: 5),
                              child:
                              TextFormField(
                                controller: _itemCriteriaInputController,
                                decoration: InputDecoration(
                                  suffixIcon:
                                  IconButton(
                                    onPressed: () => _search(setState),
                                    icon: Icon(Icons.search),
                                  ),
                                ),
                              )
                          ),
                          SizedBox(
                              height: 300,
                              child:
                              Padding(
                                padding: const EdgeInsets.only(top: 2.0),
                                child:
                                ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: _matchedItemList.length,
                                    itemBuilder: (_, index) {
                                      return ListTile(
                                        title: Text(
                                            _matchedItemList[index].name ?? ""),
                                        subtitle: Text(_matchedItemList[index]
                                            .description ?? ""),
                                        onTap: () {
                                          _selectItem(index);
                                        },
                                      );
                                      /*
                                return ItemQueryListItem(
                                    index: index,
                                    item: _matchedItemList[index],
                                    onSelected:  (selected) {
                                      _selectItem(index);
                                    }
                                );
                                */
                                    }
                                ),
                              )
                            /**
                                new ListView(
                                children: _matchedItemList.map((Item item) {
                                return new ListTile(
                                title: Text(item.name),
                                subtitle: Text(item.description),
                                selected: _selectedItem != null && _selectedItem.id == item.id,
                                selectedTileColor: Colors.white10,
                                onTap: () {
                                setState(() {
                                _selectedItem = item;
                                printLongLogMessage("_selected item is set to ${_selectedItem.name}");
                                });
                                },
                                );
                                }).toList()),*/
                          ),
                        ])
                );
              });
        });
  }

  _selectItem(int index) {
    printLongLogMessage("_selectItem WITH index ${index}");
    widget.itemNumberController.text = _matchedItemList[index].name ?? "";
    _onItemSelected(_matchedItemList[index]);
    Navigator.of(context).pop();
  }

  void _search(StateSetter setState) async {

    showLoading(context);

    if (_itemCriteriaInputController.text.isEmpty) {
      _matchedItemList = [];
    }
    else {

        try {

          _matchedItemList = await ItemService.queryItemByKeyword(_itemCriteriaInputController.text);
        }
        on WebAPICallException catch(ex) {
          Navigator.of(context).pop();
          showErrorDialog(context, "can't find item by  ${_itemCriteriaInputController.text}");
          return;
        }
    }


    printLongLogMessage("we get ${_matchedItemList.length} by keywrod: ${_itemCriteriaInputController.text}");

    setState(() {
      _matchedItemList = _matchedItemList;
    });

    Navigator.of(context).pop();
    //if (_matchedItemList.isEmpty) {

      //  showErrorDialog(context, "can't find item by  ${_itemCriteriaInputController.text}");
    //}

    return;
  }




}
