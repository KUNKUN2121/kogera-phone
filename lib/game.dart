import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:kogera_phone/main.dart';
import 'package:kogera_phone/setting.dart';
import 'package:socket_io_client/socket_io_client.dart';
import 'joinRoom.dart';
import 'dialog.dart';

String name = '';
String roomId = '';
var myCard = '';

int roomPlayers = 0;
double goukei = -100;
bool isYouKogera = false;
bool error = false;
String myid = '';
String kogeraSayUserName = '';
var userList;
var kogeraResultData;
bool firstGame = true;

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

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
      _socket.on("youId", (data) {
        myid = data['id'];
        print(myid);
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
      _socket.on("groupAll", (data) {
        goukei = data['goukei'].toDouble();
        userList = data['userList'];
        firstGame = false;
        // print('client 受信 ID : ' + data['id']);
        print(data['goukei']);
        print(userList);
        roomPlayers = userList.length;
        for (int i = 0; i < userList.length; i++) {
          if (userList[i][0] == myid) {
            myCard = data['userList'][i][3];
          }
        }
        setState(() {});
      });
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

      // kogeraWait
      _socket.on("kogeraPost", (data) async {
        if (myid == data['sayKogeraUser']) {
          return;
        }
        for (int i = 0; i < userList.length; i++) {
          print(i);
          print(userList[i][0]);

          if (userList[i][0] == data['sayKogeraUser']) {
            kogeraSayUserName = userList[i][1];
          }
        }
        print(data['sayKogeraUser']);
        kogeraWait();
      });

      // 結果！！！！！！！
      _socket.on("kogeraResultPost", (data) {
        kogeraResultData = data;
        print(data['kogeraSayUser']);
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => KogeraResultPage(socket: _socket)));
      });
      _socket.on("gameEnd", (data) {
        resetGame();
        Navigator.popUntil(context, ModalRoute.withName('/GamePage'));
      });
    }

    _socket = io(
      socketURL,
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
      appBar: AppBar(
        title: Text('Game'),
        leading: IconButton(
          onPressed: () {
            resetGame();
            Navigator.pushNamedAndRemoveUntil(
                context, "/MainPage", (r) => false);
          },
          icon: Icon(Icons.arrow_back_ios),
        ),
      ),
      body: Stack(
        children: [
          Column(
            // mainAxisSize: MainAxisSize.min,
            children: [
              Text(name),
              Text(
                '現在の参加者 ' + roomPlayers.toString() + '名',
                style: TextStyle(fontSize: 15),
              ),
              GestureDetector(
                onTap: () {
                  _gameStartPost();
                },
                child: Text("DEBUG"),
              ),

              if (firstGame)
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
              // Text(goukei.toString()),
              // ElevatedButton(
              //   child: Text('次へ'),
              //   onPressed: () {
              //     _gameStartPost();
              //   },
              // ),
              // ElevatedButton(
              //   child: Text('合計'),
              //   onPressed: () {},
              // ),
              SizedBox(
                height: 100,
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
    _socket.emit("roomJoin", {"roomId": roomId, "usrName": name});
  }

  void _gameStartPost() async {
    setState(() {
      myCard = '開始';
    });
    await Future.delayed(Duration(seconds: 1));
    _socket.emit("gamestart", {"roomId": 'room1'});
  }

  void _sendKogeraWait() {
    _socket.emit("kogeraPost", {"roomId": 'room1'});
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
        context,
        MaterialPageRoute(
            builder: (context) => KogeraPage(
                  socket: _socket,
                ))).then((value) {
      setState(() {});
    });
  }

  void kogeraWait() {
    // 画面以降
    Navigator.push(
            context, MaterialPageRoute(builder: (context) => KogeraWait()))
        .then((value) {
      setState(() {});
    });
  }

// 結果処理！！！！
}

class KogeraPage extends StatefulWidget {
  final Socket socket;
  const KogeraPage({super.key, required this.socket});

  @override
  State<KogeraPage> createState() => _KogeraPageState(socket: socket);
}

class _KogeraPageState extends State<KogeraPage> {
  final Socket socket;
  _KogeraPageState({required this.socket});
  final _enterSayNum = TextEditingController();
  bool isEnterNum = false;
  bool win = false;
  var kogeraPreSayUserId = userList[0][0];
  List<DropdownMenuItem<Object>> testListDa = userList
      .map(
        (str) => DropdownMenuItem(
          child: Text((str[1])),
          value: str[0],
        ),
      )
      // castでデータ型をあわせる。
      .cast<DropdownMenuItem<Object>>()
      .toList();

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
        DropdownButton(
            hint: Text("選択してください"),
            items: testListDa,
            value: kogeraPreSayUserId,
            onChanged: (value) {
              print(value);
              kogeraPreSayUserId = value;
              setState(() {});
            }),

        /// ビルダー
        ///    作ったウゾ
        ElevatedButton(
            onPressed: () async {
              if (_enterSayNum.text == '') {
                // 未入力の場合returnする。
                return;
              }
              // Win Loseはクライントが判断する。
              if (goukei > double.parse(_enterSayNum.text)) {
                // print('負け');
                win = false;
              } else {
                // 合計が 入力した値よりも小さい
                // print('勝ち');
                win = true;
              }

              socket.emit("kogeraResultPost", {
                "roomId": 'room1',
                "goukei": goukei,
                // こげらしたユーザID
                "kogeraSayUser": myid,
                // こげら言った人の勝敗
                "win": true,
                // こげらの前の人のユーザID
                "kogeraPreSayUserId": kogeraPreSayUserId,
                "kogeraPreSayNumber": _enterSayNum.text,
              });
              // 画面以降
              // Navigator.push(context,
              //     MaterialPageRoute(builder: (context) => KogeraResultPage()));

              isEnterNum = true;

              // setState(() {});
            },
            child: Text('続行'))
      ]),
    );
  }
}

