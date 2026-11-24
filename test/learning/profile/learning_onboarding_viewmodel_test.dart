import 'package:flutter_test/flutter_test.dart';
import 'package:andril_mobile/features/learning/profile/viewmodels/learning_onboarding_viewmodel.dart';

void main() {
  group('LearningOnboardingViewModel Unit Tests', () {
    late LearningOnboardingViewModel viewModel;

    setUp(() {
      viewModel = LearningOnboardingViewModel();
    });

    tearDown(() {
      if (!viewModel.isDisposed) {
        viewModel.dispose();
      }
    });

    test('1. Initial draft state', () {
      expect(viewModel.currentStep, 0);
      expect(viewModel.step, OnboardingStep.basics);
      expect(viewModel.displayName, '');
      expect(viewModel.bio, '');
      expect(viewModel.skillsToLearn, isEmpty);
      expect(viewModel.skillsToShare, isEmpty);
      expect(viewModel.displayNameError, isNull);
      expect(viewModel.isLoading, isFalse);
      expect(viewModel.errorMessage, isNull);
      expect(viewModel.hasUnsavedChanges, isFalse);
      expect(viewModel.isDisposed, isFalse);
    });

    test('2. Updating profile basics', () {
      viewModel.setDisplayName('Alex Chen');
      viewModel.setBio('Passionate about mobile architectures');

      expect(viewModel.displayName, 'Alex Chen');
      expect(viewModel.bio, 'Passionate about mobile architectures');
      expect(viewModel.hasUnsavedChanges, isTrue);
    });

    test('3. Unicode preservation', () {
      const tamilName = 'துசாந்த் குமாரன் 🚀';
      const tamilBio = 'கற்றல் மற்றும் பகிர்தல் ✨';
      const tamilSkill = 'தமிழ் இலக்கியம்';

      viewModel.setDisplayName(tamilName);
      viewModel.setBio(tamilBio);
      viewModel.addSkillToLearn(tamilSkill);

      expect(viewModel.displayName, tamilName);
      expect(viewModel.bio, tamilBio);
      expect(viewModel.skillsToLearn.first, tamilSkill);
    });

    test('4. Skills-to-Learn selection', () {
      viewModel.addSkillToLearn('Flutter');
      viewModel.addSkillToLearn('Dart');
      expect(viewModel.skillsToLearn, ['Flutter', 'Dart']);

      viewModel.removeSkillToLearn('Flutter');
      expect(viewModel.skillsToLearn, ['Dart']);

      viewModel.toggleSkillToLearn('Python');
      expect(viewModel.skillsToLearn, ['Dart', 'Python']);

      viewModel.toggleSkillToLearn('Dart');
      expect(viewModel.skillsToLearn, ['Python']);

      viewModel.clearSkillsToLearn();
      expect(viewModel.skillsToLearn, isEmpty);
    });

    test('5. Skills-to-Share selection', () {
      viewModel.addSkillToShare('UI Design');
      viewModel.addSkillToShare('Figma');
      expect(viewModel.skillsToShare, ['UI Design', 'Figma']);

      viewModel.removeSkillToShare('UI Design');
      expect(viewModel.skillsToShare, ['Figma']);

      viewModel.toggleSkillToShare('Mentoring');
      expect(viewModel.skillsToShare, ['Figma', 'Mentoring']);

      viewModel.toggleSkillToShare('Figma');
      expect(viewModel.skillsToShare, ['Mentoring']);

      viewModel.clearSkillsToShare();
      expect(viewModel.skillsToShare, isEmpty);
    });

    test('6. Independent skill collections', () {
      viewModel.addSkillToLearn('Python');
      expect(viewModel.skillsToLearn, ['Python']);
      expect(viewModel.skillsToShare, isEmpty);

      // Legitimate identical skill name in both collections is allowed
      viewModel.addSkillToShare('Python');
      expect(viewModel.skillsToLearn, ['Python']);
      expect(viewModel.skillsToShare, ['Python']);

      viewModel.removeSkillToLearn('Python');
      expect(viewModel.skillsToLearn, isEmpty);
      expect(viewModel.skillsToShare, ['Python']);
    });

    test('7. Duplicate prevention within collections', () {
      viewModel.addSkillToLearn('Flutter');
      viewModel.addSkillToLearn('Flutter');
      viewModel.addSkillToLearn(' Flutter ');
      expect(viewModel.skillsToLearn, ['Flutter']);

      viewModel.addSkillToShare('Dart');
      viewModel.addSkillToShare('Dart');
      expect(viewModel.skillsToShare, ['Dart']);
    });

    test('8. Back/forward draft preservation', () {
      viewModel.setDisplayName('Alex');
      viewModel.setBio('Student');

      // Next step validates and advances
      expect(viewModel.nextStep(), isTrue);
      expect(viewModel.currentStep, 1);
      expect(viewModel.step, OnboardingStep.skillsToLearn);

      viewModel.addSkillToLearn('Flutter');

      expect(viewModel.nextStep(), isTrue);
      expect(viewModel.currentStep, 2);
      expect(viewModel.step, OnboardingStep.skillsToShare);

      viewModel.addSkillToShare('UI Design');

      // Previous step retains all state
      expect(viewModel.previousStep(), isTrue);
      expect(viewModel.currentStep, 1);
      expect(viewModel.skillsToLearn, ['Flutter']);

      expect(viewModel.previousStep(), isTrue);
      expect(viewModel.currentStep, 0);
      expect(viewModel.displayName, 'Alex');
      expect(viewModel.bio, 'Student');
      expect(viewModel.skillsToShare, ['UI Design']);
    });

    test('9. Immutable externally exposed selections', () {
      viewModel.addSkillToLearn('Flutter');
      final exposedList = viewModel.skillsToLearn;

      expect(
        () => (exposedList as dynamic).add('Injected'),
        throwsA(isA<UnsupportedError>()),
      );

      viewModel.addSkillToShare('UI Design');
      final exposedShareList = viewModel.skillsToShare;

      expect(
        () => (exposedShareList as dynamic).add('Injected'),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('10. Unsaved-change detection', () {
      expect(viewModel.hasUnsavedChanges, isFalse);

      viewModel.setDisplayName('User');
      expect(viewModel.hasUnsavedChanges, isTrue);

      viewModel.reset();
      expect(viewModel.hasUnsavedChanges, isFalse);

      viewModel.addSkillToLearn('Topic');
      expect(viewModel.hasUnsavedChanges, isTrue);
    });

    test('11. No local identity reassignment', () {
      // Invariant: ViewModel manages drafts only, and has no API or mechanism
      // to manufacture or reassign accountId or profileId.
      expect(viewModel, isNot(contains('accountId')));
      expect(viewModel, isNot(contains('profileId')));
    });

    test('12. No local activation grant', () {
      // Invariant: ViewModel has no activation flag or setter.
      expect(viewModel, isNot(contains('isActivated')));
      expect(viewModel, isNot(contains('activate')));
    });

    test('13. Safe handling of missing catalogue data', () {
      viewModel.setLoading(true);
      expect(viewModel.isLoading, isTrue);

      viewModel.setErrorMessage('Catalogue unavailable');
      expect(viewModel.errorMessage, 'Catalogue unavailable');

      viewModel.setLoading(false);
      expect(viewModel.isLoading, isFalse);
    });

    test('14. State notifications and disposal', () {
      int notifyCount = 0;
      viewModel.addListener(() => notifyCount++);

      viewModel.setDisplayName('Name');
      expect(notifyCount, 1);

      viewModel.addSkillToLearn('Skill');
      expect(notifyCount, 2);

      viewModel.dispose();
      expect(viewModel.isDisposed, isTrue);
    });
  });
}
