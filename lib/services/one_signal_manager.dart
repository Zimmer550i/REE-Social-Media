import 'package:app_badge_plus/app_badge_plus.dart';
import 'package:flutter/material.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:ree_social_media_app/utils/app_constants.dart';

class OneSignalHelper {
  static Future<void> initialize() async {
    OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
    OneSignal.Debug.setAlertLevel(OSLogLevel.none);
    OneSignal.initialize(AppConstants.onesignalAppId);
    OneSignal.LiveActivities.setupDefault();

    _initBadgeSupport();

    _addObservers();
  }

  static Future<String?> getPlayerId() async {
    try {
      var playerId = await OneSignal.User.getOnesignalId();
      debugPrint("OneSignal Player ID: $playerId");
      return playerId;
    } catch (e) {
      debugPrint("Error fetching OneSignal Player ID: $e");
      return null;
    }
  }

  static Future<String?> getSubscriptionId() async {
    try {
      final subscriptionId = OneSignal.User.pushSubscription.id;
      debugPrint("OneSignal Subscription ID: $subscriptionId");
      return subscriptionId;
    } catch (e) {
      debugPrint("Error fetching OneSignal Subscription ID: $e");
      return null;
    }
  }

  // Add OneSignal observers for push notifications, user state, etc.
  static void _addObservers() {
    // Push Subscription Observer
    OneSignal.User.pushSubscription.addObserver((state) {
      debugPrint("${OneSignal.User.pushSubscription.optedIn}");
      debugPrint(OneSignal.User.pushSubscription.id);
      debugPrint(OneSignal.User.pushSubscription.token);
      debugPrint(state.current.jsonRepresentation());
    });

    // User State Observer
    OneSignal.User.addObserver((state) {
      var userState = state.jsonRepresentation();
      debugPrint('OneSignal user changed: $userState');
    });

    // Notifications permission observer
    OneSignal.Notifications.addPermissionObserver((state) {
      debugPrint("Has permission $state");
    });

    // Notification Click Listener
    OneSignal.Notifications.addClickListener((event) async {
      debugPrint('NOTIFICATION CLICK LISTENER CALLED WITH EVENT: $event');
    });

    // Foreground Notification Listener
    OneSignal.Notifications.addForegroundWillDisplayListener((event) async {
      debugPrint(
        'NOTIFICATION WILL DISPLAY LISTENER CALLED WITH: ${event.notification.jsonRepresentation()}',
      );

      // Increment iOS badge count
      incrementBadge();

      event.preventDefault();
      event.notification.display();
    });

    // In-App Message Listeners
    OneSignal.InAppMessages.addClickListener((event) {
      debugPrint(
        "In-App Message Clicked: ${event.result.jsonRepresentation()}",
      );
    });
    OneSignal.InAppMessages.addWillDisplayListener((event) {
      debugPrint("Will Display In-App Message: ${event.message.messageId}");
    });
    OneSignal.InAppMessages.addDidDisplayListener((event) {
      debugPrint("Did Display In-App Message: ${event.message.messageId}");
    });
    OneSignal.InAppMessages.addWillDismissListener((event) {
      debugPrint("Will Dismiss In-App Message: ${event.message.messageId}");
    });
    OneSignal.InAppMessages.addDidDismissListener((event) {
      debugPrint("Did Dismiss In-App Message: ${event.message.messageId}");
    });
  }

  // Send Tags to OneSignal
  static void sendTags(Map<String, String> tags) {
    debugPrint("Sending tags");
    OneSignal.User.addTags(tags);
  }

  // Get tags from OneSignal
  static Future<void> getTags() async {
    debugPrint("Getting tags");
    var tags = await OneSignal.User.getTags();
    debugPrint("$tags");
  }

  // Set Email
  static void setEmail(String email) {
    debugPrint("Setting email");
    OneSignal.User.addEmail(email);
  }

  // Remove Email
  static void removeEmail(String email) {
    debugPrint("Removing email");
    OneSignal.User.removeEmail(email);
  }

  // Set SMS Number
  static void setSMSNumber(String smsNumber) {
    debugPrint("Setting SMS Number");
    OneSignal.User.addSms(smsNumber);
  }

  // Remove SMS Number
  static void removeSMSNumber(String smsNumber) {
    debugPrint("Removing SMS Number");
    OneSignal.User.removeSms(smsNumber);
  }

  // Set Location Shared
  static void setLocationShared(bool shared) {
    debugPrint("Setting location shared to $shared");
    OneSignal.Location.setShared(shared);
  }

  // Set External User ID (login)
  static void setExternalUserId(String externalUserId) {
    debugPrint("Setting external user ID");
    OneSignal.login(externalUserId);
  }

  // Logout (remove external user ID)
  static void logout() {
    debugPrint("Logging out");
    OneSignal.logout();
  }

  // Request Push Permission
  static void requestPushPermission() {
    debugPrint("Requesting Push Permission");
    OneSignal.Notifications.requestPermission(true);
  }

  // Provide GDPR Consent
  static void provideConsent(bool consent) {
    debugPrint("Setting consent to $consent");
    OneSignal.consentGiven(consent);
  }

  // Opt-In/Opt-Out for Push Notifications
  static void optIn() {
    debugPrint("Opting in for Push Notifications");
    OneSignal.User.pushSubscription.optIn();
  }

  static void optOut() {
    debugPrint("Opting out of Push Notifications");
    OneSignal.User.pushSubscription.optOut();
  }

  // Handle Live Activities (for iOS, e.g., real-time tracking, status updates)
  static void startLiveActivity(
    String liveActivityId,
    Map<String, dynamic> data,
  ) {
    debugPrint("Starting live activity with ID: $liveActivityId");
    OneSignal.LiveActivities.startDefault(liveActivityId, {
      "title": "Welcome!",
      "message": {"en": "Hello World!"},
    }, data);
  }

  static void enterLiveActivity(String liveActivityId, String token) {
    debugPrint("Entering live activity with ID: $liveActivityId");
    OneSignal.LiveActivities.enterLiveActivity(liveActivityId, token);
  }

  static void exitLiveActivity(String liveActivityId) {
    debugPrint("Exiting live activity with ID: $liveActivityId");
    OneSignal.LiveActivities.exitLiveActivity(liveActivityId);
  }

  // 🔴 iOS App Badge (Independent of OneSignal)
  static bool _isBadgeSupported = false;
 
  static int _badgeCount = 0;
 
  static Future<void> _initBadgeSupport() async {
    // Check if the app badge is supported on the device
    _isBadgeSupported = await AppBadgePlus.isSupported();
    debugPrint("Badge Supported: $_isBadgeSupported");
  }
 
  static void setBadge(int count) {
    _badgeCount = count;
    if (_isBadgeSupported) {
      // Set the badge count
      AppBadgePlus.updateBadge(count);
    }
  }
 
  static void incrementBadge() {
    _badgeCount++;
    if (_isBadgeSupported) {
      // Increment the badge count
      AppBadgePlus.updateBadge(_badgeCount);
    }
  }
 
  static void clearBadge() {
    _badgeCount = 0;
    if (_isBadgeSupported) {
      // Clear the badge count
      AppBadgePlus.updateBadge(0);
    }
  }
 
}
