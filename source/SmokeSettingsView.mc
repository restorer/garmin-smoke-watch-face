using Toybox.WatchUi;

class SmokeSettingsView extends WatchUi.Menu2 {
    function initialize() {
        Menu2.initialize({ :title => WatchUi.loadResource(Rez.Strings.SettingsTitle) });

        addItem(new WatchUi.MenuItem(WatchUi.loadResource(Rez.Strings.SettingsVersion), null, "version", null));
        addItem(new WatchUi.MenuItem(WatchUi.loadResource(Rez.Strings.SettingsLicense), null, "license", null));
    }
}

class SmokeSettingsDelegate extends WatchUi.Menu2InputDelegate {
    function initialize() {
        Menu2InputDelegate.initialize();
    }

    // function onSelect(menuItem) {
    // }
}
