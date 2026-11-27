import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'providers/schedule_providers.dart';
import 'schedule_id.dart';

/// 일정 목록 경로입니다. 예: `/meetings/1/schedules` ([scheduleRoutes] 의 목록 route)
String scheduleListPath(int meetingId) => '/meetings/$meetingId/schedules';

/// 다른 기능(투표)의 화면이 이전 화면 없이 열렸다가 끝날 때 일정 목록으로 보냅니다.
///
/// 목록에서 push 로 연 경우에는 목록이 돌아올 때 갱신하지만, 이때는 돌아갈 목록 화면이 없습니다.
/// 그 사이 일정이 생기거나 확정됐을 수 있어 목록(과 [scheduleId] 일정의 상세)을 다시 불러오게 한 뒤 이동합니다.
void goToScheduleList(
  BuildContext context,
  WidgetRef ref, {
  required int meetingId,
  int? scheduleId,
}) {
  ref.invalidate(scheduleListProvider);
  if (scheduleId != null) {
    ref.invalidate(
      scheduleDetailProvider(
        ScheduleId(meetingId: meetingId, scheduleId: scheduleId),
      ),
    );
  }
  context.go(scheduleListPath(meetingId));
}

/// 일정 상세 경로입니다. 예: `/meetings/1/schedules/20` ([scheduleRoutes] 의 상세 route)
String scheduleDetailPath(int meetingId, int scheduleId) =>
    '/meetings/$meetingId/schedules/$scheduleId';

/// 다른 기능(투표)의 화면을 일정 상세로 바꿉니다. 뒤로 가면 그 화면이 아니라 이전 화면(일정 목록)으로 돌아갑니다.
///
/// 일정 상세는 자동으로 버려지지 않아서, 앞서 본 적이 있으면 그 사이 확정된 일시 대신 예전 값을 보여줍니다.
/// 그래서 상세를 다시 불러오게 한 뒤 이동합니다.
void replaceWithScheduleDetail(
  BuildContext context,
  WidgetRef ref, {
  required int meetingId,
  required int scheduleId,
}) {
  ref.invalidate(
    scheduleDetailProvider(
      ScheduleId(meetingId: meetingId, scheduleId: scheduleId),
    ),
  );
  context.pushReplacement(scheduleDetailPath(meetingId, scheduleId));
}
