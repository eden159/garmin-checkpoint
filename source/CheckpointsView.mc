using Toybox.WatchUi as Ui;
using Toybox.Math as Math;
using Toybox.Graphics as Gfx;
using Toybox.Application as App;
using Toybox.Time as Time;

class CheckpointsView extends Ui.DataField {

    hidden var currentCheckpoint;
    hidden var currentCheckpointInfo;
    hidden var maxCheckpoints;
    hidden var mTimerStarted = true;
    
    hidden var timer = false;
    hidden var secondsTimer = 4;
    hidden var lapsPressed = 0;
    hidden var distColor;

    function initialize() {
        DataField.initialize();
        maxCheckpoints = 12;
        distColor = Gfx.COLOR_WHITE;
        initCheckpointInfo();
    }
    
    function initCheckpointInfo() {
    	currentCheckpoint = 1;
        currentCheckpointInfo = {"name" => "Wait...", "distance" => "-", "remain" => "-"};
    }

    // Set your layout here. Anytime the size of obscurity of
    // the draw context is changed this will be called.
    function onLayout(dc) {
        View.setLayout(Rez.Layouts.MainLayout(dc));
        var labelView = View.findDrawableById("label");
        labelView.locY = labelView.locY - 57;
        var valueView = View.findDrawableById("value");
        valueView.locY = valueView.locY - 34;
        var valueDistView = View.findDrawableById("value_dist");
        valueDistView.locY = valueDistView.locY - 8;
        var labelRemainView = View.findDrawableById("remain_label");
        labelRemainView.locY = labelRemainView.locY + 23;
        var valueRemainView = View.findDrawableById("value_dist_remain");
        valueRemainView.locY = valueRemainView.locY + 50;

        labelView.setText(Rez.Strings.label);
        labelRemainView.setText(Rez.Strings.remain_label);
        return true;
    }
    
    function findCheckpoint(elapsedDistance) {
    	var i, tmp;
    	var app = App.getApp();
    	
    	for(i = 1; i <= maxCheckpoints; i++) {

    		tmp = app.getProperty("ch" + i + "_dist");
    		
    		if (tmp == null) {
    			continue;
    		}
    		
    		tmp = tmp * 1000;
    		
    		if (elapsedDistance < tmp) {
    			return i;
    		}
    	}
    	
    	return maxCheckpoints + 1;
    }
    
    function setCheckpointData(checkpoint, elapsedDistance) {
    	var app = App.getApp(), tmp;
    	
    	tmp = app.getProperty("ch" + checkpoint + "_dist");
    	
    	if (tmp == null) {
			return {"name" => "Wait...", "distance" => "-", "remain" => "-"};
		}
    	
    	return {
    		"name" => app.getProperty("ch" + checkpoint + "_name"),
    		"distance" => tmp.format("%.2f") + " km",
    		"remain" => (Math.round((tmp*1000 - elapsedDistance*1)/10)/100).format("%.2f") + " km"
    	};
    }

    // The given info object contains all the current workout information.
    // Calculate a value and save it locally in this method.
    // Note that compute() and onUpdate() are asynchronous, and there is no
    // guarantee that compute() will be called before onUpdate().
    function compute(info) {
    
    	if (timer != false && checkTimeElapsed(timer, secondsTimer) == true) {
    		timer = false;
    		distColor = Gfx.COLOR_WHITE;
    	
    		if (lapsPressed == 2) {
    			offsetDistance(-0.5);
    		} else if (lapsPressed == 3) {
    			offsetDistance(0.5);
    		}
    	}
    
    	if (mTimerStarted == true) {
	        // See Activity.Info in the documentation for available information.
	        if(info has :elapsedDistance){
	            if(info.elapsedDistance != null){
	                currentCheckpoint = findCheckpoint(info.elapsedDistance);
	                currentCheckpointInfo = setCheckpointData(currentCheckpoint, info.elapsedDistance);
	            } else {
	                initCheckpointInfo();
	            }
	        } else {
	        	initCheckpointInfo();
	        }
        }
    }

    // Display the value you computed here. This will be called
    // once a second when the data field is visible.
    function onUpdate(dc) {
    
        // Set the background color
        View.findDrawableById("Background").setColor(Gfx.COLOR_BLACK);

        // Set the foreground color and value
        var value = View.findDrawableById("value");
        var valueDist = View.findDrawableById("value_dist");
        var valueRemain = View.findDrawableById("value_dist_remain");
        var labelView = View.findDrawableById("label");
        var labelRemainView = View.findDrawableById("remain_label");
        
        value.setColor(Gfx.COLOR_WHITE);
        valueDist.setColor(distColor);
        valueRemain.setColor(Gfx.COLOR_WHITE);
        labelView.setColor(Gfx.COLOR_WHITE);
        labelRemainView.setColor(Gfx.COLOR_WHITE);
        
        if (currentCheckpoint <= maxCheckpoints) {
	        value.setText(currentCheckpointInfo["name"]);
	        valueDist.setText(currentCheckpointInfo["distance"]);
	        valueRemain.setText(currentCheckpointInfo["remain"]);
	    } else {
	    	value.setText(Rez.Strings.completed);
        	valueDist.setText("");
        	valueRemain.setText("");
	    }

        // Call parent's onUpdate(dc) to redraw the layout
        View.onUpdate(dc);
    }
    
    function offsetDistance(distance)
    {
    	var i, tmp;
    	var app = App.getApp();
    	
    	for(i = 1; i <= maxCheckpoints; i++) {

    		tmp = app.getProperty("ch" + i + "_dist");
    		
    		if (tmp == null || tmp < 0.5) {
    			continue;
    		}
    		
    		tmp = tmp + distance;
    		
    		app.setProperty("ch" + i + "_dist", tmp);
    	}
    	
    	Ui.requestUpdate();
    }

//! The timer was started, so set the state to running.
    function onTimerStart()
    {
        mTimerStarted = true;
    }
    
    function checkTimeElapsed(oldTime, seconds) {
        
		var now = Time.now();
		
		if (now.value() - oldTime.value() >= seconds) {
			return true;
		}
		
		return false;
    }
    
    function onTimerLap()
    {
        if (timer == false) {
        	lapsPressed = 1;
        	timer = Time.now();
        } else {
        	lapsPressed = lapsPressed + 1;
        }
        
        var oldColor = distColor;
        
        if (lapsPressed == 2) {
			distColor = Gfx.COLOR_RED;
		} else if (lapsPressed == 3) {
			distColor = Gfx.COLOR_GREEN;
		} else {
			distColor = Gfx.COLOR_WHITE;
		}
		
		if (oldColor != distColor) {
			Ui.requestUpdate();
		}
    }

    //! The timer was stopped, so set the state to stopped.
    function onTimerStop()
    {
        mTimerStarted = false;
    }

    //! The timer was started, so set the state to running.
    function onTimerPause()
    {
        mTimerStarted = false;
    }

    //! The timer was stopped, so set the state to stopped.
    function onTimerResume()
    {
        mTimerStarted = true;
    }

    //! The timer was reeset, so reset all our tracking variables
    function onTimerReset()
    {
        mTimerStarted = false;
    }
}