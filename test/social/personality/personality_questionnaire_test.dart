import 'package:flutter_test/flutter_test.dart';
import 'package:andril_mobile/features/social/personality/domain/entities/personality_questionnaire.dart';

void main() {
  group('PersonalityOption', () {
    test('creates valid option with trimmed fields', () {
      final opt = PersonalityOption(id: ' 1 ', label: ' Option A ');
      expect(opt.id, '1');
      expect(opt.label, 'Option A');
    });

    test('rejects empty or whitespace-only id and label', () {
      expect(
        () => PersonalityOption(id: '', label: 'Valid'),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => PersonalityOption(id: '   ', label: 'Valid'),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => PersonalityOption(id: '1', label: ''),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => PersonalityOption(id: '1', label: '   '),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('serializes to and deserializes from JSON', () {
      final opt = PersonalityOption(id: 'opt-01', label: 'Label 01');
      final json = opt.toJson();
      final fromJson = PersonalityOption.fromJson(json);

      expect(fromJson, equals(opt));
      expect(fromJson.hashCode, equals(opt.hashCode));
    });
  });

  group('PersonalityQuestion', () {
    final validOptions = [
      PersonalityOption(id: '1', label: 'First'),
      PersonalityOption(id: '2', label: 'Second'),
    ];

    test('creates valid question and enforces unmodifiable options', () {
      final q = PersonalityQuestion(
        id: 'q01',
        prompt: 'What do you prefer?',
        isRequired: true,
        options: validOptions,
      );

      expect(q.id, 'q01');
      expect(q.prompt, 'What do you prefer?');
      expect(q.isRequired, isTrue);
      expect(q.options.length, 2);
      expect(() => (q.options as dynamic).add(PersonalityOption(id: '3', label: 'Third')), throwsA(isA<UnsupportedError>()));
    });

    test('rejects empty id, empty prompt, and empty options', () {
      expect(
        () => PersonalityQuestion(id: '', prompt: 'Prompt', options: validOptions),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => PersonalityQuestion(id: 'q01', prompt: '  ', options: validOptions),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => PersonalityQuestion(id: 'q01', prompt: 'Prompt', options: const []),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects duplicate option IDs', () {
      final duplicateOptions = [
        PersonalityOption(id: 'same', label: 'First'),
        PersonalityOption(id: 'same', label: 'Second'),
      ];

      expect(
        () => PersonalityQuestion(id: 'q01', prompt: 'Prompt', options: duplicateOptions),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('serializes to and from JSON', () {
      final q = PersonalityQuestion(
        id: 'q01',
        prompt: 'Valid prompt',
        isRequired: false,
        options: validOptions,
      );
      final json = q.toJson();
      final fromJson = PersonalityQuestion.fromJson(json);

      expect(fromJson, equals(q));
      expect(fromJson.hashCode, equals(q.hashCode));
    });
  });

  group('PersonalityQuestionnaire', () {
    final sampleQuestions = [
      PersonalityQuestion(
        id: 'q01',
        prompt: 'Question 1',
        isRequired: true,
        options: [
          PersonalityOption(id: '1', label: 'Opt 1'),
          PersonalityOption(id: '2', label: 'Opt 2'),
        ],
      ),
      PersonalityQuestion(
        id: 'q02',
        prompt: 'Question 2',
        isRequired: false,
        options: [
          PersonalityOption(id: '1', label: 'Opt 1'),
        ],
      ),
    ];

    test('creates valid questionnaire with unmodifiable questions list', () {
      final questionnaire = PersonalityQuestionnaire(
        version: 'v1.0',
        questions: sampleQuestions,
      );

      expect(questionnaire.version, 'v1.0');
      expect(questionnaire.totalQuestions, 2);
      expect(questionnaire.requiredQuestionsCount, 1);
      expect(() => (questionnaire.questions as dynamic).add(sampleQuestions.first), throwsA(isA<UnsupportedError>()));
    });

    test('rejects empty version, empty questions, and duplicate question IDs', () {
      expect(
        () => PersonalityQuestionnaire(version: '', questions: sampleQuestions),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => PersonalityQuestionnaire(version: 'v1.0', questions: const []),
        throwsA(isA<ArgumentError>()),
      );
      final duplicateQuestions = [
        sampleQuestions.first,
        sampleQuestions.first,
      ];
      expect(
        () => PersonalityQuestionnaire(version: 'v1.0', questions: duplicateQuestions),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('serializes to and from JSON', () {
      final questionnaire = PersonalityQuestionnaire(
        version: 'v1.0',
        questions: sampleQuestions,
      );
      final json = questionnaire.toJson();
      final fromJson = PersonalityQuestionnaire.fromJson(json);

      expect(fromJson, equals(questionnaire));
      expect(fromJson.hashCode, equals(questionnaire.hashCode));
    });
  });

  group('PersonalityAnswerDraft', () {
    final questionnaire = PersonalityQuestionnaire(
      version: 'v1.0',
      questions: [
        PersonalityQuestion(
          id: 'q01',
          prompt: 'Question 1',
          isRequired: true,
          options: [
            PersonalityOption(id: '1', label: 'Opt 1'),
            PersonalityOption(id: '2', label: 'Opt 2'),
          ],
        ),
        PersonalityQuestion(
          id: 'q02',
          prompt: 'Question 2',
          isRequired: true,
          options: [
            PersonalityOption(id: '1', label: 'Opt 1'),
          ],
        ),
        PersonalityQuestion(
          id: 'q03',
          prompt: 'Optional Question 3',
          isRequired: false,
          options: [
            PersonalityOption(id: '1', label: 'Opt 1'),
          ],
        ),
      ],
    );

    test('initializes empty draft and calculates progress correctly', () {
      final draft = PersonalityAnswerDraft(questionnaireVersion: 'v1.0');
      expect(draft.answers, isEmpty);
      expect(draft.completionProgress(questionnaire), 0.0);
      expect(draft.isCompleteFor(questionnaire), isFalse);
    });

    test('sets and updates answers immutably', () {
      var draft = PersonalityAnswerDraft(questionnaireVersion: 'v1.0');
      draft = draft.setAnswer(questionId: 'q01', optionId: '1');

      expect(draft.answers['q01'], '1');
      expect(draft.completionProgress(questionnaire), closeTo(1 / 3, 0.01));
      expect(draft.isCompleteFor(questionnaire), isFalse);

      draft = draft.setAnswer(questionId: 'q02', optionId: '1');
      expect(draft.answers['q02'], '1');
      expect(draft.completionProgress(questionnaire), closeTo(2 / 3, 0.01));
      // All required questions answered, so complete!
      expect(draft.isCompleteFor(questionnaire), isTrue);

      // Remove an answer
      draft = draft.removeAnswer('q01');
      expect(draft.answers.containsKey('q01'), isFalse);
      expect(draft.isCompleteFor(questionnaire), isFalse);
    });

    test('rejects completion if version mismatch occurs', () {
      final draft = PersonalityAnswerDraft(
        questionnaireVersion: 'v0.9-outdated',
        answers: {'q01': '1', 'q02': '1'},
      );
      expect(draft.isCompleteFor(questionnaire), isFalse);
    });

    test('rejects completion if selected option is not defined in question', () {
      final draft = PersonalityAnswerDraft(
        questionnaireVersion: 'v1.0',
        answers: {'q01': 'non_existent_option', 'q02': '1'},
      );
      expect(draft.isCompleteFor(questionnaire), isFalse);
    });

    test('masks answers in toString diagnostics for user privacy', () {
      final draft = PersonalityAnswerDraft(
        questionnaireVersion: 'v1.0',
        answers: {'q01': 'secret_1', 'q02': 'secret_2'},
      );
      final diagnostic = draft.toString();
      expect(diagnostic.contains('secret_1'), isFalse);
      expect(diagnostic.contains('secret_2'), isFalse);
      expect(diagnostic.contains('answeredCount: 2'), isTrue);
    });
  });
}
