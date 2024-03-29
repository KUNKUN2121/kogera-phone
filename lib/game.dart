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
        firstGame = true;
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
            firstGame = true;
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
                  onPressed: () {
                    _gameStartPost();
                  },
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
              if (!firstGame)
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
                                  if (roomPlayers <= 1) {
                                    return;
                                  }
                                  Navigator.pop(context);
                                  isYouKogera = true;

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
  bool? win = null;
  var kogeraPreSayUserId = userList[0][0];
  List<DropdownMenuItem<Object>> playerDDMenuList = userList
      .where((str) => str[0] != myid)
      .map((str) => DropdownMenuItem(
            child: Text((str[1])),
            value: str[0],
          ))
      // castでデータ型をあわせる。
      .cast<DropdownMenuItem<Object>>()
      .toList();

  @override
  Widget build(BuildContext context) {
    // 戻れなくするためにわっぷ
    return WillPopScope(
      onWillPop: _willPopCallback,
      child: Scaffold(
          appBar: AppBar(
            title: Text('数値入力'),
            // 戻るボタン非表示
            automaticallyImplyLeading: false,
          ),
          body: winOrLose()),
    );
  }

  Future<bool> _willPopCallback() async {
    return true;
  }

  Widget winOrLose() {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(
          "カードの合計 : " + goukei.toString(),
          style: TextStyle(fontSize: 30),
        ),
        Text("あなたのカード : " + myCard.toString(), style: TextStyle(fontSize: 30)),
        SizedBox(
          width: 200,
          height: 70,
          child: ElevatedButton(
            child: const Text('あなたの勝ち'),
            onPressed: () {
              win = true;
              setState(() {});
            },
          ),
        ),
        SizedBox(
          height: 10,
        ),
        SizedBox(
          width: 200,
          height: 70,
          child: ElevatedButton(
            child: const Text('あなたの負け'),
            onPressed: () {
              win = false;
              kogeraPreSayUserId = null;
              setState(() {});
            },
          ),
        ),
        if (win == true)
          Column(
            children: [
              Text('こげらする前に数字を言ったユーザを選択してください。'),
              DropdownButton(
                  hint: Text("選択してください"),
                  items: playerDDMenuList,
                  value: kogeraPreSayUserId,
                  onChanged: (value) {
                    print(value);
                    kogeraPreSayUserId = value;
                    setState(() {});
                  }),
            ],
          ),
        if (win != null)
          ElevatedButton(
            child: Text('続行'),
            onPressed: () async {
              socket.emit("kogeraResultPost", {
                "roomId": 'room1',
                "goukei": goukei,
                // こげらしたユーザID
                "kogeraSayUser": myid,
                // こげら言った人の勝敗
                "win": win,
                // こげらの前の人のユーザID
                "kogeraPreSayUserId": kogeraPreSayUserId,
              });

              isEnterNum = true;

              // setState(() {});
            },
          )
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
      print(kogeraResultData);
      backGroundColor = Color.fromRGBO(255, 250, 200, 1);
    } else if (myid == kogeraResultData['loseUserId']) {
      win = false;
      backGroundColor = Color.fromRGBO(255, 148, 136, 1);
      print('a');
    }
    return WillPopScope(
      onWillPop: _willPopCallback,
      child: Scaffold(
        appBar: AppBar(automaticallyImplyLeading: false, title: Text('結果')),
        backgroundColor: backGroundColor,
        body: SafeArea(
            child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (win == null)
                Text('あなたは関係ない')
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
                  if (kogeraResultData['win'] == true)
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
              if (kogeraResultData['win'] == true) winMessage(),
              if (kogeraResultData['win'] == false) loseMessage(),
              if (kogeraResultData['win'] == null) winMessage(),
              ElevatedButton(
                onPressed: () {
                  socket.emit("gameEnd", {"roomId": roomId});
                },
                child: Text('戻る'),
              )
            ],
          ),
        )),
      ),
    );
  }

  Widget winMessage() {
    return Text(
      serachUserName(kogeraResultData['winUserId']) +
          'さんが コゲラした。\n ' +
          serachUserName(kogeraResultData['loseUserId']) +
          'さんが言った数値は合計を超えていた',
      style: TextStyle(fontSize: 20),
    );
  }

  Widget loseMessage() {
    return Text(
      serachUserName(kogeraResultData['loseUserId']) +
          'さんが コゲラしたが、\nまだ数値は合計に達していなかった',
      style: TextStyle(fontSize: 20),
    );
  }

  Future<bool> _willPopCallback() async {
    return true;
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
  firstGame = true;
  myCard = '';
  roomPlayers = 0;
  goukei = -100;
  isYouKogera = false;
  error = false;
  kogeraSayUserName = '';
}
