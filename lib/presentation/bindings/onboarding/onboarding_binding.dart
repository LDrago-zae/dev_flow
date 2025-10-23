import 'package:get/get.dart';
import '../../view_models/onboarding/onboarding_viewmodel.dart';

class OnboardingBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<OnboardingViewModel>(() => OnboardingViewModel());
  }
}
