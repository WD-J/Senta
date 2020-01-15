import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'supplemental/cut_corners_border.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'package:page_transition/page_transition.dart';
import 'package:circular_bottom_navigation/circular_bottom_navigation.dart';
import 'package:circular_bottom_navigation/tab_item.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:math';
import 'dart:typed_data';
import 'dart:io';
import 'dart:async';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:random_string/random_string.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flushbar/flushbar.dart';
import 'package:path/path.dart' as p;

/* Primary Colors:
        primaryColor: Colors.blueAccent[700],
        secondaryColor: Colors.redAccent[700],
        tertiaryColor: Colors.greenAccent[700],
        Pastel: [200]
*/

void main() => runApp(MyApp());

var currentUID;

final FirebaseAuth _auth = FirebaseAuth.instance;

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Senta',
      theme: ThemeData(
        hintColor: Colors.redAccent[700],
        highlightColor: Colors.redAccent[700],
        primaryColor: Colors.blueAccent[700],
      ),
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/HomePage':
            return PageTransition(
                child: HomePage(),
                type: PageTransitionType.fade,
                duration: Duration(seconds: 0));
          case '/SignupLoginPage':
            return PageTransition(
                child: SignupLoginPage(),
                type: PageTransitionType.fade,
                duration: Duration(seconds: 0));
          default:
            return PageTransition(
                child: LoadingPage(),
                type: PageTransitionType.fade,
                duration: Duration(seconds: 0));
        }
      },
    );
  }
}

class LoadingPage extends StatefulWidget {
  @override
  _LoadingPage createState() => _LoadingPage();
}

class _LoadingPage extends State<LoadingPage> {
  @override
  void initState() {
    super.initState();
    getUser().then((user) {
      if (user != null) {
        currentUID = user.uid;
        Navigator.pushReplacementNamed(context, '/HomePage');
      } else {
        Navigator.pushReplacementNamed(context, '/SignupLoginPage');
      }
    });
  }

  Future<FirebaseUser> getUser() async {
    return await _auth.currentUser();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold();
  }
}

class SignupLoginPage extends StatefulWidget {
  SignupLoginPage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _SignupLoginPage createState() => _SignupLoginPage();
}

class _SignupLoginPage extends State<SignupLoginPage> {
  var signupOpened = false;
  var loginOpened = false;

  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController usernameController = TextEditingController();

