using Toybox.Application;

class VenuLikeWatchFaceApp extends Application.AppBase {
    function initialize() {
        AppBase.initialize();
    }

    function onStart(state) {
    }

    function onStop(state) {
    }

    function getInitialView() {
        return [ new VenuLikeWatchFaceView() ];
    }
}
