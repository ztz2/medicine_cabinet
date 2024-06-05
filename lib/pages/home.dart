import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:excel/excel.dart';
import 'package:pinyin/pinyin.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:medicine_cabinet/util/color_util.dart';
import 'package:medicine_cabinet/util/hexto_color.dart';
import 'package:medicine_cabinet/util/screen_helper.dart';
import 'package:medicine_cabinet/widgets/box.dart';
import 'package:medicine_cabinet/widgets/gradient_icon.dart';
import 'package:medicine_cabinet/widgets/input.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MedicineArea {
  String name = '';
  List<Medicine> list = [];
  MedicineArea(this.name);
  MedicineArea.formJSON(Map<String, dynamic> json) {
    name = json['name'];
    json['list'].forEach((item) {
      list.add(Medicine.formJSON(item));
    });
  }
  toJSON() {
    return {
      '"name"': '"${name}"',
      '"list"': list.map((item) => item.toJSON()).toList()
    };
  }
}

class Medicine {
  String name = '';
  String location = '';
  Medicine(this.name, this.location);
  Medicine.formJSON(Map<String, dynamic> json) {
    name = json['name'];
    location = json['location'];
  }
  toJSON() {
    return {
      '"name"': '"${name}"',
      '"location"': '"${location}"',
    };
  }
}

