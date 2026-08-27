import 'package:family_brain/core/brain/ai/family_brain_ai_schema.dart';
import 'package:family_brain/core/brain/ai/family_brain_ai_service.dart';
import 'package:family_brain/core/brain/ai/family_brain_context.dart';
import 'package:family_brain/core/brain/ai/ai_provider.dart';
import 'package:family_brain/core/brain/assignment_resolver.dart';
import 'package:family_brain/core/brain/civil_datetime.dart';
import 'package:family_brain/core/brain/family_brain_parser.dart';
import 'package:family_brain/domain/models/app_user.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 8, 26, 10, 0); // Wednesday
  final maya = AppUser(
    id: 'maya',
    name: 'Maya',
    phone: '+1',
    language: 'en',
    createdAt: now,
    familyId: 'fam',
  );
  final david = AppUser(
    id: 'david',
    name: 'David',
    phone: '+2',
    language: 'en',
    createdAt: now,
    familyId: 'fam',
  );

  group('civil dates stay on the intended calendar day', () {
    test('YYYY-MM-DD is a local date even if parse would be UTC', () {
      final due = CivilDateTime.combine('2026-08-25', '18:00', now);
      expect(due, DateTime(2026, 8, 25, 18, 0));
      expect(
        FamilyBrainAiAction.combineDateTime(
          '2026-08-25T00:00:00.000Z',
          '09:30',
          now,
        ),
        DateTime(2026, 8, 25, 9, 30),
      );
    });
  });

  group('relative dates and times', () {
    test('tonight and this evening resolve to today 19:00', () {
      expect(
        FamilyBrainParser.parse('Call mom tonight', now: now).draft!.dueDate,
        DateTime(2026, 8, 26, 19, 0),
      );
      expect(
        FamilyBrainParser.parse('Call mom this evening', now: now)
            .draft!
            .dueDate,
        DateTime(2026, 8, 26, 19, 0),
      );
    });

    test('tomorrow morning and next week', () {
      expect(
        FamilyBrainParser.parse('Pay the bill tomorrow morning', now: now)
            .draft!
            .dueDate,
        DateTime(2026, 8, 27, 9, 0),
      );
      expect(
        FamilyBrainParser.parse('Clean the garage next week', now: now)
            .draft!
            .dueDate,
        DateTime(2026, 9, 2),
      );
    });

    test('Friday is this week; next Friday is the following week', () {
      final friday = FamilyBrainParser.parse(
        'Submit the form Friday',
        now: now,
      ).draft!.dueDate!;
      expect(friday, DateTime(2026, 8, 28));
      final nextFriday = FamilyBrainParser.parse(
        'Submit the form next Friday',
        now: now,
      ).draft!.dueDate!;
      expect(nextFriday, DateTime(2026, 9, 4));
    });

    test('at 8 PM is 20:00 and evening at 8 is 20:00', () {
      expect(
        FamilyBrainParser.parse('Call dad at 8 PM', now: now).draft!.dueDate,
        DateTime(2026, 8, 26, 20, 0),
      );
      expect(
        FamilyBrainParser.parse('Call dad tonight at 8', now: now)
            .draft!
            .dueDate,
        DateTime(2026, 8, 26, 20, 0),
      );
    });

    test('in two hours keeps the current clock', () {
      expect(
        FamilyBrainParser.parse('Call the school in 2 hours', now: now)
            .draft!
            .dueDate,
        DateTime(2026, 8, 26, 12, 0),
      );
    });

    test('Hebrew eight in the evening is 20:00', () {
      expect(
        FamilyBrainParser.parse('יוסי יוצא בשעה שמונה', now: now)
            .draft!
            .dueDate!
            .hour,
        20,
      );
    });
  });

  group('assignment', () {
    test('named member is assigned and not invented', () {
      final draft = FamilyBrainParser.parse(
        'Maya needs to buy milk tomorrow',
        now: now,
        members: [maya, david],
      ).draft!;
      expect(draft.assigneeId, 'maya');
      expect(draft.personal, isFalse);
    });

    test('I need to stays personal and assigned to the current user', () {
      final draft = FamilyBrainParser.parse(
        'I need to finish the report tomorrow',
        now: now,
        members: [maya, david],
        currentUser: maya,
      ).draft!;
      expect(draft.personal, isTrue);
      expect(draft.assigneeId, 'maya');
    });

    test('everyone is family-wide with no assignee', () {
      final draft = FamilyBrainParser.parse(
        'Everyone needs to pack for the trip',
        now: now,
        members: [maya, david],
        currentUser: maya,
      ).draft!;
      expect(draft.personal, isFalse);
      expect(draft.assigneeId, isNull);
      expect(
        AssignmentResolver.resolve(
          text: 'כולם צריכים לנקות',
          members: [
            FamilyBrainMemberRef.fromAppUser(maya),
            FamilyBrainMemberRef.fromAppUser(david),
          ],
        ).familyWide,
        isTrue,
      );
    });

    test('similar names stay ambiguous instead of guessing', () {
      final decision = AssignmentResolver.resolve(
        text: 'Ask Alex to call the school',
        members: const [
          FamilyBrainMemberRef(id: 'alex-a', name: 'Alex Cohen'),
          FamilyBrainMemberRef(id: 'alex-b', name: 'Alex Levi'),
        ],
      );
      expect(decision.ambiguous, isTrue);
      expect(decision.assigneeId, isNull);
    });

    test('unknown names are not invented as members', () {
      final draft = FamilyBrainParser.parse(
        'Uncle Bob needs to pick up the cake',
        now: now,
        members: [maya, david],
      ).draft!;
      expect(draft.assigneeId, isNull);
    });
  });

  group('AI service speed path', () {
    test('local fallback is ready without waiting after a failed cloud call',
        () async {
      final service = FamilyBrainAiService(provider: _FailingProvider());
      final started = DateTime.now();
      final result = await service.understandResult(
        input: const FamilyBrainInput(text: 'Buy milk, bread and eggs.'),
        context: FamilyBrainContext.fromApp(now: now, members: [maya]),
      );
      expect(DateTime.now().difference(started).inMilliseconds, lessThan(400));
      expect(result.usedFallback, isTrue);
      expect(result.response.hasCreateActions, isTrue);
    });
  });

  group('shared content extraction', () {
    test('shared message keeps named assignment and stated time', () {
      final draft = FamilyBrainParser.parse(
        'Maya: Please pick up the kids tomorrow at 5 PM',
        now: now,
        members: [maya, david],
        currentUser: david,
      ).draft!;
      expect(draft.assigneeId, 'maya');
      expect(draft.dueDate, DateTime(2026, 8, 27, 17, 0));
      expect(draft.originalText, contains('pick up the kids'));
    });

    test('android share source is included in the AI payload', () {
      final payload = FamilyBrainContext.fromApp(
        now: now,
        members: [maya, david],
        currentUser: david,
        source: 'android_share',
      ).toProviderPayload();
      expect(payload['source'], 'android_share');
      expect(payload['currentUser'], isNotNull);
    });
  });
}

class _FailingProvider implements AiProvider {
  @override
  String get id => 'fail';

  @override
  Future<FamilyBrainAiResponse> interpret({
    required FamilyBrainInput input,
    required FamilyBrainContext context,
  }) async {
    throw Exception('ai_failed');
  }
}
