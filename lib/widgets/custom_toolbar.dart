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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  IconButton(onPressed: (){}, icon: Icon(CupertinoIcons.pen),),
                  IconButton(onPressed: (){}, icon: Icon(CupertinoIcons.bandage_fill),),
                  IconButton(onPressed: (){}, icon: Icon(Icons.undo),),
                  IconButton(onPressed: (){}, icon: Icon(Icons.redo),)
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

}