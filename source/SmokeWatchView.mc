using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.System;
using Toybox.Lang;
using Toybox.Graphics;
using Toybox.ActivityMonitor;
using Toybox.Time;

class SmokeWatchAnimationDelegate extends WatchUi.AnimationDelegate {
    var owner = null;
    var isStateActive = false;

    function initialize(owner, isStateActive) {
        System.println(">>> SmokeWatchAnimationDelegate.initialize: begin, isStateActive = " + isStateActive);
        self.owner = owner;
        self.isStateActive = isStateActive;

        WatchUi.AnimationDelegate.initialize();
        System.println(">>> SmokeWatchAnimationDelegate.initialize: end");
    }

    function onAnimationEvent(event, options) {
        System.println(">>> SmokeWatchAnimationDelegate.onAnimationEvent: begin, event = " + event + ", options = " + options);

        if (event == WatchUi.ANIMATION_EVENT_COMPLETE) {
            owner.onAnimationComplete(isStateActive);
        }

        System.println(">>> SmokeWatchAnimationDelegate.onAnimationEvent: end");
    }
}

class SmokeWatchView extends WatchUi.WatchFace {
    const ICON_BATTERY = "0";
    const ICON_BATTERY_CHARGING = "1";
    const ICON_PHONE_CONNECTED = "2";
    const ICON_NOTIFICATIONS = "3";
    const ICON_HEART = "4";
    const ICON_STEPS = "5";
    const ICON_CALORIES = "6";
    const ICON_FLOORS = "7";
    const ICON_ACTIVITY = "8";
    const ICON_DND = "9";

    var screenWidth = 0;
    var screenHeight = 0;
    var screenCenterX = 0;
    var screenCenterY = 0;
    var screenPaddingLeft = 0;
    var screenPaddingRight = 0;
    var screenPaddingVert = 0;
    var timeFont = null;
    var infoFont = null;
    var iconFont = null;
    var infoLineHeight = 0;
    var iconSize = 0;
    var bottomInfoY = 0;
    var batteryProgressOffsetX = 0;
    var batteryProgressOffsetY = 0;
    var batteryProgressWidth = 0;
    var batteryProgressHeight = 0;
    var iconSpacingHor = 0;
    var iconTextOffsetX = 2;
    var iconTextOffsetY = -1;
    var enterLayer = null;
    var leaveLayer = null;
    var faceLayer = null;

    var isViewShown = false;
    var isViewActive = false;
    var animationState = :empty;
    var ignoreAnimationCompleteCounter = 0;

    var currentHours = "";
    var currentMinutes = "";
    var currentDate = "";
    var currentPhoneConnected = false;
    var currentNotificationsCount = 0;
    var currentDnd = false;
    var currentBatteryLevel = null;
    var currentBatteryCharging = false;
    var currentSteps = null;
    var currentCalories = null;
    var currentFloors = null;
    var currentActivity = null;
    var currentHeartRate = null;

    var lastHours = "";
    var lastMinutes = "";
    var lastDate = "";
    var lastPhoneConnected = false;
    var lastNotificationsCount = 0;
    var lastDnd = false;
    var lastBatteryLevel = null;
    var lastBatteryCharging = false;
    var lastSteps = null;
    var lastCalories = null;
    var lastFloors = null;
    var lastActivity = null;
    var lastHeartRate = null;

    function initialize() {
        System.println(">>> SmokeWatchView.initialize: begin");
        WatchFace.initialize();
        System.println(">>> SmokeWatchView.initialize: end");
    }

