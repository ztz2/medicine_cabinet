import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:excel/excel.dart';
import 'package:jiffy/jiffy.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pinyin/pinyin.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:medicine_cabinet/util/color_util.dart';
import 'package:medicine_cabinet/util/hexto_color.dart';
import 'package:medicine_cabinet/util/screen_helper.dart';
import 'package:medicine_cabinet/widgets/box.dart';
import 'package:medicine_cabinet/widgets/gradient_icon.dart';
import 'package:medicine_cabinet/widgets/input.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:adaptive_action_sheet/adaptive_action_sheet.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';


extension SafeSubstring on String {
  String safeSubstring(int startIndex, [int? endIndex]) {
    if (startIndex < 0) startIndex = 0;
    if (endIndex == null || endIndex > this.length) {
      endIndex = this.length;
    }
    if (startIndex > endIndex) {
      return '';
    }
    return this.substring(startIndex, endIndex);
  }
}

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
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    data['list'] = list.map((item) => item.toJSON()).toList();
    return data;
  }
}

class Medicine {
  String name = '';
  String location = '';
  List<int> matchNameIndexList = [];
  Medicine(this.name, this.location);
  Medicine.formJSON(Map<String, dynamic> json) {
    name = json['name'];
    location = json['location'];
  }
  toJSON() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    data['location'] = location;
    data['matchNameIndexList'] = [];
    return data;
  }
}

