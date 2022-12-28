import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'dart:convert';
import 'package:http/http.dart';
import 'card.dart';
import 'game.dart';
import 'joinRoom.dart';

class GameLobby extends StatefulWidget {
  const GameLobby({super.key});

  @override
  State<GameLobby> createState() => _GameLobbyState();
}

var data;
Future<List> getData(String id) async {
  // カテゴリー
  String apiURL = 'http://dev.kun.pink/kogera/roomtest.json';
  try {
    var result = await get(Uri.parse(apiURL));
    if (result.statusCode == 200) {
      data = json.decode(result.body);
      int length = data.length;
      for (int i = 0; i < length; i++) {
        print(data[i]["roomName"]);
      }
    }
    return data;
  } catch (e) {
    print('error');
    print(e);
    List aa = [];
    return aa;
  }
}

class _GameLobbyState extends State<GameLobby> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('部屋選択'),
      ),
      body: SafeArea(
          child: Center(
        child: Column(
          children: [
            Text('test'),
            ElevatedButton(
                onPressed: () {
                  setState(() {});
                },
                child: Text('更新')),
            FutureBuilder(
              future: getData('a'),
              builder: (BuildContext context, AsyncSnapshot<List> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                }
                if (snapshot.hasData) {
                  return Expanded(
                    child: ListView.builder(
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        return RoomListCard(
                          roomName: snapshot.data![index]['roomName'],
                          roomId: snapshot.data![index]['roomId'].toString(),
                        );
                      },
                    ),
                  );
                } else {
                  return Text("エラーが発生しました。", style: TextStyle(fontSize: 30));
                }
              },
            ),
          ],
        ),
      )),
    );
  }

  Card RoomListCard({
    required String roomName,
    required String roomId,
    // required String created,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 120.0),
          ///////
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: Container(
                  child: Row(
                    children: [
                      // 商品画像画像
                      Container(
                        width: 55,
                        height: 55,
                        // child: ,
                      ),
                      const SizedBox(
                        width: 10.0,
                      ),
                      // 商品名バーコード
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.only(right: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                roomName,
                                style: const TextStyle(
                                  fontSize: 25.0,
                                  fontWeight: FontWeight.bold,
                                ),
                                // softWrap: false,
                              ),
                              Text(
                                roomId,
                                softWrap: true,
                                style: TextStyle(fontSize: 18),
                              ),
                              Text('Not参加人数 4/6'),
                              Text('Not作成時間 10秒前'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 個数 変更ボタン
              Align(
                alignment: Alignment.bottomCenter, //右寄せの指定
                child: Container(
                  alignment: Alignment.centerRight,
                  child: Column(
                    // crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        child: Column(
                          // mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            ElevatedButton(
                              child: Text('参加'),
                              style: ElevatedButton.styleFrom(
                                primary: Colors.blue,
                                onPrimary: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: () async {
                                // print(imgURL);
                                await Navigator.of(context)
                                    .pushNamed(
                                  "/gamepage",
                                  arguments: joinRoomModel(
                                    name: 'thisisname',
                                    roomid: roomId,
                                  ),
                                )
                                    .then((value) {
                                  // 再描画
                                  setState(() {});
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
