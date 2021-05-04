

import 'package:cwms_mobile/outbound/models/order.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class OrderListItem extends StatefulWidget {
  OrderListItem({this.index, this.order,
       this.highPriorityFlag: false,
       this.sharedFlag: false,
       this.displayOnlyFlag: false,
       this.highlighted: false,
       @required this.onPriorityChanged,
       @required this.onSharedFlagChanged,
       @required this.onRemove,
       @required this.onToggleHightlighted}
       ) : super(key: ValueKey(order.number));

  final ValueChanged<Order> onPriorityChanged;
  final ValueChanged<Order> onSharedFlagChanged;
  final ValueChanged<int> onRemove;
  final ValueChanged<bool> onToggleHightlighted;

  final int index;
  final Order order;
  final bool highPriorityFlag;
  final bool sharedFlag;
  final bool displayOnlyFlag;
  bool highlighted;



  @override
  _OrderListItemState createState() => _OrderListItemState();


}

class _OrderListItemState extends State<OrderListItem> {

  void _togglePriority() {
    if (!widget.displayOnlyFlag) {

      widget.onPriorityChanged(widget.order);
    }
  }

  void _toggleSharedFlag() {
    if (!widget.displayOnlyFlag) {
      widget.onSharedFlagChanged(widget.order);
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
      padding: const EdgeInsets.only(top: 12.0),
      child: Material(
        color: widget.highlighted ? Colors.lightGreen : Colors.white,
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
                  title: Text(
                    widget.order.number,
                    textScaleFactor: .9,
                    style: TextStyle(
                      height: 1.15,
                      color: Colors.blueGrey[700],
                      fontSize: 17,
                    ),

                  ),
                  subtitle: Text(
                    widget.order.shipToContactorFirstname + " , "
                        + widget.order.shipToContactorLastname,
                    style: TextStyle(
                      color: Colors.blueGrey[700],
                      fontSize: 12,
                    ),
                  ),
                  // trailing: Text(widget.repo.language ?? ""),
                ),
                // 构建项目标题和简介
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.only(top: 1, bottom: 1),
                        child:
                        Text(
                          widget.order.totalOpenPickQuantity.toString(),
                          maxLines: 3,
                          style: TextStyle(
                            height: 1.15,
                            color: Colors.blueGrey[700],
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
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
        color: Colors.grey,
        size: 15,
      ),
      child: DefaultTextStyle(
        style: TextStyle(color: Colors.grey, fontSize: 12),
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
                          Text("High priority"),

                        ],
                      ),
                  ),

                  InkWell(
                    onTap: () => _toggleSharedFlag(),
                    child: Column(
                      children: [
                        Icon(widget.sharedFlag ?
                            Icons.share : Icons.share_outlined),
                        Text(" Share"),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: () => _removeOrderFromlist(),
                    child:
                      Column(
                        children: [
                          Icon(Icons.delete), //我们的自定义图标
                          Text("Remove"),
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
