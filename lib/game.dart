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

var myCard = '';

String name = '';
String roomId = '';
int roomPlayers = 0;
double goukei = -100;
bool isYouKogera = false;
bool error = false;

class _GamePageState extends State<GamePage> {
  late final Socket _socket;

  @override
  void initState() {
    super.initState();

    _connectSocket() {
      _socket.onConnect((data) {
        error = false;
      });
      _socket.onConnectError((data) {
        print('Connect Error: $data');
        socketerror();
      });
      _socket.onDisconnect((data) => print('Socket.IO server disconnected'));

      // _joinGroup(roomId);

      /// 受け取り処理　///

      // JoinLog 受け取り
      _socket.on("joinLog", (data) {
        print('JoinLog' + data['value']);
      });

      // groupSetting 設定情報取得
      _socket.on("groupSetting", (data) {
        roomPlayers = data['roomPlayers'];
        setState(() {});
        // print(data['roomPlayers']);
        // data['life'];
        // setState(() {});
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
            noCardDialog();
            break;
          default:
        }
      });
      // 合計値取得
      _socket.on("groupGoukei", (data) {
        goukei = data['value'].toDouble();
      });
      // kogeraWait
      _socket.on("kogeraWait", (data) {
        if (isYouKogera == true) {
          return;
        }
        kogeraWait();
      });
    }

    _socket = io(
      "http://dev.kun.pink:3000",
      OptionBuilder()
          .setTransports(['websocket'])
          .enableForceNew()
          .disableAutoConnect()
          .build(),
    );
    _connectSocket();
    _socket.connect();
    Future.delayed(Duration.zero, () {
      if (!mounted) {
        print('thismount');
        return;
      }
      joinRoomModel args =
          ModalRoute.of(context)!.settings.arguments as joinRoomModel;
      name = args.name;
      roomId = args.roomid;
      _joinGroup(roomId);
    });
  }

  @override
  void dispose() {
    // _socket.close();
    _socket.disconnect();
    _socket.close();
    super.dispose();
    print('clear');
  }

  @override
  Widget build(BuildContext context) {
    // print(roomId);

    return Scaffold(
      appBar: AppBar(title: Text('Game')),
      body: Stack(
        children: [
          Column(
            // mainAxisSize: MainAxisSize.min,
            children: [
              Text('(ユーザ)さん'),
              Text(
                '現在の参加者 ' + roomPlayers.toString() + '名',
                style: TextStyle(fontSize: 15),
              ),
              ElevatedButton(
                child: Text('ゲームを開始する。'),
                onPressed: () {},
              ),

              /// この↓ゲーム開始するまで非表示にする。
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
                  _gameStartPost();
                },
              ),
              ElevatedButton(
                child: Text('合計'),
                onPressed: () {
                  print(goukei);
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
                                isYouKogera = true;
                                // Navigator.push(
                                //     context,
                                //     MaterialPageRoute(
                                //         builder: (context) => KogeraPage()));
                                kogeraPost();
                                // _gameStartPost();
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
              Container(
                child: Column(children: [
                  Text('ライフ'),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.favorite),
                    Icon(Icons.favorite),
                    Icon(Icons.favorite),
                    Icon(Icons.favorite),
                  ]),
                ]),
              )
            ],
          ),
        ],
      ),
    );
  }

  void _joinGroup(String roomId) {
    print('次のグループに参加したよ' + roomId);
    _socket.emit("roomJoin", {"value": roomId});
  }

  void _gameStartPost() async {
    setState(() {
      myCard = '開始';
    });
    await Future.delayed(Duration(seconds: 3));
    _socket.emit("gameStartPost", {"roomId": 'room1'});
  }

  void _sendKogera() {
    _socket.emit("test_post", {"roomId": 'room1'});
  }

  void _sendKogeraWait() {
    _socket.emit("kogeraWait", {"roomId": 'room1'});
  }

  void socketerror() {
    if (error != true) {
      error = true;
      showDialog(
        context: context,
        builder: (_) {
          return AlertDialog(
            title: Text("エラー"),
            content: Text("サーバーに接続できません。再続行しています。\n Wi-Fi モバイル通信を確認してください。"),
            actions: <Widget>[
              ElevatedButton(
                  child: Text("戻る"),
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                    error = false;
                  }),
            ],
          );
        },
      );
    }
  }

  // カードがなくなった。
  void noCardDialog() {
    setState(() {
      myCard = 'カードが無いためリセットします';
    });
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text("カードが足りなくなりました。 \n カードをリセットします。 "),
          actions: <Widget>[
            ElevatedButton(
                child: Text("はい"),
                onPressed: () {
                  Navigator.pop(context);
                }),
          ],
        );
      },
    );
  }

  void kogeraPost() {
    _sendKogeraWait();
    // 画面以降
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => KogeraPage()));
  }

  void kogeraWait() {
    // 画面以降
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => KogeraWait()));
  }
}

class KogeraPage extends StatefulWidget {
  const KogeraPage({super.key});

  @override
  State<KogeraPage> createState() => _KogeraPageState();
}

class _KogeraPageState extends State<KogeraPage> {
  final _enterSayNum = TextEditingController();
  bool isEnterNum = false;
  bool win = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Stack(children: [
        Center(
            child: Column(
          children: [
            if (!isEnterNum)
              inputNumber(title: 'aaa')
            else if (win = true)
              Column(
                children: [Text('勝ち')],
              )
            else
              Column(
                children: [Text('負け')],
              )
          ],
        ))
      ]),
    );
  }

  Widget inputNumber({
    required String title,
    // required String description,
    // required IconData icon,
    // required Key key,
    // required Function()? onPressed,
  }) {
    return Center(
      child: Column(children: [
        Text('最後に言った数字を入力してください'),
        TextField(
          controller: _enterSayNum,
        ),
        ElevatedButton(
            onPressed: () {
              isEnterNum = true;
              if (goukei > double.parse(_enterSayNum.text)) {
                print('負け');
              } else {
                // 合計が 入力した値よりも小さい
                print('勝ち');
                win = true;
              }
              setState(() {});
            },
            child: Text('続行'))
      ]),
    );
  }
}

class KogeraWait extends StatefulWidget {
  const KogeraWait({super.key});

  @override
  State<KogeraWait> createState() => _KogeraWaitState();
}

class _KogeraWaitState extends State<KogeraWait> {
  bool isEnterNum = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Column(children: [
            Text(
              '待機中',
              style: TextStyle(fontSize: 30),
            ),
            Text(
              'ユーザID : 1',
              style: TextStyle(fontSize: 30),
            ),
          ]),
        ));
  }
}

class Result extends StatefulWidget {
  const Result({super.key});

  @override
  State<Result> createState() => _ResultState();
}

class _ResultState extends State<Result> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Result'),
      ),
      body: Center(
        child: Column(children: [Text('Result')]),
      ),
    );
  }
}
