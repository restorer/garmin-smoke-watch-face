using Toybox.Application;

class SmokeApp extends Application.AppBase {
    function initialize() {
        AppBase.initialize();
    }

    function onStart(state) {
    }

    function onStop(state) {
    }

    function getInitialView() {
        return [new SmokeWatchView()];
    }

    function getSettingsView() {
        return [new SmokeSettingsView(), new SmokeSettingsDelegate()];
    }
}
