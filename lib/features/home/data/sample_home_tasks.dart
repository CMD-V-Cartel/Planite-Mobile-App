import 'package:cursor_hack/features/home/models/task_appointment.dart';
import 'package:flutter/material.dart';

List<TaskAppointment> buildSampleTasksForDay(DateTime day) {
  DateTime at(int hour, [int minute = 0]) =>
      DateTime(day.year, day.month, day.day, hour, minute);

  return <TaskAppointment>[
    TaskAppointment(
      startTime: at(8),
      endTime: at(9),
      subject: 'Research new project',
      color: const Color(0xFF9B8CFF),
    ),
    TaskAppointment(
      startTime: at(9, 30),
      endTime: at(10, 30),
      subject: 'Design onboarding',
      color: const Color(0xFF4A90E2),
      isCompleted: true,
    ),
    TaskAppointment(
      startTime: at(11),
      endTime: at(12),
      subject: 'Learn Webflow',
      color: const Color(0xFF5FD4A8),
    ),
    TaskAppointment(
      startTime: at(12, 30),
      endTime: at(13),
      subject: 'Lunch break',
      color: const Color(0xFF4CAF50),
    ),
    TaskAppointment(
      startTime: at(15, 30),
      endTime: at(16, 30),
      subject: 'Report progress with client',
      color: const Color(0xFF5FD4A8),
    ),
  ];
}
