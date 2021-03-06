// ignore_for_file: use_key_in_widget_constructors, library_private_types_in_public_api, deprecated_member_use, use_build_context_synchronously

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:notes/models/api_response.dart';
import 'package:notes/models/note_for_listing.dart';
import 'package:notes/services/notes_service.dart';
import 'package:notes/views/note_delete.dart';

import 'note_modify.dart';

class NoteList extends StatefulWidget {
  @override
  _NoteListState createState() => _NoteListState();
}

class _NoteListState extends State<NoteList> {
  NotesService get service => GetIt.I<NotesService>();

  late APIResponse<List<NoteForListing>> _apiResponse;
  bool _isLoading = false;

  String formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  @override
  void initState() {
    _fetchNotes();
    super.initState();
  }

  _fetchNotes() async {
    setState(() {
      _isLoading = true;
    });

    _apiResponse = await service.getNotesList();

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text('List of notes')),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => NoteModify()))
                .then((_) {
              _fetchNotes();
            });
          },
          child: const Icon(Icons.note_add),
        ),
        body: RefreshIndicator(
          triggerMode: RefreshIndicatorTriggerMode.anywhere,
          backgroundColor: Theme.of(context).primaryColor,
          color: Colors.white,
          onRefresh: () async {
            _fetchNotes();
          },
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(
              dragDevices: {
                PointerDeviceKind.touch,
                PointerDeviceKind.mouse,
              },
            ),
            child: Builder(
              builder: (_) {
                if (_isLoading) {
                  return Center(
                      child: CircularProgressIndicator(
                    color: Theme.of(context).primaryColor,
                  ));
                }

                if (_apiResponse.error) {
                  return Center(child: Text(_apiResponse.errorMessage!));
                }

                if (_apiResponse.data!.isEmpty) {
                  return Center(
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 15),
                            child: Text('No Notes in the API',
                                textAlign: TextAlign.center,
                                softWrap: true,
                                style: TextStyle(
                                    color: Theme.of(context).primaryColor,
                                    fontSize: 35)),
                          ),
                          const SizedBox(height: 35),
                          Icon(
                            Icons.nights_stay,
                            color: Theme.of(context).primaryColor,
                            size: 150,
                          ),
                          const SizedBox(height: 35),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 45),
                            child: Text(
                              'Click the Floating Button to create a new note',
                              softWrap: true,
                              style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                  fontSize: 18),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ]),
                  );
                }

                return ListView.separated(
                  separatorBuilder: (_, __) => Divider(
                      height: .5, color: Theme.of(context).primaryColor),
                  itemBuilder: (context, index) {
                    return Dismissible(
                      key: ValueKey(_apiResponse.data![index].noteID),
                      direction: DismissDirection.startToEnd,
                      onDismissed: (direction) {},
                      confirmDismiss: (direction) async {
                        final result = await showDialog(
                            context: context, builder: (_) => NoteDelete());

                        if (result) {
                          final deleteResult = await service
                              .deleteNote(_apiResponse.data![index].noteID!);
                          var message = '';

                          if (deleteResult.data == true) {
                            message = 'The note was deleted successfully';
                          } else {
                            message =
                                deleteResult.errorMessage ?? 'An error occrued';
                          }
                          Scaffold.of(context).showSnackBar(SnackBar(
                              content: Text(message),
                              duration: const Duration(milliseconds: 3000)));

                          return deleteResult.data ?? false;
                        }

                        print(result);
                        return result;
                      },
                      background: Container(
                        color: Colors.red,
                        padding: const EdgeInsets.only(left: 16),
                        child: const Align(
                          alignment: Alignment.centerLeft,
                          child: Icon(Icons.delete, color: Colors.white),
                        ),
                      ),
                      child: ListTile(
                        title: Text(
                          '???? ${_apiResponse.data![index].noteTitle!}',
                          style:
                              TextStyle(color: Theme.of(context).primaryColor),
                        ),
                        subtitle: Text(
                            '??? ??? Last edited on ${formatDateTime(_apiResponse.data![index].latestEditDateTime ?? _apiResponse.data![index].createDateTime!)}'),
                        onLongPress: () {
                          Navigator.of(context)
                              .push(MaterialPageRoute(
                                  builder: (_) => NoteModify(
                                      noteID:
                                          _apiResponse.data![index].noteID!)))
                              .then((data) {
                            print(data);
                            _fetchNotes();
                          });
                        },
                      ),
                    );
                  },
                  itemCount: _apiResponse.data!.length,
                );
              },
            ),
          ),
        ));
  }
}
