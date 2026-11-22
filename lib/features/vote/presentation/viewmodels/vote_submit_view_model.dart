import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moamoa/core/errors/api_exception.dart';

import '../../domain/usecases/submit_my_vote.dart';
import '../providers/vote_providers.dart';
import '../vote_id.dart';
import 'vote_submit_state.dart';
import 'vote_submit_status.dart';

/// 내 투표 제출 ViewModel 입니다. 고른 후보 시간을 [VoteId] 투표의 내 응답으로 제출하고
/// 과정을 [VoteSubmitState] 로 알립니다. (API 5-3)
///
/// 어떤 칸을 골랐는지는 화면 안에서만 쓰는 값이라 여기서 들고 있지 않고, 제출할 때 넘겨받습니다.
/// 제출이 끝나면 내 선택·칸별 가능 인원·응답 인원이 바뀌므로 투표를 다시 불러옵니다.
/// 제출 중에 화면을 닫고 같은 투표를 다시 열어도 이 결과가 새 화면의 조회에 반영되도록, 요청이 끝날 때까지는 autoDispose 를 미룹니다.
class VoteSubmitViewModel extends Notifier<VoteSubmitState> {
  VoteSubmitViewModel({required VoteId id}) : _id = id;

  final VoteId _id;

  @override
  VoteSubmitState build() => const VoteSubmitState();

  /// [meetingTimes] 를 내 응답으로 제출합니다. 비어 있으면 "가능한 시간 없음" 입니다.
  /// 다시 제출하면 이전 선택을 모두 바꿉니다.
  Future<void> submit(List<DateTime> meetingTimes) async {
    if (state.status == VoteSubmitStatus.submitting) return; // 중복 탭 방지
    state = const VoteSubmitState(status: VoteSubmitStatus.submitting);
    // 요청 중에 화면이 닫혀도 서버는 저장합니다. 이 Provider 가 먼저 사라지면 invalidate 를 할 수 없어서,
    // 다시 열린 화면이 저장 전 조회 결과에 남습니다. 요청이 끝날 때까지만 유지합니다.
    final keepAlive = ref.keepAlive();

    try {
      await ref.read(submitMyVoteProvider)(
        SubmitMyVoteParams(
          meetingId: _id.meetingId,
          scheduleId: _id.scheduleId,
          meetingTimes: meetingTimes,
        ),
      );
      if (!ref.mounted) return; // 앱이 종료되는 경우
      ref
        ..invalidate(voteProvider(_id))
        ..invalidate(voteResponsesProvider(_id));
      state = const VoteSubmitState(status: VoteSubmitStatus.success);
    } on ApiException catch (e) {
      if (!ref.mounted) return;
      // 그 사이 마감되거나 확정됐을 수 있어(422) 화면이 지난 투표를 보여주므로 다시 불러옵니다.
      ref.invalidate(voteProvider(_id));
      state = VoteSubmitState(
        status: VoteSubmitStatus.failure,
        errorMessage: e.userMessage,
      );
    } finally {
      keepAlive.close();
    }
  }
}