// 待機ページ
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
            Text(kogeraSayUserName + ' さんがこげらしました！'),
            Text(
              'ユーザID : 1',
              style: TextStyle(fontSize: 30),
            ),
          ]),
        ));
  }
}

class KogeraResultPage extends StatelessWidget {
  final Socket socket;
  KogeraResultPage({super.key, required this.socket});
  Color backGroundColor = Colors.white;
  @override
  Widget build(BuildContext context) {
    bool? win = null;
    if (myid == kogeraResultData['winUserId']) {
      win = true;
      print('a');
      backGroundColor = Color.fromRGBO(255, 250, 200, 1);
    } else if (myid == kogeraResultData['loseUserId']) {
      win = false;
      backGroundColor = Color.fromRGBO(255, 148, 136, 1);
      print('a');
    }
    return Scaffold(
      appBar: AppBar(title: Text('結果')),
      backgroundColor: backGroundColor,
      body: SafeArea(
          child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (win == null)
              Text('aaa')
            else if (win)
              Text(
                'WIN',
                style: TextStyle(fontSize: 100),
              )
            else
              Text(
                'LOSE',
                style: TextStyle(fontSize: 100),
              ),
            Container(
              child: Column(children: [
                Text(serachUserName(kogeraResultData['winUserId']) + ' WIN',
                    style: TextStyle(fontSize: 20)),
                Text(serachUserName(kogeraResultData['loseUserId']) + ' LOSE',
                    style: TextStyle(fontSize: 20)),
              ]),
            ),
            SizedBox(
              height: 50,
            ),
            Text('合計は ' + goukei.toString() + ' でした。',
                style: TextStyle(fontSize: 20)),
            Text(
              serachUserName(kogeraResultData['loseUserId']) +
                  'さんが ' +
                  kogeraResultData['kogeraPreSayNumber'] +
                  'と言った',
              style: TextStyle(fontSize: 20),
            ),
            ElevatedButton(
              onPressed: () {
                socket.emit("gameEnd", {"roomId": roomId});
              },
              child: Text('戻る'),
            )
          ],
        ),
      )),
    );
  }
}

serachUserName(userId) {
  for (int i = 0; i < userList.length; i++) {
    print(i);
    print(userList[i][0]);

    if (userList[i][0] == userId) {
      return userList[i][1];
    }
  }
  return 'error';
}

void resetGame() {
  firstGame = false;
  myCard = '';
  roomPlayers = 0;
  goukei = -100;
  isYouKogera = false;
  error = false;
  kogeraSayUserName = '';
}


// class Result extends StatefulWidget {
//   const Result({super.key});

//   @override
//   State<Result> createState() => _ResultState();
// }

// class _ResultState extends State<Result> {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Result'),
//       ),
//       body: Center(
//         child: Column(children: [Text('Result')]),
//       ),
//     );
//   }
// }

