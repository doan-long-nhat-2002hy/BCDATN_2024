import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Công cụ nhận diện cây',
      theme: ThemeData(
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Roboto',
      ),
      debugShowCheckedModeBanner: false,
      home: const MyHomePage(title: 'Công cụ nhận diện cây'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  File? selectedImage;
  String? message = "";
  String? mostCommonLabel = "";
  bool isLoading = false; // Biến trạng thái để kiểm soát hiển thị thông báo "Đang dự đoán"

  uploadImage() async {
    setState(() {
      isLoading = true;
      mostCommonLabel = ""; // Xóa kết quả trước đó khi nhấn nút "Dự đoán"
    });

    final request = http.MultipartRequest("POST", Uri.parse("https://3165-2405-4802-1c64-e740-fd85-147a-9cc5-c459.ngrok-free.app/upload"));
    final headers = {
      "Content-Type": "multipart/form-data",
    };
    request.files.add(
        http.MultipartFile('image', selectedImage!.readAsBytes().asStream(), selectedImage!.lengthSync(), filename: selectedImage!.path.split("/").last)
    );
    request.headers.addAll(headers);
    final response = await request.send();
    http.Response res = await http.Response.fromStream(response);
    final resJson = jsonDecode(res.body);
    setState(() {
      message = resJson['message'];
      mostCommonLabel = resJson['most_common_label_name'];
      isLoading = false; // Kết thúc trạng thái "Đang dự đoán"
    });
  }

  Future<void> _showImageSourceSelection() async {
    final ImagePicker picker = ImagePicker();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Chọn nguồn ảnh'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.camera_alt),
                title: Text('Chụp ảnh từ camera'),
                onTap: () async {
                  Navigator.of(context).pop();
                  final pickedImage = await picker.getImage(source: ImageSource.camera);
                  setState(() {
                    selectedImage = File(pickedImage!.path);
                    mostCommonLabel = ""; // Xóa kết quả khi chọn ảnh mới
                  });
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text('Chọn ảnh từ thư viện'),
                onTap: () async {
                  Navigator.of(context).pop();
                  final pickedImage = await picker.getImage(source: ImageSource.gallery);
                  setState(() {
                    selectedImage = File(pickedImage!.path);
                    mostCommonLabel = ""; // Xóa kết quả khi chọn ảnh mới
                  });
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _deleteImage() {
    setState(() {
      selectedImage = null;
      mostCommonLabel = ""; // Xóa kết quả khi xóa ảnh
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: Text(widget.title),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 120.0), // Thêm đệm dưới
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    "Nhận diện cây",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                  const SizedBox(height: 20),
                  selectedImage == null
                      ? Container(
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.green, width: 2),
                    ),
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.image,
                          size: 100,
                          color: Colors.green[300],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "Vui lòng tải ảnh lên để nhận diện cây",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 18, color: Colors.green[700]),
                        ),
                      ],
                    ),
                  )
                      : Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.5),
                              spreadRadius: 5,
                              blurRadius: 7,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        width: double.infinity,
                        height: 300,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15.0),
                          child: Image.file(
                            selectedImage!,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 10,
                        right: 10,
                        child: GestureDetector(
                          onTap: _deleteImage,
                          child: Container(
                            padding: const EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.withOpacity(0.5),
                                  spreadRadius: 2,
                                  blurRadius: 5,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.delete,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Nút "Dự đoán" với hiệu ứng động và biểu tượng mới
                  AnimatedOpacity(
                    opacity: selectedImage == null ? 0.5 : 1.0,
                    duration: Duration(milliseconds: 300),
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 30.0),
                        primary: Colors.blueAccent,
                        onPrimary: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        elevation: 5, // Hiệu ứng nổi
                        shadowColor: Colors.blueAccent.withOpacity(0.5), // Màu sắc của bóng
                        side: BorderSide(color: Colors.blueAccent, width: 2), // Viền của nút
                      ),
                      onPressed: selectedImage == null ? null : uploadImage,
                      icon: Icon(
                        Icons.analytics,  // Thay đổi biểu tượng cho phù hợp với chức năng dự đoán
                        size: 24,
                      ),
                      label: Text(
                        isLoading ? "Đang dự đoán" : "Dự đoán",  // Hiển thị thông báo "Đang dự đoán" khi đang chờ kết quả
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (isLoading) // Hiển thị thông báo "Đang dự đoán" khi đang chờ kết quả
                    CircularProgressIndicator(),
                  if (mostCommonLabel != null && mostCommonLabel!.isNotEmpty)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.green, width: 2),
                      ),
                      padding: const EdgeInsets.all(20.0),
                      child: Text(
                        "Kết quả: $mostCommonLabel",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 16.0,
            right: 16.0,
            child: FloatingActionButton(
              onPressed: _showImageSourceSelection,
              tooltip: 'Chọn ảnh',
              backgroundColor: Colors.green,
              child: Icon(Icons.add_a_photo),
            ),
          ),
        ],
      ),
    );
  }
}


