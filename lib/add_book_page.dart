import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class BookAdd extends StatefulWidget {
  @override
  _BookAddState createState() => _BookAddState();
}

class _BookAddState extends State<BookAdd> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _authorController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  XFile? _image;

  Future<void> _pickImage() async {
    final pickedImage = await _picker.pickImage(source: ImageSource.gallery);
    setState(() {
      _image = pickedImage;
    });
  }

  bool submitBook() {
    if (_titleController.text.isEmpty ||
        _authorController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _image == null) {
      return false;
    }
    // Add code here to handle the case when all fields are filled and the image is selected
    return true;
  }

  void _handleSubmit() {
    if (submitBook()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Book submitted successfully!'),
          action: SnackBarAction(
            label: 'OK',
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill all fields and select an image.'),
          action: SnackBarAction(
            label: 'OK',
            onPressed: () {
              // Do nothing, just close the SnackBar
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add New Book'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Book Title',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _authorController,
              decoration: InputDecoration(
                labelText: 'Author',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _pickImage,
              child: Text('Select Image'),
            ),
            SizedBox(height: 10),
            _image == null
                ? Text('No image selected.')
                : Image.file(File(_image!.path)),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _handleSubmit,
              child: Text('Submit Book'),
            ),
          ],
        ),
      ),
    );
  }
}
