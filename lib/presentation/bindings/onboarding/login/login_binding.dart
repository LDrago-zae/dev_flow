import 'package:get/get.dart';
import '../../../view_models/login/login_viewmodel.dart';
// import '../../view_models/auth/login/login_viewmodel.dart';

class LoginBinding extends Bindings {
  @override
  void dependencies() {
    // TODO: implement dependencies
    Get.lazyPut<LoginViewModel>(() => LoginViewModel());
  }
}