    function onLayout(dc) {
        System.println(">>> SmokeWatchView.onLayout: begin");

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        var settings = System.getDeviceSettings();
        screenWidth = settings.screenWidth;
        screenHeight = settings.screenHeight;
        screenCenterX = screenWidth * 0.5;
        screenCenterY = screenHeight * 0.5;
        screenPaddingLeft = screenWidth * 0.075;
        screenPaddingRight = screenWidth * 0.05;
        screenPaddingVert = screenHeight * 0.075;

        timeFont = WatchUi.loadResource(Rez.Fonts.RobotoLight);
        infoFont = WatchUi.loadResource(Rez.Fonts.Roboto);
        iconFont = WatchUi.loadResource(Rez.Fonts.Icons);

        infoLineHeight = Graphics.getFontHeight(infoFont);
        iconSize = Graphics.getFontHeight(iconFont);
        bottomInfoY = screenHeight - screenPaddingVert - iconSize;

        if (iconSize >= 16) {
            batteryProgressOffsetX = 5;
            batteryProgressOffsetY = 4;
            batteryProgressWidth = 6;
            batteryProgressHeight = 10;
            iconSpacingHor = 4;
        } else {
            batteryProgressOffsetX = 5;
            batteryProgressOffsetY = 5;
            batteryProgressWidth = 5;
            batteryProgressHeight = 10;
            iconSpacingHor = 2;
        }

        faceLayer = new WatchUi.Layer({
            :locX => 0,
            :locY => 0,
            :width => screenWidth,
            :height => screenHeight
        });

        addLayer(faceLayer);

        System.println(">>> SmokeWatchView.onLayout: end");
        return true;
    }

    function onShow() {
        System.println(">>> SmokeWatchView.onShow: begin");

        if (enterLayer == null) {
            enterLayer = setupAnimationLayer(null, Rez.Drawables.enter);
        }

        if (leaveLayer == null) {
            leaveLayer = setupAnimationLayer(null, Rez.Drawables.leave);
        }

        isViewShown = true;
        isViewActive = true;
        startAnimation();

        System.println(">>> SmokeWatchView.onShow: end");
        return true;
    }

    function onHide() {
        System.println(">>> SmokeWatchView.onHide: begin");

        isViewShown = false;
        isViewActive = false;
        animationState = :empty;

        if (enterLayer != null) {
            destroyAnimationLayer(enterLayer);
            enterLayer = null;
        }

        if (leaveLayer != null) {
            destroyAnimationLayer(leaveLayer);
            leaveLayer = null;
        }

        View.onHide();
        System.println(">>> SmokeWatchView.onHide: end");
    }

    function onExitSleep() {
        System.println(">>> SmokeWatchView.onExitSleep: begin");
        isViewActive = true;
        startAnimation();
        System.println(">>> SmokeWatchView.onExitSleep: end");
    }

    function onEnterSleep() {
        isViewActive = false;
    }

    function onUpdate(dc) {
        if (faceLayer == null) {
            return false;
        }

        var faceDc = faceLayer.getDc();

        if (faceDc == null) {
            return false;
        }

        computeValues();

        if (currentHours == lastHours
            && currentMinutes == lastMinutes
            && currentDate == lastDate
            && currentPhoneConnected == lastPhoneConnected
            && currentNotificationsCount == lastNotificationsCount
            && currentDnd == lastDnd
            && currentBatteryLevel == lastBatteryLevel
            && currentBatteryCharging == lastBatteryCharging
            && currentSteps == lastSteps
            && currentCalories == lastCalories
            && currentFloors == lastFloors
            && currentActivity == lastActivity
            && currentHeartRate == lastHeartRate
        ) {
            return true;
        }

        lastHours = currentHours;
        lastMinutes = currentMinutes;
        lastDate = currentDate;
        lastPhoneConnected = currentPhoneConnected;
        lastNotificationsCount = currentNotificationsCount;
        lastDnd = currentDnd;
        lastBatteryLevel = currentBatteryLevel;
        lastBatteryCharging = currentBatteryCharging;
        lastSteps = currentSteps;
        lastCalories = currentCalories;
        lastFloors = currentFloors;
        lastActivity = currentActivity;
        lastHeartRate = currentHeartRate;

        faceDc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        faceDc.clear();

        drawTimeAndDate(faceDc);
        drawConnectionAndNotifications(faceDc);
        drawDndAndBattery(faceDc);
        drawStats(faceDc);

        return true;
    }

