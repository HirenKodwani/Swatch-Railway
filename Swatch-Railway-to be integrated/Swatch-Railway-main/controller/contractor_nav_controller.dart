import 'package:get/get.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';

class ContractorNavController extends GetxController {
  late PersistentTabController tabController;

  var formStatusFilter = Rx<String?>(null);
  var formsInnerTabIndex = Rx<int?>(null);

  @override
  void onInit() {
    tabController = PersistentTabController(initialIndex: 0);
    super.onInit();
  }

  void changeTab(int index) {
    tabController.index = index;
    update();
  }

  void navigateToFormsWithStatus(String status) {
    formStatusFilter.value = status;
    tabController.index = 1;
    update();
  }

  void navigateToFormsTab(int innerTabIndex) {
    formsInnerTabIndex.value = innerTabIndex; // Set CTS tab index
    tabController.index = 1; // Navigate to Forms screen
    update();
  }

  void clearFormStatusFilter() {
    formStatusFilter.value = null;
  }

  void clearFormsInnerTabIndex() {
    formsInnerTabIndex.value = null;
  }
}
