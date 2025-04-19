// test/widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:FocusMate/providers/task_provider.dart';
import 'package:FocusMate/providers/timer_provider.dart';
import 'package:FocusMate/screens/home_screen.dart';
import 'package:FocusMate/models/task_model.dart';
import 'package:FocusMate/widgets/task_item.dart';

void main() {
  testWidgets('App should render the home screen with task lists',
      (WidgetTester tester) async {
    // Build our app and trigger a frame
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => TaskProvider()),
          ChangeNotifierProvider(create: (_) => TimerProvider()),
        ],
        child: const MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );

    // Verify that the title is displayed
    expect(find.text('My Tasks'), findsOneWidget);
    expect(find.text('Pending Tasks'), findsOneWidget);
    expect(find.text('Completed Tasks'), findsOneWidget);

    // Should have the add task button
    expect(find.byIcon(Icons.add), findsOneWidget);
  });

  testWidgets('Task item should display correctly',
      (WidgetTester tester) async {
    final task = Task(
      title: 'Test Task',
      description: 'Test Description',
      pomodoroTime: 25,
      shortBreak: 5,
      longBreak: 15,
      pomodoroCount: 4,
    );

    // Create a test widget with a single task item
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TaskItem(
            task: task,
            onDelete: (String taskId) {
              return null;
            },
            onStart: () {},
          ),
        ),
      ),
    );

    // Verify that the task details are displayed
    expect(find.text('Test Task'), findsOneWidget);
    expect(find.text('Test Description'), findsOneWidget);

    // Should have delete button
    expect(find.byIcon(Icons.delete_outline), findsOneWidget);

    // Should have start button
    expect(find.text('Start'), findsOneWidget);
  });
}