    function computeValues() {
        var deviceSettings = System.getDeviceSettings();
        var systemStats = System.getSystemStats();

        var timeInfo = System.getClockTime();
        var dateInfo = Time.Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
        var hours = timeInfo.hour;

        if (deviceSettings has :is24Hour && !deviceSettings.is24Hour) {
            hours %= 12;

            if (hours == 0) {
                hours = 12;
            }
        }

        currentHours = hours.format("%02d");
        currentMinutes = timeInfo.min.format("%02d");
        currentDate = Lang.format("$1$\n$2$ $3$", [dateInfo.day_of_week, dateInfo.month, dateInfo.day]);

        currentPhoneConnected = (deviceSettings has :phoneConnected && deviceSettings.phoneConnected);
        currentNotificationsCount = (deviceSettings has :notificationCount ? deviceSettings.notificationCount : 0);

        currentDnd = (deviceSettings has :doNotDisturb && deviceSettings.doNotDisturb);
        currentBatteryLevel = (systemStats has :battery ? systemStats.battery : null);
        currentBatteryCharging = (systemStats has :charging && systemStats.charging);

        var activityInfo = ActivityMonitor.getInfo();
        var heartRateSample = ActivityMonitor.getHeartRateHistory(1, true).next();

        currentSteps = (activityInfo has :steps && activityInfo.steps != null) ? activityInfo.steps : null;
        currentCalories = (activityInfo has :calories && activityInfo.calories != null) ? activityInfo.calories : null;
        currentFloors = (activityInfo has :floorsClimbed && activityInfo.floorsClimbed != null) ? activityInfo.floorsClimbed : null;

        currentActivity = (activityInfo has :activeMinutesWeek && activityInfo.activeMinutesWeek != null)
            ? activityInfo.activeMinutesWeek.total
            : null;

        currentHeartRate = (heartRateSample != null && heartRateSample.heartRate != ActivityMonitor.INVALID_HR_SAMPLE)
            ? heartRateSample.heartRate
            : null;
    }

    function drawTimeAndDate(faceDc) {
        faceDc.drawText(
            screenCenterX,
            screenHeight * 0.35,
            timeFont,
            currentHours,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );

        faceDc.drawText(
            screenCenterX,
            screenHeight * 0.65,
            timeFont,
            currentMinutes,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );

        faceDc.drawText(
            screenWidth - screenPaddingRight,
            screenCenterY,
            infoFont,
            currentDate,
            Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER
        );
    }

    function drawConnectionAndNotifications(faceDc) {
        var notificationsCountText = currentNotificationsCount.format("%d");
        var rowWidth = 0;

        if (currentPhoneConnected) {
            rowWidth += iconSize;
        }

        if (currentNotificationsCount > 0) {
            rowWidth += iconSize + faceDc.getTextWidthInPixels(notificationsCountText, infoFont);
        }

        var rowX = screenCenterX - rowWidth * 0.5;

        if (currentPhoneConnected) {
            faceDc.drawText(
                rowX,
                screenPaddingVert,
                iconFont,
                ICON_PHONE_CONNECTED,
                Graphics.TEXT_JUSTIFY_LEFT
            );

            rowX += iconSize + iconSpacingHor;
        }

        if (currentNotificationsCount > 0) {
            faceDc.drawText(
                rowX,
                screenPaddingVert,
                iconFont,
                ICON_NOTIFICATIONS,
                Graphics.TEXT_JUSTIFY_LEFT
            );

            faceDc.drawText(
                rowX + iconSize + iconTextOffsetX,
                screenPaddingVert + iconTextOffsetY,
                infoFont,
                notificationsCountText,
                Graphics.TEXT_JUSTIFY_LEFT
            );
        }
    }

