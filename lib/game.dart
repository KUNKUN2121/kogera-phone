import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:kogera_phone/main.dart';
import 'package:socket_io_client/socket_io_client.dart';

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  var myCard = '';
  late final Socket _socket;
  @override
  void initState() {
    super.initState();
    _socket = io(
        "http://dev.kun.pink:3000",
        OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect()
            .build());
    _socket.onConnect((data) {
      print('Connection established');
      _socket.on("token", (data) {
        // emitData = EmitData.fromJson(data);
      });
      _socket.on("clientOnly", (data) {
        switch (data['id']) {
          case 'card':
            myCard = data['value'];
            setState(() {});
            break;
          default:
        }
      });
    });
    _socket.connect();
    // _socket.onConnect((_) {

    // });
    _socket.onDisconnect((_) => print('Connection Disconnection'));
    _socket.onConnectError((err) => print(err));
    _socket.onError((err) => print(err));
  }

  @override
  Widget build(BuildContext context) {
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
                onPressed: () {
                  _sendMessage();
                },
                child: Text('次へ')),
            ElevatedButton(
                onPressed: () {
                  _JoinGroup();
                },
                child: Text('Join'))
          ],
        ),
      ),
    );
  }

  void _sendMessage() {
    _socket.emit("test_post", {"roomId": 'room1'});
  }

  void _JoinGroup() {
    _socket.emit("roomJoin", {"value": 'room1'});
  }
}
