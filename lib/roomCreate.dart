import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';

class RoomCreate extends StatefulWidget {
  const RoomCreate({super.key});

  @override
  State<RoomCreate> createState() => _RoomCreateState();
}

int _choiceIndex = 1;
int _vanish = 1;

class _RoomCreateState extends State<RoomCreate> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('ルーム作成')),
      body: Center(
          child: Column(
        children: [
          Text('枚数選択'),
          Text('公開？非公開？'),
          Text('人数選択'),
          Text('あいことば'),
          Wrap(
            spacing: 10,
            children: [
              ChoiceChip(
                label: Text("choice 0"),
                selected: _choiceIndex == 0,
                backgroundColor: Colors.grey[600],
                selectedColor: Colors.white,
                onSelected: (_) {
                  setState(() {
                    _choiceIndex = 0;
                  });
                },
              ),
              ChoiceChip(
                label: Text("choice 1"),
                selected: _choiceIndex == 1,
                backgroundColor: Colors.grey[600],
                selectedColor: Colors.white,
                onSelected: (_) {
                  setState(() {
                    _choiceIndex = 1;
                  });
                },
              ),
              ChoiceChip(
                label: Text("choice 2"),
                selected: _choiceIndex == 2,
                backgroundColor: Colors.grey[600],
                selectedColor: Colors.white,
                onSelected: (_) {
                  setState(() {
                    _choiceIndex = 2;
                  });
                },
              ),
              ChoiceChip(
                label: Text("choice 3"),
                selected: _choiceIndex == 3,
                backgroundColor: Colors.grey[600],
                selectedColor: Colors.white,
                onSelected: (_) {
                  setState(() {
                    _choiceIndex = 3;
                  });
                },
              ),
            ],
          ),
          Wrap(
            spacing: 10,
            children: [
              ChoiceChip(
                label: Text("非公開"),
                selected: _vanish == 0,
                backgroundColor: Colors.grey[600],
                selectedColor: Colors.white,
                onSelected: (_) {
                  setState(() {
                    _vanish = 0;
                  });
                },
              ),
              ChoiceChip(
                label: Text("公開"),
                selected: _vanish == 1,
                backgroundColor: Colors.grey[600],
                selectedColor: Colors.white,
                onSelected: (_) {
                  setState(() {
                    _vanish = 1;
                  });
                },
              ),
            ],
          ),
          ElevatedButton(onPressed: () {}, child: Text('ゲーム開始')),
        ],
      )),
    );
  }
}
