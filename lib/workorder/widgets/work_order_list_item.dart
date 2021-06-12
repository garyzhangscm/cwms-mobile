

import 'package:cwms_mobile/i18n/localization_intl.dart';
import 'package:cwms_mobile/outbound/models/order.dart';
import 'package:cwms_mobile/workorder/models/work_order.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class WorkOrderListItem extends StatefulWidget {
  WorkOrderListItem({this.index, this.workOrder,
       this.highPriorityFlag: false,
       this.sharedFlag: false,
       this.displayOnlyFlag: false,
       this.highlighted: false,
       @required this.onPriorityChanged,
       @required this.onSharedFlagChanged,
       @required this.onRemove,
       @required this.onToggleHightlighted}
       ) : super(key: ValueKey(workOrder.number));

  final ValueChanged<WorkOrder> onPriorityChanged;
  final ValueChanged<WorkOrder> onSharedFlagChanged;
  final ValueChanged<int> onRemove;
  final ValueChanged<bool> onToggleHightlighted;

  final int index;
  final WorkOrder workOrder;
  final bool highPriorityFlag;
  final bool sharedFlag;
  final bool displayOnlyFlag;
  bool highlighted;



  @override
  _WorkOrderListItemState createState() => _WorkOrderListItemState();


}

class _WorkOrderListItemState extends State<WorkOrderListItem> {

  void _togglePriority() {
    if (!widget.displayOnlyFlag) {

      widget.onPriorityChanged(widget.workOrder);
    }
  }

  void _toggleSharedFlag() {
    if (!widget.displayOnlyFlag) {
      widget.onSharedFlagChanged(widget.workOrder);
    }
  }
  void _removeOrderFromlist() {
    if (!widget.displayOnlyFlag) {
      widget.onRemove(widget.index);
    }
  }
  void _onToggleHightlighted() {
    if (widget.onToggleHightlighted != null) {

      setState(() {
        widget.highlighted = !widget.highlighted;
      });
      widget.onToggleHightlighted(widget.highlighted);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 2.0),
      child: Material(
        // If the user highlight the widget, display green
        // otherwise if there's no open pick, display grey
        color: widget.highlighted ? Colors.lightGreen:
              widget.workOrder.totalOpenPickQuantity == 0 ?
              Colors.grey : Colors.white,
        shape: BorderDirectional(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: .5,
          ),
        ),
        child: InkWell(
          onTap: _onToggleHightlighted,
          child: Padding(
            padding: const EdgeInsets.only(top: 0.0, bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                ListTile(
                  dense: true,
                  // tileColor: widget.highlighted ? Colors.lightGreen:
                  //     widget.order.totalOpenPickQuantity == 0 ?
                  //                Colors.grey : Colors.white,
                  title: Text(
                    widget.workOrder.number,
                    textScaleFactor: .9,
                    style: TextStyle(
                      height: 1.15,
                      color: Colors.blueGrey[700],
                      fontSize: 17,
                    ),

                  ),
                  subtitle: Text(widget.workOrder.totalOpenPickQuantity.toString()),
                ),
                // 构建项目标题和简介

                // 构建卡片底部信息
                widget.displayOnlyFlag ? Container() : _buildBottom(),
              ],
            ),
          ),
        ),
      ),
    );
  }


  // 构建卡片底部信息
  Widget _buildBottom() {
    const paddingWidth = 10;
    return IconTheme(
      data: IconThemeData(
        color: Colors.black ,
        size: 15,
      ),
      child: DefaultTextStyle(
        style: TextStyle(color: Colors.black, fontSize: 12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Builder(builder: (context) {

            return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                mainAxisSize: MainAxisSize.max,
                //交叉轴的布局方式，对于column来说就是水平方向的布局方式
                crossAxisAlignment: CrossAxisAlignment.center,
                //就是字child的垂直布局方向，向上还是向下
                verticalDirection: VerticalDirection.down,
                children: <Widget>[
                  InkWell(
                    onTap: () => _togglePriority(),
                    child: Column(
                        children: [
                          Icon(widget.highPriorityFlag ?
                            Icons.star : Icons.star_border),
                          Text(CWMSLocalizations.of(context).highPriority),

                        ],
                      ),
                  ),

                  InkWell(
                    onTap: () => _toggleSharedFlag(),
                    child: Column(
                      children: [
                        Icon(widget.sharedFlag ?
                            Icons.share : Icons.share_outlined),
                        Text(CWMSLocalizations.of(context).share),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: () => _removeOrderFromlist(),
                    child:
                      Column(
                        children: [
                          Icon(Icons.delete), //我们的自定义图标
                          Text(CWMSLocalizations.of(context).remove),
                        ],
                      )
                 ),
                ]
            );
          }),
        ),
      ),
    );
  }




}