  void signUpWithEmail() async {
    // marked async
    FirebaseUser user;
    try {
      user = await _auth.createUserWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );
    } catch (e) {
      print(e.toString());
    } finally {
      if (user != null) {
        await getDownloadUrl(context);

        Firestore.instance.collection('users').document().setData({
          'displayName': usernameController.text,
          'photoUrl': fileUrl.toString(),
          'email': user.email,
          'uid': user.uid,
          // 'isEmailVerified': user.isEmailVerified,   // will also be false
        });

        // sign up successful!
        Navigator.pushReplacementNamed(context, '/HomePage');
      } else {
        // sign up unsuccessful
        // ex: prompt the user to try again
      }
    }
  }

  void logInWithEmail() async {
    // marked async
    FirebaseUser user;
    try {
      user = await _auth.signInWithEmailAndPassword(
          email: emailController.text, password: passwordController.text);
    } catch (e) {
      print(e.toString());
    } finally {
      if (user != null) {
        // log in successful!
        Navigator.pushReplacementNamed(context, '/HomePage');
        HomePage();
      } else {
        // log in unsuccessful
        // ex: prompt the user to try again
      }
    }
  }

  File _file;
  bool _isLoading = false;
  var fileUrl;
  var fileExtension;

  Future getPfp(bool isCamera) async {
    File file;
    if (isCamera) {
      file = await ImagePicker.pickImage(source: ImageSource.camera);
    } else {
      //file = await ImagePicker.pickImage(source: ImageSource.gallery);
      file = await FilePicker.getFile(type: FileType.IMAGE);
    }

    setState(() {
      _file = file;
      fileExtension = p
          .extension(file.toString())
          .split('?')
          .first
          .replaceFirst(".", "")
          .replaceFirst("'", "");
    });
  }

  Future getDownloadUrl(BuildContext context) async {
    setState(() {
      _isLoading = true;
    });

    final FirebaseUser user = await FirebaseAuth.instance.currentUser();
    final String userID = user.uid.toString();

    // randomAlpha was 5, then 28
    String fileId = userID + " - " + randomAlphaNumeric(5);

    StorageReference reference =
        FirebaseStorage.instance.ref().child("$fileId");

    StorageUploadTask uploadTask = reference.putFile(
      _file,
      StorageMetadata(
        // Here you need to update the type depending on what the user wants to upload.
        contentType: "image" + '/' + fileExtension,
      ),
    );
    StorageTaskSnapshot taskSnapshot = await uploadTask.onComplete;
    String downloadUrl = await taskSnapshot.ref.getDownloadURL();
    // Maybe input download url in image.network ??
    fileUrl = downloadUrl;

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueAccent[700],
      body: Padding(
        padding: const EdgeInsets.only(left: 25, right: 25, top: 50, bottom: 0),
        child: Column(children: <Widget>[
          Text(
            "Senta          ",
            textAlign: TextAlign.start,
            style: TextStyle(
                fontSize: 75, color: Colors.white, fontWeight: FontWeight.bold),
          ),
          Text(
            "One post a day keeps the impetuous away",
            textAlign: TextAlign.start,
            style: TextStyle(
                fontSize: 25,
                color: Colors.white,
                fontWeight: FontWeight.normal),
          ),
          Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(top: 35),
                child: AnimatedContainer(
                  duration: Duration(seconds: 1),
                  curve: Curves.fastOutSlowIn,
                  width: 350,
                  height: signupOpened ? 380 : 60,
                  child: Container(
                    decoration: ShapeDecoration(
                      color: Colors.redAccent[700],
                      shape: BeveledRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Column(
                        children: <Widget>[
                          SizedBox(
                            width: 350,
                            height: 60,
                            child: RaisedButton(
                              onPressed: () {
                                setState(() {
                                  signupOpened = !signupOpened;
                                  loginOpened = false;
                                });
                              },
                              shape: BeveledRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              color: Colors.redAccent[700],
                              child: Text(
                                "Sign up",
                                style: TextStyle(
                                    fontSize: 25,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w300),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: SizedBox(
                              width: 350,
                              child: TextField(
                                controller: emailController,
                                textInputAction: TextInputAction.next,
                                keyboardType: TextInputType.emailAddress,
                                cursorColor: Colors.white,
                                style: TextStyle(
                                    decorationColor: Colors.red,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w300,
                                    fontSize: 25),
                                decoration: InputDecoration(
                                  labelText: " Email ",
                                  labelStyle: TextStyle(
                                      fontWeight: FontWeight.w300,
                                      color: Colors.white,
                                      fontSize: 25),
                                  hintStyle: TextStyle(
                                      fontWeight: FontWeight.w300,
                                      color: Colors.white,
                                      fontSize: 25),
                                  border: CutCornersBorder(cut: 10),
                                  focusedBorder: CutCornersBorder(
                                      cut: 10,
                                      borderSide: BorderSide(
                                          color: Colors.redAccent[700])),
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: SizedBox(
                              width: 350,
                              child: TextField(
                                controller: usernameController,
                                cursorColor: Colors.white,
                                style: TextStyle(
                                    decorationColor: Colors.red,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w300,
                                    fontSize: 25),
                                decoration: InputDecoration(
                                  labelText: " Username ",
                                  labelStyle: TextStyle(
                                      fontWeight: FontWeight.w300,
                                      color: Colors.white,
                                      fontSize: 25),
                                  hintStyle: TextStyle(
                                      fontWeight: FontWeight.w300,
                                      color: Colors.white,
                                      fontSize: 25),
                                  border: CutCornersBorder(cut: 10),
                                  focusedBorder: CutCornersBorder(
                                      cut: 10,
                                      borderSide: BorderSide(
                                          color: Colors.redAccent[700])),
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: SizedBox(
                              width: 350,
                              child: TextField(
                                controller: passwordController,
                                obscureText: true,
                                cursorColor: Colors.white,
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w300,
                                    fontSize: 25),
                                decoration: InputDecoration(
                                  labelText: " Password ",
                                  labelStyle: TextStyle(
                                      fontWeight: FontWeight.w300,
                                      color: Colors.white,
                                      fontSize: 25),
                                  hintStyle: TextStyle(
                                      fontWeight: FontWeight.w300,
                                      color: Colors.white,
                                      fontSize: 25),
                                  border: CutCornersBorder(cut: 10),
                                  focusedBorder: CutCornersBorder(
                                      cut: 10,
                                      borderSide: BorderSide(
                                          color: Colors.redAccent[700])),
                                ),
                              ),
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              IconButton(
                                icon: Icon(Icons.folder),
                                onPressed: () {
                                  getPfp(false);
                                },
                              ),
                              SizedBox(
                                width: 15.0,
                              ),
                              IconButton(
                                icon: Icon(Icons.camera_alt),
                                onPressed: () {
                                  getPfp(true);
                                },
                              ),
                            ],
                          ),
                          SizedBox(
                            height: 10.0,
                          ),
                          _file == null
                              ? Container()
                              : Image.file(
                                  _file,
                                  height: 300.0,
                                  width: 300.0,
                                ),
                          SizedBox(
                            height: 15.0,
                          ),
                          _file == null
                              ? Container()
                              : _isLoading == true
                                  ? CircularProgressIndicator()
                                  : RaisedButton(
                                      onPressed: () {
                                        getDownloadUrl(context);
                                      },
                                      child: Text(
                                        'Upload',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      color: Theme.of(context).accentColor,
                                    ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: AnimatedContainer(
                  duration: Duration(seconds: 1),
                  curve: Curves.fastOutSlowIn,
                  width: 350,
                  height: loginOpened ? 240 : 60,
                  child: Container(
                    decoration: ShapeDecoration(
                      color: Colors.redAccent[700],
                      shape: BeveledRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Column(
                        children: <Widget>[
                          SizedBox(
                            width: 350,
                            height: 60,
                            child: RaisedButton(
                              onPressed: () {
                                setState(() {
                                  loginOpened = !loginOpened;
                                  signupOpened = false;
                                });
                              },
                              shape: BeveledRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              color: Colors.redAccent[700],
                              child: Text(
                                "Log in",
                                style: TextStyle(
                                    fontSize: 25,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w300),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: SizedBox(
                              width: 350,
                              child: TextField(
                                controller: emailController,
                                textInputAction: TextInputAction.next,
                                keyboardType: TextInputType.emailAddress,
                                cursorColor: Colors.white,
                                style: TextStyle(
                                    decorationColor: Colors.red,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w300,
                                    fontSize: 25),
                                decoration: InputDecoration(
                                  labelText: " Email ",
                                  labelStyle: TextStyle(
                                      fontWeight: FontWeight.w300,
                                      color: Colors.white,
                                      fontSize: 25),
                                  hintStyle: TextStyle(
                                      fontWeight: FontWeight.w300,
                                      color: Colors.white,
                                      fontSize: 25),
                                  border: CutCornersBorder(cut: 10),
                                  focusedBorder: CutCornersBorder(
                                      cut: 10,
                                      borderSide: BorderSide(
                                          color: Colors.redAccent[700])),
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: SizedBox(
                              width: 350,
                              child: TextField(
                                controller: passwordController,
                                obscureText: true,
                                cursorColor: Colors.white,
                                style: TextStyle(
                                    decorationColor: Colors.red,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w300,
                                    fontSize: 25),
                                decoration: InputDecoration(
                                  labelText: " Password ",
                                  labelStyle: TextStyle(
                                      fontWeight: FontWeight.w300,
                                      color: Colors.white,
                                      fontSize: 25),
                                  hintStyle: TextStyle(
                                      fontWeight: FontWeight.w300,
                                      color: Colors.white,
                                      fontSize: 25),
                                  border: CutCornersBorder(cut: 10),
                                  focusedBorder: CutCornersBorder(
                                      cut: 10,
                                      borderSide: BorderSide(
                                          color: Colors.redAccent[700])),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 24),
            child: SizedBox(
              width: 350,
              height: 60,
              child: RaisedButton(
                highlightColor: Colors.white,
                onPressed: () {
                  if (signupOpened == true) {
                    signUpWithEmail();
                  } else {
                    logInWithEmail();
                  }
                },
                shape: BeveledRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                color: Colors.white,
                child: Text(
                  "Continue",
                  style: TextStyle(
                      fontSize: 25,
                      color: Colors.redAccent[700],
                      fontWeight: FontWeight.normal),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

List<TabItem> tabItems = List.of([
  TabItem(Icons.person, "Profile", Colors.red),
  TabItem(Icons.file_upload, "Post", Colors.orange),
  TabItem(Icons.home, "Home", Colors.blue),
  TabItem(Icons.view_day, "Discover", Colors.green),
  TabItem(Icons.message, "Messages", Colors.yellow),
]);

class _HomePageState extends State<HomePage> {
  int selectedPos = 2;

  double bottomNavBarHeight = 60;

  CircularBottomNavigationController _navigationController;

  @override
  void initState() {
    super.initState();
    _navigationController = CircularBottomNavigationController(selectedPos);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          Padding(
            child: bodyContainer(),
            padding: EdgeInsets.only(bottom: bottomNavBarHeight),
          ),
          Align(alignment: Alignment.bottomCenter, child: bottomNav())
        ],
      ),
    );
  }

  Widget bodyContainer() {
    Color selectedColor = tabItems[selectedPos].color;
    var buildMethod;
    switch (selectedPos) {
      case 0:
        buildMethod = profile();
        break;
      case 1:
        buildMethod = post();
        break;
      case 2:
        buildMethod = home();
        break;
      case 3:
        buildMethod = discover();
        break;
      case 4:
        buildMethod = messages();
        break;
    }

    return Scaffold(
      backgroundColor: selectedColor,
      body: Padding(
        padding: const EdgeInsets.only(left: 25, right: 25, top: 50, bottom: 0),
        child: buildMethod,
      ),
    );
  }

  Widget bottomNav() {
    GestureDetector(
      child: Container(
        width: double.infinity,
        height: bottomNavBarHeight,
      ),
      onTap: () {
        if (_navigationController.value == tabItems.length - 1) {
          _navigationController.value = 0;
        } else {
          _navigationController.value++;
        }
      },
    );

    return CircularBottomNavigation(
      tabItems,
      controller: _navigationController,
      barHeight: bottomNavBarHeight,
      barBackgroundColor: Colors.white,
      animationDuration: Duration(milliseconds: 200),
      selectedCallback: (int selectedPos) {
        setState(() {
          this.selectedPos = selectedPos;
        });
      },
    );
  }

  Widget profile() {
    return Scaffold(
      appBar: AppBar(
        title: Text("Profile"),
      ),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(10.0),
          child: StreamBuilder<QuerySnapshot>(
            stream: Firestore.instance
                .collection('users')
                .where('uid', isEqualTo: currentUID)
                .snapshots(),
            builder:
                (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (snapshot.hasError) return Text('Error: ${snapshot.error}');
              switch (snapshot.connectionState) {
                case ConnectionState.waiting:
                  return CircularProgressIndicator();
                default:
                  if (snapshot.data.documents.length == 0) {
                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Center(child: Text("lol")),
                    );
                  } else {
                    return ListView(
                      children: snapshot.data.documents
                          .map((DocumentSnapshot document) {
                        return Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: <Widget>[
                              Text(document['displayName']),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  }
              }
            },
          ),
        ),
      ),
    );
  }

  File _file;
  bool _isLoading = false;
  var fileUrl;
  var fileExtension;

  Future getImage(bool isCamera) async {
    File file;
    if (isCamera) {
      file = await ImagePicker.pickImage(source: ImageSource.camera);
    } else {
      //file = await ImagePicker.pickImage(source: ImageSource.gallery);
      file = await FilePicker.getFile(type: FileType.IMAGE);
    }

    setState(() {
      _file = file;
      fileExtension = p
          .extension(file.toString())
          .split('?')
          .first
          .replaceFirst(".", "")
          .replaceFirst("'", "");
    });
  }

  Future getDownloadUrl(BuildContext context) async {
    setState(() {
      _isLoading = true;
    });

    final FirebaseUser user = await FirebaseAuth.instance.currentUser();
    final String userID = user.uid.toString();

    // randomAlpha was 5, then 28
    String fileId = userID + " - " + randomAlphaNumeric(5);

    StorageReference reference =
        FirebaseStorage.instance.ref().child("$fileId");

    StorageUploadTask uploadTask = reference.putFile(
      _file,
      StorageMetadata(
        // Here you need to update the type depending on what the user wants to upload.
        contentType: "image" + '/' + fileExtension,
      ),
    );
    StorageTaskSnapshot taskSnapshot = await uploadTask.onComplete;
    String downloadUrl = await taskSnapshot.ref.getDownloadURL();
    // Maybe input download url in image.network ??
    fileUrl = downloadUrl;

    setState(() {
      _isLoading = false;
    });
    _showResponse(context);
  }

  void _showResponse(context) {
    showModalBottomSheet(
        builder: (BuildContext context) {
          // redirect to the mainscreen where your post is being posted and presented to the viewer.

          Flushbar(
            message:
                "Lorem Ipsum is simply dummy text of the printing and typesetting industry",
            icon: Icon(
              Icons.info_outline,
              size: 28.0,
              color: Colors.blue[300],
            ),
            duration: Duration(seconds: 3),
            leftBarIndicatorColor: Colors.blue[300],
          )..show(context);

          /*
                  onPressed: () {
                    setState(() {
                      _imageFile = null;
                    });
                    Navigator.pop(context);
                  },
           */
        },
        context: context);
  }

  /*
  IDEA FOR HOW TO FIX THE ISSUE OF HAVING TO SAVE AN IMAGE TWICE, ONE TO THE DISCOVER PAGE AND ONE FOR INDIVIDUAL ACCOUNTS:
  SAVE THE IMAGE ONCE FOR THE DISCOVER PAGE, AKA THE INDIVIDUAL TOPICS YOU CAN SUBSCRIBE TO, AND THEN WHEN THE USER PUBLISHES AN IMAGE-
  IT SAVES THE downloadUrl TO A LIST OF URL'S THAT ALL INDIVIDUALLY GET PARSED THROUGH IN IMAGE.NETWORK WHEN BUILDING THE ACCOUNT PAGE.
  IT READS IT OFF THE USERS DATABASE PAGE IN FIREBASE.
   */

  Widget post() {
    return Scaffold(
      backgroundColor: Colors.orange,
      body: Column(
        children: <Widget>[
          Text(
            "Post!          ",
            textAlign: TextAlign.start,
            style: TextStyle(
                fontSize: 75, color: Colors.white, fontWeight: FontWeight.bold),
          ),
          Text(
            "Insert instructions of how to post here.",
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 25, color: Colors.white, fontWeight: FontWeight.bold),
          ),
          SizedBox(
            height: 25,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              IconButton(
                icon: Icon(Icons.folder),
                onPressed: () {
                  getImage(false);
                },
              ),
              SizedBox(
                width: 15.0,
              ),
              IconButton(
                icon: Icon(Icons.camera_alt),
                onPressed: () {
                  getImage(true);
                },
              ),
            ],
          ),
          SizedBox(
            height: 10.0,
          ),
          _file == null
              ? Container()
              : Image.file(
                  _file,
                  height: 300.0,
                  width: 300.0,
                ),
          SizedBox(
            height: 15.0,
          ),
          _file == null
              ? Container()
              : _isLoading == true
                  ? CircularProgressIndicator()
                  : RaisedButton(
                      onPressed: () {
                        getDownloadUrl(context);
                      },
                      child: Text(
                        'Upload',
                        style: TextStyle(color: Colors.white),
                      ),
                      color: Theme.of(context).accentColor,
                    ),
        ],
      ),
    );
  }

  Widget home() {
    return Column(
      children: <Widget>[
        Center(
          child: Text(
            "Home",
            style: TextStyle(
                fontSize: 25,
                color: Colors.white,
                fontWeight: FontWeight.normal),
          ),
        ),
      ],
    );
  }

  /*
  Widget discover() {
    return Scaffold(
      appBar: AppBar(
        title: Text("Discover page"),
      ),
      body: Center(
        child: Image.network("lol"),
      ),
    );
  }
  */

  Widget discover() {
    return Scaffold(
      appBar: AppBar(
        title: Text("Discover"),
      ),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(10.0),
          child: StreamBuilder<QuerySnapshot>(
            stream: Firestore.instance
                .collection('categories')
                .document('gore')
                .collection('posts')
                /*
                Here's an example of finding all the newest content within a certain category / keyword:
                .collection('users')
                .where('publishedContent', arrayContains: 'gore')

                or

                .where('publishedContent')
                .where('gore')

                */
                .snapshots(),
            builder:
                (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (snapshot.hasError) return Text('Error: ${snapshot.error}');
              switch (snapshot.connectionState) {
                case ConnectionState.waiting:
                  return CircularProgressIndicator();
                default:
                  return ListView(
                    children: snapshot.data.documents
                        .map((DocumentSnapshot document) {
                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: <Widget>[
                            Text(document['postDescription'].toString()),
                            Image.network(document['postUrl'])
                          ],
                        ),
                      );
                    }).toList(),
                  );
              }
            },
          ),
        ),
      ),
    );
  }

  Widget messages() {
    return Scaffold(
      appBar: AppBar(
        title: Text("Messages"),
      ),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(10.0),
          child: StreamBuilder<QuerySnapshot>(
            stream: Firestore.instance
                .collection('users')
                /*
                Here's an example of finding all the newest content within a certain category / keyword:
                .collection('users')
                .where('publishedContent', arrayContains: 'gore')

                or

                .where('publishedContent')
                .where('gore')

                */
                .snapshots(),
            builder:
                (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (snapshot.hasError) return Text('Error: ${snapshot.error}');
              switch (snapshot.connectionState) {
                case ConnectionState.waiting:
                  return CircularProgressIndicator();
                default:
                  return ListView(
                    children: snapshot.data.documents
                        .map((DocumentSnapshot document) {
                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          document['displayName'].toString(),
                          style: TextStyle(fontSize: 24),
                        ),
                      );
                    }).toList(),
                  );
              }
            },
          ),
        ),
      ),
    );
  }
}