    function drawDndAndBattery(faceDc) {
        var batteryText = (currentBatteryLevel != null ? currentBatteryLevel.format("%d") + "%" : null);
        var rowWidth = 0;

        if (currentDnd) {
            rowWidth += iconSize;
        }

        if (batteryText != null) {
            rowWidth += iconSize + faceDc.getTextWidthInPixels(batteryText, infoFont);
        }

        var rowX = screenCenterX - rowWidth * 0.5;

        if (currentDnd) {
            faceDc.drawText(
                rowX,
                bottomInfoY,
                iconFont,
                ICON_DND,
                Graphics.TEXT_JUSTIFY_LEFT
            );

            rowX += iconSize + iconSpacingHor;
        }

        if (batteryText != null) {
            if (currentBatteryCharging) {
                faceDc.drawText(
                    rowX,
                    bottomInfoY,
                    iconFont,
                    ICON_BATTERY_CHARGING,
                    Graphics.TEXT_JUSTIFY_LEFT
                );
            } else {
                faceDc.drawText(
                    rowX,
                    bottomInfoY,
                    iconFont,
                    ICON_BATTERY,
                    Graphics.TEXT_JUSTIFY_LEFT
                );

                var batteryLevelHeight = currentBatteryLevel * 0.01 * batteryProgressHeight;

                faceDc.fillRectangle(
                    rowX + batteryProgressOffsetX,
                    bottomInfoY + batteryProgressOffsetY + batteryProgressHeight - batteryLevelHeight,
                    batteryProgressWidth,
                    batteryLevelHeight
                );
            }

            faceDc.drawText(
                rowX + iconSize + iconTextOffsetX,
                bottomInfoY + iconTextOffsetY,
                infoFont,
                batteryText,
                Graphics.TEXT_JUSTIFY_LEFT
            );
        }
    }

    function drawStats(faceDc) {
        var colHeight = 0;

        if (currentSteps != null) {
            colHeight += infoLineHeight;
        }

        if (currentCalories != null) {
            colHeight += infoLineHeight;
        }

        if (currentFloors != null) {
            colHeight += infoLineHeight;
        }

        if (currentActivity != null) {
            colHeight += infoLineHeight;
        }

        if (currentHeartRate != null) {
            colHeight += infoLineHeight;
        }

        var colY = screenCenterY - colHeight * 0.5;

        if (currentSteps != null) {
            faceDc.drawText(
                screenPaddingLeft,
                colY,
                iconFont,
                ICON_STEPS,
                Graphics.TEXT_JUSTIFY_LEFT
            );

            faceDc.drawText(
                screenPaddingLeft + iconSize + iconTextOffsetX,
                colY + iconTextOffsetY,
                infoFont,
                currentSteps.format("%d"),
                Graphics.TEXT_JUSTIFY_LEFT
            );

            colY += infoLineHeight;
        }

        if (currentCalories != null) {
            faceDc.drawText(
                screenPaddingLeft,
                colY,
                iconFont,
                ICON_CALORIES,
                Graphics.TEXT_JUSTIFY_LEFT
            );

            faceDc.drawText(
                screenPaddingLeft + iconSize + iconTextOffsetX,
                colY + iconTextOffsetY,
                infoFont,
                currentCalories.format("%d"),
                Graphics.TEXT_JUSTIFY_LEFT
            );

            colY += infoLineHeight;
        }

        if (currentFloors != null) {
            faceDc.drawText(
                screenPaddingLeft,
                colY,
                iconFont,
                ICON_FLOORS,
                Graphics.TEXT_JUSTIFY_LEFT
            );

            faceDc.drawText(
                screenPaddingLeft + iconSize + iconTextOffsetX,
                colY + iconTextOffsetY,
                infoFont,
                currentFloors.format("%d"),
                Graphics.TEXT_JUSTIFY_LEFT
            );

            colY += infoLineHeight;
        }

        if (currentActivity != null) {
            faceDc.drawText(
                screenPaddingLeft,
                colY,
                iconFont,
                ICON_ACTIVITY,
                Graphics.TEXT_JUSTIFY_LEFT
            );

            faceDc.drawText(
                screenPaddingLeft + iconSize + iconTextOffsetX,
                colY + iconTextOffsetY,
                infoFont,
                currentActivity.format("%d"),
                Graphics.TEXT_JUSTIFY_LEFT
            );

            colY += infoLineHeight;
        }

        if (currentHeartRate != null) {
            faceDc.drawText(
                screenPaddingLeft,
                colY,
                iconFont,
                ICON_HEART,
                Graphics.TEXT_JUSTIFY_LEFT
            );

            faceDc.drawText(
                screenPaddingLeft + iconSize + iconTextOffsetX,
                colY + iconTextOffsetY,
                infoFont,
                currentHeartRate.format("%d"),
                Graphics.TEXT_JUSTIFY_LEFT
            );

            // colY += infoLineHeight;
        }
    }

