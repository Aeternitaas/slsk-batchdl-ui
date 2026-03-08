#include "run_loop.h"

#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include <algorithm>
#include <chrono>

RunLoop::RunLoop() {}

RunLoop::~RunLoop() {}

void RunLoop::Run() {
  bool running = true;
  while (running) {
    running = ProcessNextEvent(true);
  }
}

bool RunLoop::ProcessNextEvent(bool wait_for_event) {
  UINT wait_ms = WaitTimeInMilliseconds();
  if (wait_for_event && wait_ms != 0) {
    MsgWaitForMultipleObjects(0, nullptr, FALSE, wait_ms, QS_ALLINPUT);
  }

  bool processed_event = false;

  if (flutter_instance_) {
    flutter_instance_->engine()->RunTask();
  }

  MSG message;
  while (PeekMessage(&message, nullptr, 0, 0, PM_REMOVE)) {
    if (message.message == WM_QUIT) {
      return false;
    }
    TranslateMessage(&message);
    DispatchMessage(&message);
    processed_event = true;
  }

  return true;
}

UINT RunLoop::WaitTimeInMilliseconds() const {
  if (!flutter_instance_) {
    return INFINITE;
  }
  std::chrono::nanoseconds next_task_time =
      flutter_instance_->engine()->GetNextTaskTargetTime();
  if (next_task_time.count() == 0) {
    return INFINITE;
  }
  auto now = std::chrono::steady_clock::now();
  int64_t remaining_ms =
      std::chrono::duration_cast<std::chrono::milliseconds>(
          std::chrono::nanoseconds(next_task_time) - now.time_since_epoch())
          .count();
  return static_cast<UINT>(std::max(0LL, remaining_ms));
}