const MEDICINE_PREFERENCE_KEY = 'MEDICINE_AREA_DATA';
const DEFAULT_DATA = '[{"name":"Z区","list":[{"name":"紫草","location":"A-1-3","matchNameIndexList":[]},{"name":"知哥","location":"A-1-4","matchNameIndexList":[]}]},{"name":"Y区","list":[{"name":"夜明砂","location":"B-1","matchNameIndexList":[]},{"name":"益母草","location":"B-9","matchNameIndexList":[]}]}]';


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Timer? _timer;
  String _searchValue = '';
  List<MedicineArea> _medicineAreaList = [];
  List<MedicineArea> _medicineAreaListSource = [];
  Directory? _appDocumentsDir;

  _updateMedicineAreaList () {
    var cloneMedicineAreaList = _medicineAreaListSource.map((e) => MedicineArea.formJSON(e.toJSON())).toList();
    List<MedicineArea> filterMedicineAreaList = [];
    String searchValue = _searchValue.trim();
    if (searchValue == '') {
      filterMedicineAreaList.addAll(cloneMedicineAreaList);
    } else {
      cloneMedicineAreaList.forEach((element) {
        List<Medicine> list = [];
        element.list.forEach((element) {
          List<int> matchIndices = _matchString(element.name, searchValue);
          element.matchNameIndexList.clear();
          if (matchIndices.isNotEmpty) {
            element.matchNameIndexList.addAll(matchIndices);
            list.add(element);
          }
        });
        if (list.isNotEmpty) {
          element.list.clear();
          element.list.addAll(list);
          filterMedicineAreaList.add(element);
        }
      });
    }
    setState(() {
      _medicineAreaList = filterMedicineAreaList;
    });
  }

  _initData() async{
    List<MedicineArea> medicineAreaList = [];
    try{
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      var str = prefs.getString(MEDICINE_PREFERENCE_KEY);
      if (str == null || str == '' || str.trim() == '') {
        str = DEFAULT_DATA;
      }
      dynamic list = jsonDecode(str);
      list?.forEach((item){
        medicineAreaList.add(MedicineArea.formJSON(item));
      });
    }catch(e) {}
    setState(() {
      _medicineAreaListSource = medicineAreaList;
      _updateMedicineAreaList();
    });
    final Directory appDocumentsDir = await getTemporaryDirectory();
    setState(() {
      _appDocumentsDir = appDocumentsDir;
    });
  }

  _handleSearch(text) {
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 200), () {
      setState(() {
        _searchValue = text;
        _updateMedicineAreaList();
      });
    });
  }

  _matchString(String originalText, String matchText) {

    List<int> matchIndices = [];

    if (matchText.length > originalText.length) {
      return matchIndices;
    }

    int j = 0;
    for (int i = 0; i < matchText.length; i++) {
      var matchTextChar = matchText.substring(i, i + 1);
      if (matchTextChar == '') {
        continue;
      }
      for (j; j < originalText.length; j++) {
        var originalChar = originalText.substring(j, j + 1);
        if (originalChar == '') {
          continue;
        }
        if (originalChar == matchTextChar) {
          matchIndices.add(j);
          break;
        } else {
          var originalPinyinText = PinyinHelper.getPinyin(originalChar, format: PinyinFormat.WITHOUT_TONE);
          var originalPinyinChar = originalPinyinText.safeSubstring(0, 1);
          if (originalPinyinChar.toLowerCase() == matchTextChar.toLowerCase()) {
            matchIndices.add(j);
            break;
          }
        }
      }
    }

    if (matchIndices.isNotEmpty && matchIndices.length != matchText.length) {
      matchIndices.clear();
    }

    return matchIndices;
  }

  // 数据导出
  _createExcel() async {
    var excel = Excel.createExcel();
    _medicineAreaListSource.forEach((element) {
      Sheet sheetObject = excel[element.name];
      element.list.forEach((item) {
        sheetObject.appendRow([TextCellValue(item.name), TextCellValue(item.location)]);
      });
    });
    if (_appDocumentsDir == null) {
      final Directory temp = await getTemporaryDirectory();
      setState(() {
        _appDocumentsDir = temp;
      });
    }
    String outputPath = '${_appDocumentsDir?.path}/药品数据_${Jiffy.now().format(pattern: 'yyyy.hh.mm.ss')}.xlsx';
    // Save the file
    File(outputPath)
      ..createSync(recursive: true)
      ..writeAsBytesSync(excel.encode()!);

    TDToast.showText('保存成功', context: context);
  }

  // 选择文件，数据导入
  _pickFile() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    FilePickerResult? pickFileResult = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
    );
    int count = 0;
    List<MedicineArea> medicineAreaList = [];
    if (pickFileResult == null) return null;
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
        count++;
      }
      medicineAreaList.add(medicineArea);
    }

    // 保存数据到本地
    await prefs.setString(MEDICINE_PREFERENCE_KEY, jsonEncode(medicineAreaList.map((item) => item.toJSON()).toList()));
    TDToast.showText(count > 0 ? '成功导入$count条数据' : '导入数据为空，请检查Excel中数据格式是否正确', context: context);
    setState(() {
      _medicineAreaListSource = medicineAreaList;
      _updateMedicineAreaList();
    });
  }

  @override
  void dispose() {
    super.dispose();
    _timer?.cancel();
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
                  Container(
                    margin: EdgeInsets.fromLTRB(12.5.px, 13.5.px, 12.5.px, 12.px),
                    child: Stack(
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.all(0),
                            child: GestureDetector(
                              onTap: () {},
                              child: Text("中药位置快速查询", style: TextStyle(color: Colors.white, fontSize: 22.px, decoration: TextDecoration.none, fontWeight: FontWeight.w400)),
                            ),
                          ),
                        ),
                        Align(
                            alignment: Alignment.centerRight,
                            child: Container(
                              margin: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                              child: Wrap(
                                spacing: 10.px,
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      if (_medicineAreaListSource.isEmpty) {
                                        return TDToast.showText('没有可以导出的数据', context: context);
                                      }
                                      showGeneralDialog(
                                        context: context,
                                        pageBuilder: (BuildContext buildContext, Animation<double> animation,
                                            Animation<double> secondaryAnimation) {
                                          return TDAlertDialog(
                                            content: '药品数据导出${_appDocumentsDir?.path != null ? '，保存路径：${_appDocumentsDir?.path}' : ''}',
                                            rightBtnAction:() async {
                                              Navigator.of(context).pop();
                                              _createExcel();
                                            },
                                          );
                                        },
                                      );
                                    },
                                    child: Box(
                                      width: 32.px,
                                      height: 32.px,
                                      backgroundColor: hexToColor("#ffeddf"),
                                      borderRadius: BorderRadius.circular(20),
                                      child: GradientIcon(
                                          Icons.add_to_home_screen,
                                          size: 20.px,
                                          gradient: LinearGradient(
                                            colors: _medicineAreaListSource.isNotEmpty ? [
                                              hexToColor("#ff8a06"),
                                              hexToColor("#fc5201"),
                                            ] : [
                                              hexToColor("#cccccc"),
                                              hexToColor("#111111"),
                                            ],
                                            stops: const [0.7, 1.0], // 蓝色占比70%，绿色占比30%
                                          )
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      showAdaptiveActionSheet(
                                        context: context,
                                        androidBorderRadius: 4,
                                        actions: <BottomSheetAction>[
                                          BottomSheetAction(title: Text('Excel导入', style: TextStyle(fontSize: 14.px)), onPressed: (context) {
                                            Navigator.of(context).pop();
                                            _pickFile();
                                          }),
                                        ],
                                        cancelAction: CancelAction(title: Text('取消', style: TextStyle(fontSize: 14.px))),// onPressed parameter is optional by default will dismiss the ActionSheet
                                      );
                                    },
                                    child: Box(
                                      width: 32.px,
                                      height: 32.px,
                                      backgroundColor: hexToColor("#ffeddf"),
                                      borderRadius: BorderRadius.circular(20),
                                      child: GradientIcon(
                                          // Icons.file_upload,
                                          Icons.add_to_photos,
                                          size: 21.px,
                                          gradient: LinearGradient(
                                            colors: [
                                              hexToColor("#ff8a06"),
                                              hexToColor("#fc5201"),
                                            ],
                                            stops: const [0.7, 1.0], // 蓝色占比70%，绿色占比30%
                                          )
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            )
                        )
                      ],
                    ),
                  ),
                  _medicineAreaListSource.isNotEmpty ?
                  // 搜索
                  Container(
                    width: double.infinity,
                    margin: EdgeInsets.only(top: 8.px),
                    child: Container(
                      padding: EdgeInsets.fromLTRB(13.px, 0.px, 13.px, 0.px),
                      child: PhysicalModel(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30.px),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          children: [
                            Input(
                              hintText: "搜索",
                              height: 40.px,
                              padding: EdgeInsets.fromLTRB(18.px, 0, 38.px, 0),
                              onChanged: (text) {
                                _handleSearch(text);
                              },
                              controller: TextEditingController.fromValue(TextEditingValue(
                                text: _searchValue,
                                selection: TextSelection.fromPosition(
                                  TextPosition(
                                    affinity: TextAffinity.downstream,
                                    offset: _searchValue.length
                                  )
                                )
                              ))
                            ),
                            _searchValue.isNotEmpty ? Positioned(
                              right: 6.px,
                              top: 0,
                              bottom: 0,
                              child: Align(
                                alignment: Alignment.center,
                                // margin: EdgeInsets.fromLTRB(0, 8.px, 8.px, 0),
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _searchValue = '';
                                      _handleSearch('');
                                    });
                                  },
                                  child: Box(
                                    // backgroundColor: Colors.red,
                                    child: Padding(
                                      padding: EdgeInsets.all(4.px),
                                      child: Icon(TDIcons.close_circle_filled, size: 19.px, color: hexToColor("#999999")),
                                    ),
                                  ),
                                ),
                              ),
                            ) : Container(),
                          ],
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
                  margin: EdgeInsets.only(top: 10.px),
                  padding: EdgeInsets.fromLTRB(10.px, 0, 10.px, bottom),
                  child: _medicineAreaList.isNotEmpty ? ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      Container(
                        padding: EdgeInsets.fromLTRB(0, 10.px, 0, 10.px),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: _medicineAreaList.asMap().entries.map((medicineAreaEntry) {
                            var i = medicineAreaEntry.key;
                            var e = medicineAreaEntry.value;
                            return Container(
                              margin: EdgeInsets.only(bottom: i < _medicineAreaList.length - 1 ? 14.px : 0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // 区域标题
                                  Container(
                                    margin: EdgeInsets.fromLTRB(2.px, 0, 0, 4.px),
                                    child: Text(e.name, style: TextStyle(fontSize: 18, color: hexToColor("#111211"), decoration: TextDecoration.none)),
                                  ),
                                  // 药品列表
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
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: item.name.split('').asMap().entries.map((e) {
                                                      var medicineNameChar = e.value;
                                                      var medicineNameCharIndex = e.key;
                                                      var isMarched = item.matchNameIndexList.contains(medicineNameCharIndex);
                                                      return Text(
                                                        medicineNameChar,
                                                        style: TextStyle(
                                                          color: isMarched ? hexToColor("#fc1e21") : hexToColor("#111211"),
                                                          fontSize: 12, decoration: TextDecoration.none, fontWeight: isMarched ? FontWeight.w600 : FontWeight.w400
                                                        )
                                                      );
                                                    }).toList(),
                                                  ),
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
                          child: _medicineAreaListSource.isNotEmpty ? Text((_searchValue != '' && _searchValue.trim() != '') ? '没有搜索到药品' : '',
                            style: TextStyle(
                              fontSize: 16.px,
                              fontWeight: FontWeight.w400,
                              color: hexToColor("#333333"),
                              decoration: TextDecoration.none,
                            ),
                          ) : TDEmpty(
                            type: TDEmptyType.plain,
                            emptyText: '请先导入数据',
                            image: Container(
                              width: 190.px,
                              height: 190.px,
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(TDTheme.of(context).radiusDefault),
                                  image: const DecorationImage(image: AssetImage('assets/img/empty.png'), fit: BoxFit.cover)
                              ),
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