// import 'dart:convert';
// import 'dart:io';
//
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:http/http.dart' as http;
//
// void main() {
//   runApp(const MyApp());
// }
//
// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//
//   // This widget is the root of your application.
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Flutter Demo',
//       theme: ThemeData(
//         colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
//         useMaterial3: true,
//       ),
//       debugShowCheckedModeBanner: false ,
//       home: const MyHomePage(title: 'Công cụ nhận diện cây'),
//     );
//   }
// }
//
// class MyHomePage extends StatefulWidget {
//   const MyHomePage({super.key, required this.title});
//
//   final String title;
//
//   @override
//   State<MyHomePage> createState() => _MyHomePageState();
// }
//
// class _MyHomePageState extends State<MyHomePage> {
//   File? selectedImage;
//   String? message = "";
//   String? mostCommonLabel = "";
//
//   uploadImage() async{
//     final request = http.MultipartRequest("POST", Uri.parse("https://3165-2405-4802-1c64-e740-fd85-147a-9cc5-c459.ngrok-free.app/upload"));
//     final headers = {
//       "Content-Type": "multipart/form-data",
//     };
//     request.files.add(
//         http.MultipartFile('image', selectedImage!.readAsBytes().asStream(), selectedImage!.lengthSync(), filename: selectedImage!.path.split("/").last)
//     );
//     request.headers.addAll(headers);
//     final response = await request.send();
//     http.Response res = await http.Response.fromStream(response);
//     final resJson = jsonDecode(res.body);
//     // message = resJson['message'];
//     setState(() {
//       message = resJson['message'];
//       mostCommonLabel = resJson['most_common_label_name']; // Nhận giá trị most_common_label_name từ Flask
//     });
//   }
//
//   Future getImage1() async{
//     final pickedImage = await ImagePicker().getImage(source: ImageSource.camera);
//     selectedImage = File(pickedImage!.path);
//     setState(() {
//     });
//   }
//
//   Future getImage() async{
//     final pickedImage = await ImagePicker().getImage(source: ImageSource.gallery);
//     selectedImage = File(pickedImage!.path);
//     setState(() {
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Theme.of(context).colorScheme.inversePrimary,
//         title: Text(widget.title),
//       ),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: <Widget>[
//             selectedImage == null
//                 ? Text("Vui lòng tải ảnh lên để nhận diện cây")
//                 : Image.file(selectedImage!),
//             TextButton.icon(
//                 style: ButtonStyle(
//                   backgroundColor: MaterialStateProperty.all(Colors.blue),
//                 ),
//                 onPressed: uploadImage,
//                 icon: Icon(Icons.upload_file, color: Colors.white),
//                 label: Text("Dự đoán")),
//             TextButton(onPressed: getImage1, child: Icon(Icons.add_a_photo)),
//             SizedBox(height: 20), // Khoảng cách giữa nút Upload và mostCommonLabel
//             mostCommonLabel != null
//                 ? Text("Kết quả: $mostCommonLabel",
//                 style: TextStyle(fontSize: 18))
//                 : Container(), // Hiển thị mostCommonLabel
//           ],
//         ),
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: getImage,
//         tooltip: 'Pick Image',
//         child: Icon(Icons.add_a_photo),
//       ),
//     );
//   }
// }
