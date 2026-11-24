import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moamoa/core/errors/api_error_code.dart';
import 'package:moamoa/core/errors/api_exception.dart';
import 'package:moamoa/features/group/domain/entities/member_role.dart';
import 'package:moamoa/features/group/presentation/providers/group_providers.dart';
import 'package:moamoa/features/schedule/domain/entities/schedule.dart';
import 'package:moamoa/features/schedule/domain/entities/schedule_status.dart';
import 'package:moamoa/features/schedule/presentation/pages/schedule_list_page.dart';
import 'package:moamoa/features/schedule/presentation/providers/schedule_providers.dart';
import 'package:moamoa/features/vote/domain/entities/vote_status.dart';
import 'package:moamoa/features/vote/presentation/providers/vote_providers.dart';
import 'package:moamoa/features/vote/presentation/vote_routes.dart';

import '../../../vote/fakes/fake_vote_repository.dart';
import '../../../vote/fakes/vote_fixtures.dart';
import '../../fakes/fake_schedule_repository.dart';

void main() {
  final voting = Schedule(
    id: 7,
    title: '10월 정기 모임',
    startAt: DateTime(2099, 10, 13, 18),
    location: '강남 스터디룸 3호',
    status: ScheduleStatus.voting,
  );

  late FakeScheduleRepository repository;

  setUp(() {
    repository = FakeScheduleRepository(schedules: [voting]);
  });

  /// 일정 목록과 상세·투표 화면 자리를 둡니다.
  /// 투표 화면 대신 확정하고 닫는 버튼과 그냥 닫는 버튼을 둡니다.
  Future<void> pumpList(WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: '/meetings/1/schedules',
      routes: [
        GoRoute(
          path: '/meetings/:meetingId/schedules',
          builder: (_, _) => const ScheduleListPage(meetingId: 1),
          routes: [
            GoRoute(
              path: ':scheduleId',
              builder: (_, _) => const Scaffold(body: Text('일정 상세 화면')),
            ),
          ],
        ),
        GoRoute(
          path: '/meetings/:meetingId/schedule-votes/:scheduleId',
          builder: (context, state) => Scaffold(
            body: Column(
              children: [
                Text('투표 화면 ${state.pathParameters['scheduleId']}'),
                TextButton(
                  onPressed: () => context.pop(),
                  child: const Text('일정 확정 완료'),
                ),
                TextButton(
                  onPressed: () => context.pop(),
                  child: const Text('확정하지 않고 닫기'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [
          scheduleRepositoryProvider.overrideWithValue(repository),
          scheduleAdminProvider.overrideWith((ref, meetingId) => false),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('일정 목록의 투표 중 일정', () {
    testWidgets('투표 중 일정은 날짜 대신 투표 배지와 투표 중 라벨을 보여주고 임시 시작 시각은 숨긴다', (
      tester,
    ) async {
      await pumpList(tester);

      expect(find.text('투표'), findsOneWidget);
      expect(find.text('투표 중'), findsOneWidget);
      expect(find.text('확정'), findsNothing);
      expect(find.textContaining('18:00'), findsNothing);
      expect(find.text('강남 스터디룸 3호'), findsOneWidget);
    });

    testWidgets('투표 중 일정을 누르면 상세 대신 투표 화면으로 이동한다', (tester) async {
      await pumpList(tester);

      await tester.tap(find.text('10월 정기 모임'));
      await tester.pumpAndSettle();

      expect(find.text('투표 화면 7'), findsOneWidget);
    });

    testWidgets('투표 화면에서 확정하고 돌아오면 일정 목록을 다시 불러온다', (tester) async {
      await pumpList(tester);
      await tester.tap(find.text('10월 정기 모임'));
      await tester.pumpAndSettle();
      final before = repository.listCallCount;

      await tester.tap(find.text('일정 확정 완료'));
      await tester.pumpAndSettle();

      expect(repository.listCallCount, greaterThan(before));
    });

    testWidgets('확정하지 않고 돌아와도 일정 목록을 다시 불러온다', (tester) async {
      // 그 사이 다른 관리자가 확정·취소했을 수 있습니다.
      await pumpList(tester);
      await tester.tap(find.text('10월 정기 모임'));
      await tester.pumpAndSettle();
      final before = repository.listCallCount;

      await tester.tap(find.text('확정하지 않고 닫기'));
      await tester.pumpAndSettle();

      expect(repository.listCallCount, greaterThan(before));
    });

    testWidgets('투표가 아닌 일정을 누르면 일정 상세로 이동한다', (tester) async {
      repository.schedules = [
        voting.copyWith(status: ScheduleStatus.confirmed),
      ];
      await pumpList(tester);

      await tester.tap(find.text('10월 정기 모임'));
      await tester.pumpAndSettle();

      expect(find.text('일정 상세 화면'), findsOneWidget);
    });
  });

  group('실제 투표 화면에서 돌아올 때', () {
    testWidgets('다른 관리자가 먼저 확정해 내 확정이 실패한 뒤 돌아와도 목록을 다시 불러와 확정으로 보여준다', (
      tester,
    ) async {
      final votes = FakeVoteRepository(
        vote: sampleVote(),
        responses: sampleResponses(),
      );
      final router = GoRouter(
        initialLocation: '/meetings/1/schedules',
        routes: [
          GoRoute(
            path: '/meetings/:meetingId/schedules',
            builder: (_, _) => const ScheduleListPage(meetingId: 1),
          ),
          ...voteRoutes,
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          retry: (_, _) => null,
          overrides: [
            scheduleRepositoryProvider.overrideWithValue(repository),
            voteRepositoryProvider.overrideWithValue(votes),
            groupMyRoleProvider.overrideWith(
              (ref, groupId) async => MemberRole.admin,
            ),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('10월 정기 모임'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('일정 확정하기'));
      await tester.pumpAndSettle();
      // 시트를 연 사이 다른 관리자가 확정했습니다.
      votes
        ..confirmError = const ApiException(
          code: ApiErrorCode.unprocessableEntity,
          message: '이미 확정된 일정입니다.',
        )
        ..vote = sampleVote(status: VoteStatus.confirmed, votingOpen: false);
      repository.schedules = [
        voting.copyWith(status: ScheduleStatus.confirmed),
      ];
      await tester.tap(find.text('이 시간으로 확정'));
      await tester.pumpAndSettle();
      expect(find.text('이미 확정된 일정입니다.'), findsOneWidget);
      final before = repository.listCallCount;

      await tester.tap(find.byType(IconButton).first);
      await tester.pumpAndSettle();

      expect(find.byType(ScheduleListPage), findsOneWidget);
      expect(repository.listCallCount, greaterThan(before));
      expect(find.text('투표 중'), findsNothing);
      expect(find.text('확정'), findsOneWidget);
    });
  });
}