    function startAnimation() {
        System.println(">>> SmokeWatchView.startAnimation: begin, animationState = " + animationState);

        if (animationState == :active) {
            animationState = :leaving;
            enterLayer = setupAnimationLayer(enterLayer, Rez.Drawables.enter);

            leaveLayer.setVisible(true);
            leaveLayer.play({ :delegate => new SmokeWatchAnimationDelegate(self, false) });
        } else if (animationState != :entering && animationState != :leaving) {
            animationState = :entering;
            leaveLayer = setupAnimationLayer(leaveLayer, Rez.Drawables.leave);

            enterLayer.setVisible(true);
            enterLayer.play({ :delegate => new SmokeWatchAnimationDelegate(self, true) });
        }

        System.println(">>> SmokeWatchView.startAnimation: end, animationState = " + animationState);
    }

    function onAnimationComplete(isStateActive) {
        System.println(">>> SmokeWatchView.onAnimationComplete: begin, isStateActive = "
            + isStateActive
            + ", ignoreAnimationCompleteCounter = "
            + ignoreAnimationCompleteCounter
            + ", animationState = "
            + animationState);

        if (ignoreAnimationCompleteCounter > 0 || (animationState != :entering && animationState != :leaving)) {
            System.println(">>> SmokeWatchView.onAnimationComplete: end (ignoreAnimationCompleteCounter), isStateActive = "
                + isStateActive
                + ", ignoreAnimationCompleteCounter = "
                + ignoreAnimationCompleteCounter
                + ", animationState = "
                + animationState);

            return;
        }

        if (isStateActive) {
            animationState = :active;
            leaveLayer = setupAnimationLayer(leaveLayer, Rez.Drawables.leave);

            System.println(">>> SmokeWatchView.onAnimationComplete: end (isActive), isStateActive = "
                + isStateActive
                + ", ignoreAnimationCompleteCounter = "
                + ignoreAnimationCompleteCounter
                + ", animationState = "
                + animationState);

            return;
        }

        animationState = :empty;
        enterLayer = setupAnimationLayer(enterLayer, Rez.Drawables.enter);

        if (isViewShown && isViewActive) {
            startAnimation();
        }

        System.println(">>> SmokeWatchView.onAnimationComplete: end, isStateActive = "
            + isStateActive
            + ", ignoreAnimationCompleteCounter = "
            + ignoreAnimationCompleteCounter
            + ", animationState = "
            + animationState);
    }

    function setupAnimationLayer(layer, rez) {
        ++ignoreAnimationCompleteCounter;

        if (layer != null) {
            destroyAnimationLayer(layer);
        }

        layer = new WatchUi.AnimationLayer(rez, null);
        layer.setVisible(false);
        insertLayer(layer, 0);

        --ignoreAnimationCompleteCounter;
        return layer;
    }

    function destroyAnimationLayer(layer) {
        ++ignoreAnimationCompleteCounter;
        layer.stop();
        removeLayer(layer);
        --ignoreAnimationCompleteCounter;
    }
}