const MEDICINE_PREFERENCE_KEY = 'MEDICINE_AREA_DATA';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Timer? _timer;
  List<MedicineArea> _medicineAreaList = [];

  Future<void> _pickFile() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    FilePickerResult? pickFileResult = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
    );
    List<MedicineArea> medicineAreaList = [];
    if (pickFileResult != null) {
      File file = File(pickFileResult.files.single.path!);
      var bytes = file.readAsBytesSync();
      var excel = Excel.decodeBytes(bytes);
      var tables = excel.tables;

      for (var tableName in tables.keys) {
        var table = tables[tableName];
        var rows = table?.rows;
        var medicineArea = MedicineArea(tableName);
        if (rows == null) {
          continue;
        }
        for (var row in rows) {
          dynamic medicineNameCell = row[0];
          dynamic medicineLocationCell = row[1];
          if (medicineNameCell == null || medicineLocationCell == null) {
            continue;
          }
          dynamic medicineName = medicineNameCell?.value.toString();
          dynamic medicineLocation = medicineLocationCell?.value.toString();
          var medicine = Medicine(medicineName, medicineLocation);
          medicineArea.list.add(medicine);
        }

        medicineAreaList.add(medicineArea);
      }
    }

    // 保存数据到本地
    await prefs.setString(MEDICINE_PREFERENCE_KEY, medicineAreaList.map((item) => item.toJSON()).toList().toString());
    setState(() {
      _medicineAreaList = medicineAreaList;
    });
  }

  _initData() async{
    List<MedicineArea> medicineAreaList = [];
    try{
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      var str = prefs.getString(MEDICINE_PREFERENCE_KEY);
      if (str != null) {
        dynamic list = jsonDecode(str);
        list?.forEach((item){
          medicineAreaList.add(MedicineArea.formJSON(item));
        });
      }
    }catch(e) {}
    setState(() {
      _medicineAreaList = medicineAreaList;
    });
  }

  _handleSearch(text) {
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 200), () {
      String originalText = "安逗和黑子逗和";
      String matchText = "逗和";

      // 测试匹配
      List<int> matchIndices = matchString(originalText, matchText);
      print(matchIndices); // 输出：[1, 5]
    });
  }

  List<int> matchString(String originalText, String matchText) {
    List<int> matchIndices = [];

    // 遍历原始文本中的每个字符
    for (int i = 0; i <= originalText.length - matchText.length; i++) {
      bool isMatch = true;

      // 检查原始文本中的当前位置开始是否与匹配文本匹配
      for (int j = 0; j < matchText.length; j++) {
        if (originalText[i + j] != matchText[j]) {
          isMatch = false;
          break;
        }
      }

      // 如果匹配，则记录当前位置
      if (isMatch) {
        matchIndices.add(i);
      }
    }

    return matchIndices;
  }
  @override
  void initState() {
    super.initState();
    _initData();
  }
  @override
  Widget build(BuildContext context) {
    ScreenHelper.init(context);

    EdgeInsets padding = MediaQuery.of(context).padding;
    double top = padding.top;
    double bottom = padding.bottom;
    var hasData = _medicineAreaList.isNotEmpty;
    // var hasData = false;

    return Stack(
      children: [
        // 整体背景
        Container(color: hexToColor('#f4f4f4')),
        // 顶部渐变背景
        Container(
          height: (200 + top).px,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                ColorUtil.primaryColor,
                hexToColor('#f4f4f4', opacity: 0.3)
              ],
              stops: const [0.1, 1.0],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        // 内容主体
        Container(
          padding: EdgeInsets.only(top: top),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 顶部区域
              Column(
                children: [
                  // 标题
                  Stack(
                    children: [
                      Align(
                        alignment: Alignment.center,
                        child: Center(
                          child: Padding(
                            padding: EdgeInsets.all(10.px),
                            child: GestureDetector(
                              onTap: () {
                                _initData();
                              },
                              child: Text("中药位置快速查询", style: TextStyle(color: Colors.white, fontSize: 18.px, decoration: TextDecoration.none, fontWeight: FontWeight.w400)),
                            ),
                          )
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          margin: EdgeInsets.fromLTRB(0, 6.px, 11.px, 0),
                          child: GestureDetector(
                            onTap: () {
                              _pickFile();
                            },
                            child: Box(
                              width: 32.px,
                              height: 32.px,
                              backgroundColor: hexToColor("#ffeddf"),
                              borderRadius: BorderRadius.circular(20),
                              child: GradientIcon(
                                Icons.file_upload,
                                size: 18.px,
                                gradient: LinearGradient(
                                  colors: [
                                    hexToColor("#ff8a06"),
                                    hexToColor("#fc5201"),
                                  ],
                                  stops: const [0.7, 1.0], // 蓝色占比70%，绿色占比30%
                                )
                              ),
                            ),
                          ),
                        )
                      )
                    ],
                  ),
                  hasData ?
                  // 搜索
                  Container(
                    width: double.infinity,
                    margin: EdgeInsets.only(top: 4.px),
                    child: Container(
                      padding: EdgeInsets.fromLTRB(13.px, 0.px, 13.px, 0.px),
                      child: PhysicalModel(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30.px),
                        clipBehavior: Clip.antiAlias,
                        child: Input(
                          hintText: "搜索",
                          height: 40.px,
                          padding: EdgeInsets.fromLTRB(18.px, 0, 20.px, 0),
                          onChanged: (text) {
                            _handleSearch(text);
                          },
                        ),
                      ),
                    )
                  )
                  : Container(),
                ],
              ),
              Expanded(
                flex: 1,
                child: Container(
                  margin: EdgeInsets.only(top: 18.px),
                  padding: EdgeInsets.fromLTRB(10.px, 0, 10.px, bottom),
                  child: hasData ? ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      Container(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Column(
                          children: _medicineAreaList.asMap().entries.map((medicineAreaEntry) {
                            var i = medicineAreaEntry.key;
                            var e = medicineAreaEntry.value;
                            return Container(
                              margin: EdgeInsets.only(bottom: i < _medicineAreaList.length - 1 ? 14.px : 0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    margin: EdgeInsets.fromLTRB(2.px, 0, 0, 4.px),
                                    child: Text(e.name, style: TextStyle(fontSize: 18, color: hexToColor("#111211"), decoration: TextDecoration.none)),
                                  ),
                                  Wrap(
                                    children: e.list.asMap().entries.map((entry) {
                                      var index = entry.key;
                                      var item = entry.value;
                                      var marginGap = index % 2 == 0 ? EdgeInsets.fromLTRB(0, 6.px, 5.px, 0) : EdgeInsets.fromLTRB(5.px, 6.px, 0, 0);
                                      return Container(
                                        margin: marginGap,
                                        child: PhysicalModel(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(10.px),
                                          clipBehavior: Clip.antiAlias,
                                          child: Container(
                                            width: 172.5.px,
                                            padding: EdgeInsets.fromLTRB(10.px, 10.px, 10.px, 10.px),
                                            child: Align(
                                              child: Column(
                                                children: [
                                                  Text(item.name, style: TextStyle(fontSize: 12, color: hexToColor("#111211"), decoration: TextDecoration.none, fontWeight: FontWeight.w400)),
                                                  Container(
                                                    margin: const EdgeInsets.only(top: 3),
                                                    child: Text(item.location, style: TextStyle(fontSize: 12, color: hexToColor("#111211"), decoration: TextDecoration.none, fontWeight: FontWeight.w400)),
                                                  )
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        )
                      )
                    ],
                  ) : Wrap(
                    children: [
                      Container(
                        margin: EdgeInsets.only(top: 40.px),
                        child: Center(
                          child: Text(
                            "请先导入数据",
                            style: TextStyle(
                              fontSize: 16.px,
                              fontWeight: FontWeight.w400,
                              color: hexToColor("#333333"),
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ),
                      )
                    ]
                  ),
                )
              )
            ],
          ),
        )
      ],
    );
  }
}
