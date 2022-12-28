import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:kogera_phone/main.dart';
import 'package:socket_io_client/socket_io_client.dart';
import 'joinRoom.dart';
import 'dialog.dart';

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

String name = '';
String roomId = '';

class _GamePageState extends State<GamePage> {
  var myCard = '';
  late final Socket _socket;

  @override
  void initState() {
    _socket = io(
        "http://dev.kun.pink:3000",
        OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect()
            .build());
    _socket.onConnect((data) {
      print('Connection established');

      // token受け取り
      _socket.on("token", (data) {
        // emitData = EmitData.fromJson(data);
      });
      // 個人配信
      _socket.on("client", (data) {
        print('clientOnly 受信 ID : ' + data['id']);
        switch (data['id']) {
          case 'card':
            myCard = data['value'];
            setState(() {});
            break;
          default:
        }
      });

      // グループ配信
      _socket.on("client", (data) {
        print('client 受信 ID : ' + data['id']);
        switch (data['id']) {
          case 'card':
            myCard = data['value'];
            setState(() {});
            break;
          default:
        }
      });
      _socket.on("group", (data) {
        print('group 受信 ID : ' + data['id']);
        switch (data['id']) {
          case 'noCard':
            myCard = 'やり直し';
            setState(() {});
            break;
          default:
        }
      });

      // JoinLog 受け取り
      _socket.on("joinLog", (data) {
        print('JoinLog' + data['value']);
      });
    });
    _socket.connect();
    _socket.onDisconnect((_) => print('Connection Disconnection'));
    _socket.onConnectError((err) => print(err));
    _socket.onError((err) => print(err));

    // Futureの中ではcontextにアクセスできるらしい。
    Future.delayed(Duration.zero, () {
      setState(() {
        joinRoomModel args =
            ModalRoute.of(context)!.settings.arguments as joinRoomModel;
        name = args.name;
        roomId = args.roomid;
        _JoinGroup(roomId);
      });
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // print(roomId);

    return Scaffold(
      appBar: AppBar(title: Text('Game')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('GameLobby'),
            Container(
              alignment: Alignment.center,
              // width: 200,
              height: 200,
              child: Text(
                myCard,
                style: TextStyle(fontSize: 150),
              ),
            ),
            ElevatedButton(
              child: Text('次へ'),
              onPressed: () {
                _sendMessage();
              },
            ),
            ElevatedButton(
              child: Text(
                'こげら！！！',
                style: TextStyle(fontSize: 30),
              ),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) {
                    return AlertDialog(
                      title: Text("本当にこげらしますか"),
                      actions: <Widget>[
                        ElevatedButton(
                            child: Text("はい"),
                            onPressed: () {
                              Navigator.pop(context);
                            }),
                        ElevatedButton(
                            child: Text("いいえ"),
                            onPressed: () {
                              Navigator.pop(context);
                            }),
                      ],
                    );
                  },
                );
              },
            ),
            ElevatedButton(
              child: Text('Join'),
              onPressed: () {
                _JoinGroup('room1');
              },
            )
          ],
        ),
      ),
    );
  }

  void _sendMessage() {
    print(roomId + 'goStart');
    _socket.emit("test_post", {"roomId": 'room1'});
  }

  void _JoinGroup(String roomId) {
    print('次のグループに参加したよ' + roomId);
    _socket.emit("roomJoin", {"value": roomId});
  }
}
