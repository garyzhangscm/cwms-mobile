

import 'package:cwms_mobile/outbound/models/order.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/wave.dart';

class WaveListItem extends StatefulWidget {
  WaveListItem({this.index, this.wave,
       @required this.onRemove }
       ) : super(key: ValueKey(wave.number));

  final ValueChanged<int> onRemove;

  final int index;
  final Wave wave;



  @override
  _WaveListItemState createState() => _WaveListItemState();


}

class _WaveListItemState extends State<WaveListItem> {


  void _removeWaveFromlist() {
      widget.onRemove(widget.index);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 2.0),
      child: Material(
        shape: BorderDirectional(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: .5,
          ),
        ),
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
                  widget.wave.number,
                  textScaleFactor: .9,
                  style: TextStyle(
                    height: 1.15,
                    color: Colors.blueGrey[700],
                    fontSize: 17,
                  ),

                ),
                trailing: IconButton(
                  onPressed: () => _removeWaveFromlist(),
                  icon: Icon(Icons.delete),
                ),
                // subtitle: Text(widget.wave.totalOpenPickQuantity.toString()),
              ),
              // _buildBottom(),
            ],
          ),
        ),
      ),
    );
  }


  // 构建卡片底部信息
  Widget _buildBottom() {
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
                    onTap: () => _removeWaveFromlist(),
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
