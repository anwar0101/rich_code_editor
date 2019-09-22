import 'package:example/python_highlighter.dart';
import 'package:flutter/material.dart';
import 'package:overlay_container/overlay_container.dart';
import 'package:rich_code_editor/code_editor/widgets/code_text_field.dart';
import 'package:rich_code_editor/rich_code_editor.dart';

void main() {
  runApp(MaterialApp(
    home: Home(),
  ));
}

class Home extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: Center(
          child: FlatButton(
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => DemoCodeEditor()));
            },
            child: Text("My Code Editor"),
          ),
        ),
      ),
    );
  }
}

class DemoCodeEditor extends StatefulWidget {
  @override
  _DemoCodeEditorState createState() => _DemoCodeEditorState();
}

class _DemoCodeEditorState extends State<DemoCodeEditor> {
  // GlobalKey<RichTextFieldState> _richTextFieldState =
  //     new GlobalKey<RichTextFieldState>();

  CodeEditingController _cec = CodeEditingController();

  int lastPosition = -1;

  String lastwordTyped = "";

  var autoSuggesstion = false;

  Rect cursor;

  @override
  void dispose() {
    //_richTextFieldState.currentState?.dispose();
    super.dispose();
  }

  _insert(int start, String newText) {
    final TextSelection currentSelection = _cec.selection;

    var completeText = _cec.value.text;

    var textBefore = completeText.substring(
        0, currentSelection.start - lastwordTyped.length);
    var textAfter =
        completeText.substring(currentSelection.start, completeText.length);

    var result = "";

    if (textBefore.length == 0) {
      // at the beginning of editor
      result = newText;
    } else {
      if (textBefore.length > 0) {
        result = textBefore + newText;
      }

      if (textAfter.length > 0) {
        result = result + textAfter;
      }
    }

    var plainStyle = TextStyle(fontSize: 16.0, color: Colors.black);

    var ls = _getTextSpans(result);
    _cec.value = _cec.value.copyWith(
        remotelyEdited: true,
        value: new TextSpan(text: "", style: plainStyle, children: ls),
        selection: TextSelection.fromPosition(TextPosition(
            affinity: TextAffinity.upstream,
            offset: currentSelection.start +
                newText.length -
                lastwordTyped.length)));
    autoSuggesstion = false;
    setState(() {});
  }

  List<TextSpan> _getTextSpans(String text) {
    List<TextSpan> ls = [];

    var plainStyle = TextStyle(fontSize: 16.0, color: Colors.black);

    var lines = text.split("\n"); //splits each line
    var space = TextSpan(text: " ", style: plainStyle);
    var lineSpan = TextSpan(text: "\n", style: plainStyle);
    for (var i = 0; i < lines.length; i++) {
      var line = lines[i];
      if (line == "    ") {
        ls.add(TextSpan(text: "    ", style: plainStyle));
        continue;
      }
      var words = line.split(" "); //add other delimeters here..
      var isCode = true;

      for (var j = 0; j < words.length; j++) {
        var word = words[j];
        var ts = TextSpan(text: word, style: plainStyle);

        isCode = !isCode;

        if (word != "") {
          ls.add(ts);
        }

        if (words.length - (j + 1) > 0) {
          ls.add(space);
        }
      }
      if (lines.length - (i + 1) > 0) {
        ls.add(lineSpan);
      }
    }

    return ls;
  }

  _overLayContainer() {
    // backing data
    final europeanCountries = [
      'Albania',
      'Andorra',
      'Armenia',
      'Austria',
      'Azerbaijan',
      'Belarus',
      'Belgium',
      'Bosnia and Herzegovina',
      'Bulgaria',
      'Croatia',
      'Cyprus',
      'Czech Republic',
      'Denmark',
      'Estonia',
      'Finland',
      'France',
      'Georgia',
      'Germany',
      'Greece',
      'Hungary',
      'Iceland',
      'Ireland',
      'Italy',
      'Kazakhstan',
      'Kosovo',
      'Latvia',
      'Liechtenstein',
      'Lithuania',
      'Luxembourg',
      'Macedonia',
      'Malta',
      'Moldova',
      'Monaco',
      'Montenegro',
      'Netherlands',
      'Norway',
      'Poland',
      'Portugal',
      'Romania',
      'Russia',
      'San Marino',
      'Serbia',
      'Slovakia',
      'Slovenia',
      'Spain',
      'Sweden',
      'Switzerland',
      'Turkey',
      'Ukraine',
      'United Kingdom',
      'Vatican City'
    ];

    return OverlayContainer(
      show: autoSuggesstion,
      // Let's position this overlay to the right of the button.
      position: OverlayContainerPosition(
          // Left position.
          cursor != null ? cursor.left : 100,
          // Bottom position.
          cursor != null ? cursor.bottom : 100),
      // The content inside the overlay.
      child: Container(
        height: 250,
        width: 200,
        child: ListView.builder(
          itemCount: europeanCountries.length,
          itemBuilder: (context, index) {
            return ListTile(
              title: Text(europeanCountries[index]),
              onTap: () {
                print(europeanCountries[index]);
                _insert(_cec.selection.start, europeanCountries[index]);
              },
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text("Dummy Editor"),
      ),
      body: new Container(
        child: new Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            new Expanded(
              child: new Container(
                padding: new EdgeInsets.all(16.0),
                child: Stack(
                  children: <Widget>[
                    new Container(
                        padding: EdgeInsets.all(24.0),
                        decoration: new BoxDecoration(
                            border: new Border.all(
                                color: Theme.of(context).primaryColor)),
                        child: PageView(
                          children: <Widget>[
                            new CodeTextField(
                              //keyboard type is set to email address in order to
                              //prevent auto text correction after typing.
                              //Since the autoCorrect:false property isn't working, we use this hack here.
                              //https://github.com/flutter/flutter/issues/22828
                              keyboardType: TextInputType.emailAddress,
                              highlighter: PythonHighlighter(),
                              onTap: () {
                                print('onTap');
                              },
                              onRectChanged: ((rect) {
                                print(rect);

                                setState(() {
                                  cursor = rect;
                                });
                              }),
                              onChanged: (t) {
                                lastPosition = _cec.selection.start;
                                lastwordTyped = t
                                    .substring(0, lastPosition)
                                    .split(" ")
                                    .last
                                    .split("\n")
                                    .last;

                                if (!t
                                    .substring(lastPosition - 1, lastPosition)
                                    .contains(" ")) {
                                  if (!t
                                      .substring(lastPosition - 1, lastPosition)
                                      .contains("\n")) {
                                    autoSuggesstion = true;
                                    setState(() {});
                                  } else {
                                    autoSuggesstion = false;
                                    setState(() {});
                                  }
                                } else {
                                  autoSuggesstion = false;
                                  setState(() {});
                                }
                              },
                              controller: _cec,
                              maxLines: null,
                              decoration: null,
                              autofocus: true,
                              style: TextStyle(
                                  fontSize: 16.0, color: Colors.black),
                            ),
                          ],
                        )),
                    _overLayContainer()
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
