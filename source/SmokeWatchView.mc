using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.System;
using Toybox.Lang;
using Toybox.Graphics;
using Toybox.ActivityMonitor;
using Toybox.Time;
using Toybox.Timer;

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

    const SMOKE_ACTIVE_INDEX = 4;

    var animationTimer = null;
    var smokeBitmaps = [];

    var timeFont = null;
    var infoFont = null;
    var iconFont = null;

    var screenWidth = 0;
    var screenHeight = 0;
    var screenCenterX = 0;
    var screenCenterY = 0;

    var iconSize = 0;
    var infoHeight = 0;
    var captionOffsetX = 0;
    var captionOffsetY = 0;

    var hoursMidY = 0;
    var minutesMidY = 0;
    var dateEndX = 0;
    var topBlockY = 0;
    var leftBlockX = 0;
    var bottomBlockY = 0;

    var iconSpacing = 0;
    var batteryWidth = 0;
    var batteryHeight = 0;
    var batteryOffsetX = 0;
    var batteryOffsetY = 0;

    var backLayer = null;
    var faceLayer = null;

    var isViewShown = false;
    var isJustShown = false;

    var currentSmokeIndex = 0;
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

    var lastSmokeIndex = -1;
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
        WatchFace.initialize();
        animationTimer = new Timer.Timer();

        smokeBitmaps = [
            Rez.Drawables.Smoke01,
            Rez.Drawables.Smoke02,
            Rez.Drawables.Smoke03,
            Rez.Drawables.Smoke04,
            Rez.Drawables.Smoke05,
            Rez.Drawables.Smoke06,
            Rez.Drawables.Smoke07,
            Rez.Drawables.Smoke08,
            Rez.Drawables.Smoke09,
            null
        ];
    }

    function onLayout(dc) {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        // Resources

        timeFont = WatchUi.loadResource(Rez.Fonts.RobotoLight);
        infoFont = Graphics.FONT_XTINY;
        iconFont = WatchUi.loadResource(Rez.Fonts.Icons);

        // Compute

        var settings = System.getDeviceSettings();
        screenWidth = settings.screenWidth;
        screenHeight = settings.screenHeight;
        screenCenterX = (screenWidth * 0.5).toNumber();
        screenCenterY = (screenHeight * 0.5).toNumber();

        iconSize = Graphics.getFontHeight(iconFont);
        infoHeight = Graphics.getFontHeight(infoFont);
        captionOffsetX = iconSize + 2;
        captionOffsetY = ((iconSize - infoHeight) * 0.5).toNumber();

        hoursMidY = (screenHeight * 0.35).toNumber();
        minutesMidY =  (screenHeight * 0.65).toNumber();
        dateEndX = screenWidth - (screenWidth * (iconSize >= 16 ? 0.075 : 0.05)).toNumber();
        topBlockY = (screenHeight * 0.075).toNumber();
        leftBlockX = (screenWidth * 0.075).toNumber();
        bottomBlockY = screenHeight - (screenHeight * 0.075).toNumber() - iconSize;

        if (iconSize >= 16) {
            iconSpacing = 4;
            batteryWidth = 6;
            batteryHeight = 11;
            batteryOffsetX = 5;
            batteryOffsetY = 4;
        } else {
            iconSpacing = 2;
            batteryWidth = 5;
            batteryHeight = 10;
            batteryOffsetX = 5;
            batteryOffsetY = 5;
        }

        // Layers

        backLayer = new WatchUi.Layer({
            :locX => 0,
            :locY => 0,
            :width => screenWidth,
            :height => screenHeight
        });

        faceLayer = new WatchUi.Layer({
            :locX => 0,
            :locY => 0,
            :width => screenWidth,
            :height => screenHeight
        });

        addLayer(backLayer);
        addLayer(faceLayer);

        return true;
    }

    // Lifecycle

    function onShow() {
        isViewShown = true;
        isJustShown = (currentSmokeIndex < SMOKE_ACTIVE_INDEX);
        startAnimation();
        return true;
    }

    function onUpdate(dc) {
        updateValues();
        renderBack();
        renderFace();
        return true;
    }

    function onHide() {
        isViewShown = false;
        stopAnimation();
        View.onHide();
    }

    // Power mode

    function onExitSleep() {
        if (isViewShown) {
            startAnimation();
        }
    }

    function onEnterSleep() {
        if (isViewShown) {
            stopAnimation();
        }
    }

    // Values

    function updateValues() {
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
        currentDate = dateInfo.day_of_week + "\n" + dateInfo.month + " " + dateInfo.day.format("%d");

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

    // Background

    function startAnimation() {
        animationTimer.stop();
        animationTimer.start(method(:renderAnimation), 100, true);
    }

    function stopAnimation() {
        animationTimer.stop();
        currentSmokeIndex = SMOKE_ACTIVE_INDEX;
    }

    function renderAnimation() {
        currentSmokeIndex = (currentSmokeIndex + 1) % smokeBitmaps.size();

        if (currentSmokeIndex == SMOKE_ACTIVE_INDEX) {
            if (isJustShown) {
                isJustShown = false;
            } else {
                animationTimer.stop();
            }
        }

        requestUpdate();
    }

    function renderBack() {
        if (backLayer == null) {
            return;
        }

        var backDc = backLayer.getDc();

        if (backDc == null || currentSmokeIndex == lastSmokeIndex) {
            return;
        }

        lastSmokeIndex = currentSmokeIndex;
        var bitmap = smokeBitmaps[currentSmokeIndex];

        if (bitmap == null) {
            backDc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
            backDc.clear();
        } else if (bitmap instanceof WatchUi.BitmapResource) {
            backDc.drawBitmap(0, 0, bitmap);
        } else {
            bitmap = WatchUi.loadResource(bitmap);
            smokeBitmaps[currentSmokeIndex] = bitmap;
            backDc.drawBitmap(0, 0, bitmap);
        }
    }

    // Face

    function renderFace() {
        if (faceLayer == null) {
            return;
        }

        var faceDc = faceLayer.getDc();

        if (faceDc == null) {
            return;
        }

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
            return;
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
        drawTopBlock(faceDc);
        drawBottomBlock(faceDc);
        drawLeftBlock(faceDc);
    }

    function drawTimeAndDate(dc) {
        dc.drawText(
            screenCenterX,
            hoursMidY,
            timeFont,
            currentHours,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );

        dc.drawText(
            screenCenterX,
            minutesMidY,
            timeFont,
            currentMinutes,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );

        dc.drawText(
            dateEndX,
            screenCenterY,
            infoFont,
            currentDate,
            Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER
        );
    }

    function drawTopBlock(dc) {
        var notificationsCountText = currentNotificationsCount.format("%d");
        var width = 0;

        if (currentPhoneConnected) {
            width += iconSize;
        }

        if (currentPhoneConnected && currentNotificationsCount > 0) {
            width += iconSpacing;
        }

        if (currentNotificationsCount > 0) {
            width += captionOffsetX + dc.getTextWidthInPixels(notificationsCountText, infoFont);
        }

        var x = (screenCenterX - width * 0.5).toNumber();

        if (currentPhoneConnected) {
            dc.drawText(x, topBlockY, iconFont, ICON_PHONE_CONNECTED, Graphics.TEXT_JUSTIFY_LEFT);
            x += iconSize + iconSpacing;
        }

        if (currentNotificationsCount > 0) {
            dc.drawText(x, topBlockY, iconFont, ICON_NOTIFICATIONS, Graphics.TEXT_JUSTIFY_LEFT);

            dc.drawText(
                x + captionOffsetX,
                topBlockY + captionOffsetY - 0.5,
                infoFont,
                notificationsCountText,
                Graphics.TEXT_JUSTIFY_LEFT
            );
        }
    }

    function drawBottomBlock(dc) {
        var batteryText = (currentBatteryLevel != null ? currentBatteryLevel.format("%d") + "%" : null);
        var width = 0;

        if (currentDnd) {
            width += iconSize;
        }

        if (currentDnd && batteryText != null) {
            width += iconSpacing;
        }

        if (batteryText != null) {
            width += captionOffsetX + dc.getTextWidthInPixels(batteryText, infoFont);
        }

        var x = (screenCenterX - width * 0.5).toNumber();

        if (currentDnd) {
            dc.drawText(x, bottomBlockY, iconFont, ICON_DND, Graphics.TEXT_JUSTIFY_LEFT);
            x += iconSize + iconSpacing;
        }

        if (batteryText != null) {
            if (currentBatteryCharging) {
                dc.drawText(x, bottomBlockY, iconFont, ICON_BATTERY_CHARGING, Graphics.TEXT_JUSTIFY_LEFT);
            } else {
                dc.drawText(x, bottomBlockY, iconFont, ICON_BATTERY, Graphics.TEXT_JUSTIFY_LEFT);
                var batHeight = currentBatteryLevel * 0.01 * batteryHeight;

                dc.fillRectangle(
                    x + batteryOffsetX,
                    bottomBlockY + batteryOffsetY + batteryHeight - batHeight,
                    batteryWidth,
                    batHeight
                );
            }

            dc.drawText(
                x + captionOffsetX,
                bottomBlockY + captionOffsetY,
                infoFont,
                batteryText,
                Graphics.TEXT_JUSTIFY_LEFT
            );
        }
    }

    function drawLeftBlock(dc) {
        var height = 0;

        if (currentSteps != null) {
            height += infoHeight;
        }

        if (currentCalories != null) {
            height += infoHeight;
        }

        if (currentFloors != null) {
            height += infoHeight;
        }

        if (currentActivity != null) {
            height += infoHeight;
        }

        if (currentHeartRate != null) {
            height += infoHeight;
        }

        var y = (screenCenterY - height * 0.5).toNumber();

        if (currentSteps != null) {
            drawStatsItem(dc, y, ICON_STEPS, currentSteps.format("%d"));
            y += infoHeight;
        }

        if (currentCalories != null) {
            drawStatsItem(dc, y, ICON_CALORIES, currentCalories.format("%d"));
            y += infoHeight;
        }

        if (currentFloors != null) {
            drawStatsItem(dc, y, ICON_FLOORS, currentFloors.format("%d"));
            y += infoHeight;
        }

        if (currentActivity != null) {
            drawStatsItem(dc, y, ICON_ACTIVITY, currentActivity.format("%d"));
            y += infoHeight;
        }

        if (currentHeartRate != null) {
            drawStatsItem(dc, y, ICON_HEART, currentHeartRate.format("%d"));
        }
    }

    function drawStatsItem(dc, y, icon, text) {
        dc.drawText(leftBlockX, y, iconFont, icon, Graphics.TEXT_JUSTIFY_LEFT);
        dc.drawText(leftBlockX + captionOffsetX, y + captionOffsetY, infoFont, text, Graphics.TEXT_JUSTIFY_LEFT);
    }
}
