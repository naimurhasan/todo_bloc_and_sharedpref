import 'package:todo_list_app/features/todo/domain/model/Todo.dart';
import 'package:todo_list_app/features/todo/presentation/bloc/TodoCubit.dart';
import 'package:todo_list_app/features/todo/presentation/bloc/TodoState.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:todo_list_app/features/todo/presentation/widget/AddTodoBottomSheet.dart';
import 'package:todo_list_app/features/todo/presentation/widget/TaskView.dart';

class TodoView extends StatelessWidget {
  const TodoView({super.key});

  @override
  Widget build(BuildContext context) {
    return const TodoViewBody();
  }
}

class TodoViewBody extends StatefulWidget {
  const TodoViewBody({super.key});

  @override
  _TodoViewBodyState createState() => _TodoViewBodyState();
}

class _TodoViewBodyState extends State<TodoViewBody> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

  @override
  void initState() {
    super.initState();
    BlocProvider.of<TodoCubit>(context).initial();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ToDos'),
      ),
      body: BlocBuilder<TodoCubit, TodoState>(
        builder: (context, state) {
          if (state is TodoInitial) {
            return _initialView();
          } else if (state is TodoLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is TodoLoaded) {
            return _loadedView(state);
          } else {
            return _errorView();
          }
        },
      ),
      floatingActionButton: _addButton(context),
    );
  }

  FloatingActionButton _addButton(BuildContext context) {
    return FloatingActionButton(
      child: const Icon(Icons.add),
      onPressed: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (dialogContext) {
            return BlocProvider.value(
              value: BlocProvider.of<TodoCubit>(context),
              child: Padding(
                padding: MediaQuery.of(dialogContext).viewInsets,
                child: AddTodoBottomSheet(
                  onAdd: (title, description) async {
                    final todoCubit = BlocProvider.of<TodoCubit>(context);
                    await todoCubit.add(title, description);
                    if (todoCubit.state is TodoLoaded) {
                      _listKey.currentState?.insertItem(
                        (todoCubit.state as TodoLoaded).todo.length - 1,
                      );
                    }
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  Center _initialView() {
    return const Center(child: Text("Initial"));
  }

  Center _errorView() {
    return const Center(child: Text("Error"));
  }

  Widget _loadedView(TodoLoaded state) {
    return AnimatedList(
      key: _listKey,
      initialItemCount: state.todo.length,
      itemBuilder: (context, index, animation) {
        final item = state.todo[index];
        return _buildItem(item, index, animation);
      },
    );
  }

  Widget _buildItem(Todo item, int index, Animation<double> animation) {
    return SizeTransition(
      sizeFactor: animation,
      child: TaskView(
        index: index,
        todo: item,
        onDelete: () async {
          await BlocProvider.of<TodoCubit>(context).delete(index);
          _listKey.currentState?.removeItem(
            index,
            (context, animation) {
              return SizeTransition(
                sizeFactor: animation,
                child: TaskView(
                  index: index,
                  todo: item,
                  onDelete: () async {
                    await BlocProvider.of<TodoCubit>(context).delete(index);
                    _listKey.currentState?.removeItem(
                      index,
                      (context, animation) {
                        return _buildItem(
                            item, index, animation); // Animate removal
                      },
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
