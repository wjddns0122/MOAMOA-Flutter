import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:moamoa/features/schedule/presentation/schedule_navigation.dart';

/// 투표 화면을 끝냅니다.
///
/// - 일정 목록에서 push 로 열렸으면 [result] 를 돌려주며 닫습니다. 목록 갱신은 연 쪽(일정 목록)이 합니다.
/// - 링크 등으로 바로 열려 닫을 화면이 없으면 `pop` 이 실패하므로, 일정 목록으로 이동합니다.
///   [scheduleId] 를 주면 그 일정의 상세도 다시 불러오게 합니다.
void finishVoteScreen(
  BuildContext context,
  WidgetRef ref, {
  required int meetingId,
  int? scheduleId,
  Object? result,
}) {
  if (context.canPop()) {
    context.pop(result);
    return;
  }
  goToScheduleList(context, ref, meetingId: meetingId, scheduleId: scheduleId);
}
