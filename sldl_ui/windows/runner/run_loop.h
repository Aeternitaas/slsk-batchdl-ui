#ifndef RUNNER_RUN_LOOP_H_
#define RUNNER_RUN_LOOP_H_

#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>

#include <functional>

// A runloop that will service both Flutter Engine tasks and Win32 messages.
class RunLoop {
 public:
  RunLoop();
  ~RunLoop();

  // Prevent copying.
  RunLoop(RunLoop const&) = delete;
  RunLoop& operator=(RunLoop const&) = delete;

  // Runs the run loop until the Flutter engine signals a quit.
  void Run();

  // Registers the given flutter::FlutterViewController to receive events.
  void RegisterFlutterInstance(
      flutter::FlutterViewController* flutter_instance) {
    flutter_instance_ = flutter_instance;
  }

  // Unregisters the given flutter::FlutterViewController.
  void UnregisterFlutterInstance(
      flutter::FlutterViewController* flutter_instance) {
    flutter_instance_ = nullptr;
  }

 private:
  bool ProcessNextEvent(bool wait_for_event);
  UINT WaitTimeInMilliseconds() const;

  flutter::FlutterViewController* flutter_instance_ = nullptr;
};

#endif  // RUNNER_RUN_LOOP_H_
