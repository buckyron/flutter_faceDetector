import 'dart:io';
import 'dart:ui'as ui;
import 'package:flutter/painting.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(

        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Face Detector'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  File _imageFile;
  List<Face> _faces;
  ui.Image image;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }





  void _faceDetector() async{
    final imageFile = await ImagePicker.pickImage(source: ImageSource.gallery);
    final firebaseImage = FirebaseVisionImage.fromFile(imageFile);
    final faceDetector = FirebaseVision.instance.faceDetector();
    final faces = await faceDetector.processImage(firebaseImage);
    final data = await imageFile.readAsBytes();
    await decodeImageFromList(data).then((value) {
      if (mounted){
        setState(() {
          _imageFile = imageFile;
          image = value;
          _faces = faces;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {

    Size size = MediaQuery.of(context).size;

    List<Widget> stackChildren = [];
//
    if(stackChildren.isNotEmpty) stackChildren.removeLast();
    stackChildren.add(Positioned(
      top: 0.0,
      left: 0.0,
      width: size.width,
      child: image != null? _faces.length != 0? ImagesAndFaces(image: image,faces: _faces,imageFile: _imageFile,):ImageViewer(imageFile: _imageFile): Center(child: Text('Pick an image'),),
    ));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Stack(
        children: stackChildren,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _faceDetector(),
        child: Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

class ImagesAndFaces extends StatefulWidget {
  ImagesAndFaces({Key key,this.image, this.faces, this.imageFile}): super(key: key);
  final ui.Image image;
  final List<Face> faces;
  final File imageFile;

  @override
  _ImagesAndFacesState createState() => _ImagesAndFacesState();
}

class _ImagesAndFacesState extends State<ImagesAndFaces> {

  boundBoxes(List<Face> faces){
    List<Rect> faceBoxes = List<Rect>();

    for (Face face in faces){
      final pos = face.boundingBox;
      Rect rect = Rect.fromLTRB(pos.left, pos.top, pos.right, pos.bottom);
      faceBoxes.add(rect);
    }
    return faceBoxes;
  }

  @override
  Widget build(BuildContext context) {

    return FittedBox(
      child: SizedBox(
        width: widget.image.width.toDouble(),
        height: widget.image.height.toDouble(),
        child:CustomPaint(
            child: Container(),
            willChange: true,
            painter: MyPainter(widget.image, boundBoxes(widget.faces)),
        ),
      ),
    );
  }
}

class ImageViewer extends StatelessWidget {
  ImageViewer({this.imageFile});
  final File imageFile;
  @override
  Widget build(BuildContext context) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            Container(height:500,child: Image.file(imageFile)),
            SizedBox(height: 30,),
            Container(child: Center(child: Text('No faces detected')))
          ],
        );

  }
}



class MyPainter extends CustomPainter{
  final ui.Image image;
  final List<Rect> faces;
  MyPainter(this.image,this.faces);


  
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawColor(Colors.transparent, BlendMode.clear);

    var paint1 = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..color = Colors.red;

    canvas.drawImage(image,Offset.zero,Paint() );
    for (var i = 0; i < faces.length;i++){
      canvas.drawRect(faces[i], paint1);
    }
  }


  @override
  bool shouldRepaint(MyPainter oldDelegate) {

    if(image != oldDelegate.image || faces != oldDelegate.faces) {
      return true;
    }
    return false;

  }
}

