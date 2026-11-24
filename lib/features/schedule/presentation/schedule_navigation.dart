import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'providers/schedule_providers.dart';

/// 일정 목록 경로입니다. 예: `/meetings/1/schedules` ([scheduleRoutes] 의 목록 route)
String scheduleListPath(int meetingId) => '/meetings/$meetingId/schedules';

/// 다른 기능(투표)의 화면이 이전 화면 없이 열렸다가 끝날 때 일정 목록으로 보냅니다.
///
/// 목록에서 push 로 연 경우에는 목록이 돌려받은 결과를 보고 갱신하지만, 이때는 결과를 받을 화면이 없습니다.
/// 그 사이 일정이 생겼을 수 있어 목록을 다시 불러오게 한 뒤 이동합니다.
void goToScheduleList(
  BuildContext context,
  WidgetRef ref, {
  required int meetingId,
}) {
  ref.invalidate(scheduleListProvider);
  context.go(scheduleListPath(meetingId));
}
