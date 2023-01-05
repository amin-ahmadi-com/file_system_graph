import 'dart:io';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:graphist/graph/base/node.dart';
import 'package:graphist/widgets/graph_controller.dart';
import 'package:graphist/widgets/graph_widget.dart';
import 'package:graphist_file_system/file_system_nodes.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:window_manager/window_manager.dart';

import 'details_drawer.dart';
import 'dialog_utils.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WindowListener {
  final gc = GraphController();
  var scaffoldKey = GlobalKey<ScaffoldState>();
  Node? selectedNode;

  @override
  void initState() {
    super.initState();

    windowManager.addListener(this);
    windowManager.setPreventClose(true);
  }

  @override
  void dispose() {
    gc.dispose();
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowClose() async {
    exitPrompt(context);
  }

  final errorFile = File("./errors.log");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        title: const Text("MeSH Graph"),
        // Hide end drawer button
        actions: const [SizedBox()],
      ),
      drawerEnableOpenDragGesture: false,
      endDrawerEnableOpenDragGesture: false,
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(
              child: SizedBox(
                height: 1500,
                child: Center(
                  child: Text(
                    "File System Graph",
                    style: TextStyle(fontSize: 32),
                  ),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.help),
              title: const Text("About"),
              onTap: () => showAboutDialog(
                context: context,
                applicationName: "File System Graph",
                applicationLegalese: "Copyright 2023\nwww.amin-ahmadi.com",
                applicationVersion: "1.0.0",
              ),
            )
          ],
        ),
      ),
      endDrawer: DetailsDrawer(
        node: selectedNode,
        onOpen: () {},
        onCopy: () {
          String data = selectedNode!.uniqueValue;
          Clipboard.setData(ClipboardData(text: data));
          DialogUtils.showSnackBar(
            context,
            "Data copied to clipboard!\n$data",
            Colors.amber,
          );
        },
        onHide: () {
          gc.hideNode(selectedNode!.id);
        },
      ),
      body: DropTarget(
        onDragDone: (d) {
          if (d.files.length != 1 ||
              !FileSystemEntity.isDirectorySync(d.files[0].path)) {
            DialogUtils.showSnackBar(
              context,
              "Drop only a single folder.",
              Colors.deepOrange,
            );
          } else {
            gc.showNode(
              FileSystemFolderNode(d.files[0].path),
              Rect.fromLTWH(
                d.localPosition.dx,
                d.localPosition.dy,
                175,
                50,
              ),
            );
          }
        },
        child: GraphWidget(
          controller: gc,
          onNodeLongPress: (node) {
            if (node.url != null) {
              launchUrl(Uri.parse(node.url!));
            }
          },
          onNodeSecondaryTap: (node) {
            setState(() {
              selectedNode = node;
            });
            scaffoldKey.currentState?.openEndDrawer();
          },
        ),
      ),
    );
  }

  static void exitPrompt(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Do you want to quit exploring?'),
          actions: [
            TextButton(
              child: const Text(
                'No',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text(
                'Sure',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () async {
                Navigator.of(context).pop();
                await windowManager.destroy();
              },
            ),
          ],
        );
      },
    );
  }
}
