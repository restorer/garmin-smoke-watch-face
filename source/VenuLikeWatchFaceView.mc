using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.System;
using Toybox.Lang;
using Toybox.Graphics as Gfx;

class AnimationDelegate extends WatchUi.AnimationDelegate {
	var owner = null;
	var nextIsActive = false;

	function initialize(owner, nextIsActive) {
		System.println(">>> AnimationDelegate.initialize: begin");
		self.owner = owner;
		self.nextIsActive = nextIsActive;
		
		WatchUi.AnimationDelegate.initialize();
		System.println(">>> AnimationDelegate.initialize: end");
	}

	function onAnimationEvent(event, options) {
		System.println(">>> AnimationDelegate.onAnimationEvent: begin, event = " + event);

		if (event == WatchUi.ANIMATION_EVENT_COMPLETE) {
			owner.onAnimationComplete(nextIsActive);
		}

		System.println(">>> AnimationDelegate.onAnimationEvent: end");
	}
}

class VenuLikeWatchFaceView extends WatchUi.WatchFace {
	var timeFont = Graphics.FONT_NUMBER_MEDIUM;
	var state = :empty;
	var enterLayer = null;
	var leaveLayer = null;
	var faceLayer = null;
	var timeTextMidX = 0;
	var timeTextMidY = 0;
	var isShown = false;
	var isPerformingAttach = false;

    function initialize() {
		System.println(">>> VenuLikeWatchFaceView.initialize: begin");
        WatchFace.initialize();
		System.println(">>> VenuLikeWatchFaceView.initialize: end");
    }

    function onLayout(dc) {
		System.println(">>> VenuLikeWatchFaceView.onLayout: begin");
    	setLayout(Rez.Layouts.WatchFace(dc));

        dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_BLACK);
        dc.clear();
        
        var settings = System.getDeviceSettings();

		faceLayer = new WatchUi.Layer({
			:locX => 0,
			:locY => 0,
			:width => settings.screenWidth,
			:height => settings.screenHeight
		});

        addLayer(faceLayer);
        
        timeTextMidX = settings.screenWidth / 2;
        timeTextMidY = settings.screenHeight / 2; 
        
		System.println(">>> VenuLikeWatchFaceView.onLayout: end");
        return true;
    }

    function onShow() {
		System.println(">>> VenuLikeWatchFaceView.onShow: begin");

		if (enterLayer == null) {
			enterLayer = attachAnimation(null, Rez.Drawables.enter);
		}

		if (leaveLayer == null) {
			leaveLayer = attachAnimation(null, Rez.Drawables.leave);
		}

    	isShown = true;
    	startAnimation();

		System.println(">>> VenuLikeWatchFaceView.onShow: end");
    	return true;
    }

    function onHide() {
		System.println(">>> VenuLikeWatchFaceView.onHide: begin");

    	isShown = false;
    	state = :empty;
   
		if (enterLayer != null) {
			enterLayer.stop();
			removeLayer(enterLayer);
			enterLayer = null;
		}

		if (leaveLayer != null) {
			leaveLayer.stop();
			removeLayer(leaveLayer);
			leaveLayer = null;
		}

    	View.onHide();
		System.println(">>> VenuLikeWatchFaceView.onHide: end");
    }

    function onExitSleep() {
		System.println(">>> VenuLikeWatchFaceView.onExitSleep: begin");
    	startAnimation();
		System.println(">>> VenuLikeWatchFaceView.onExitSleep: end");
    }

    function onEnterSleep() {
    }

    function onUpdate(dc) {
    	performUpdate(true);
    	return true;
    }

	function onPartialUpdate(dc) {
    	performUpdate(false);
	}

	function performUpdate(isFullUpdate) {
		if (faceLayer == null) {
			return;
		}
		
		var faceDc = faceLayer.getDc();
		
		if (faceDc == null) {
			return;
		}
		
        var time = System.getClockTime();
        var timeString = Lang.format("$1$:$2$", [time.hour, time.min.format("%02d")]);
        
        faceDc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
        faceDc.clear();
        faceDc.drawText(timeTextMidX, timeTextMidY, timeFont, timeString, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
	}

	function startAnimation() {
		System.println(">>> VenuLikeWatchFaceView.startAnimation: begin, state = " + decodeState());

    	if (state == :active) {
    		state = :leaving;
			enterLayer = attachAnimation(enterLayer, Rez.Drawables.enter);

    		leaveLayer.setVisible(true);    		
    		leaveLayer.play({ :delegate => new AnimationDelegate(self, false) });
    	} else if (state != :entering && state != :leaving) {
    		state = :entering;
			leaveLayer = attachAnimation(leaveLayer, Rez.Drawables.leave);

    		enterLayer.setVisible(true);
    		enterLayer.play({ :delegate => new AnimationDelegate(self, true) });
    	}

		System.println(">>> VenuLikeWatchFaceView.startAnimation: end, state = " + decodeState());
	}
    
    function onAnimationComplete(isActive) {
		System.println(">>> VenuLikeWatchFaceView.onAnimationComplete: begin, isActive = " + isActive + ", isPerformingAttach = " + isPerformingAttach + ", state = " + decodeState());

    	if (isPerformingAttach) {
			System.println(">>> VenuLikeWatchFaceView.onAnimationComplete: end (isPerformingAttach), isActive = " + isActive + ", isPerformingAttach = " + isPerformingAttach + ", state = " + decodeState());
    		return;
    	}
    
		if (isActive) {
			state = :active;
	    	leaveLayer = attachAnimation(leaveLayer, Rez.Drawables.leave);
			System.println(">>> VenuLikeWatchFaceView.onAnimationComplete: end (isActive), isActive = " + isActive + ", isPerformingAttach = " + isPerformingAttach + ", state = " + decodeState());
			return;
		}

		state = :empty;
		enterLayer = attachAnimation(enterLayer, Rez.Drawables.enter);

		if (isShown) {
			startAnimation();
		}

		System.println(">>> VenuLikeWatchFaceView.onAnimationComplete: end, isActive = " + isActive + ", isPerformingAttach = " + isPerformingAttach + ", state = " + decodeState());
    }

	function attachAnimation(layer, rez) {
		isPerformingAttach = true;
	
		if (layer != null) {
			layer.stop();
			removeLayer(layer);
		}

		layer = new WatchUi.AnimationLayer(rez, null);
		layer.setVisible(false);
		insertLayer(layer, 0);
		
		isPerformingAttach = false;
		return layer;
	}
	
	function decodeState() {
		if (state == :empty) {
			return ":empty";
		}
		
		if (state == :entering) {
			return ":entering";
		}
		
		if (state == :leaving) {
			return ":leaving";
		}
		
		if (state == :active) {
			return ":active";
		}
		
		return state;
	}
}
