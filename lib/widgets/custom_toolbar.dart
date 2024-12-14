import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class customToolbar extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      appBar: AppBar(
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(100),
            )
          ],
        ),
      ),
    );
  }

}