package com.yahoo.gnews.android.helloworld;

//import com.urbanairship.Logger;

import android.app.Activity;
import android.content.Context;
import android.os.Bundle;
import android.webkit.WebView;
import android.hardware.SensorListener;
import android.hardware.SensorManager;
import android.location.*;

public class HelloWorld2Activity extends Activity implements SensorListener { 
	/** Called when the activity is first created. */
	WebView webview;
    // For shake motion detection.
    private SensorManager sensorMgr;
    private long lastUpdate = -1;
    private float x, y, z;
    private float last_x, last_y, last_z;
    private static final int SHAKE_THRESHOLD = 800;   
    
	@Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        
        setContentView(R.layout.main);
        webview = (WebView) findViewById(R.id.webview);
        webview.getSettings().setJavaScriptEnabled(true);
        webview.loadUrl("http://chrisho.info/pig/pig.html");
        
     
    	// start motion detection
    	sensorMgr = (SensorManager) getSystemService(SENSOR_SERVICE);
    	boolean accelSupported = sensorMgr.registerListener(this,
    		SensorManager.SENSOR_ACCELEROMETER,
    		SensorManager.SENSOR_DELAY_GAME);
     
    	if (!accelSupported) {
    	    // on accelerometer on this device
    	    sensorMgr.unregisterListener(this,
                    SensorManager.SENSOR_ACCELEROMETER);
    	}
        
/*
  		     // Acquire a reference to the system Location Manager
        LocationManager locationManager = (LocationManager) this.getSystemService(Context.LOCATION_SERVICE);

        // Define a listener that responds to location updates
        LocationListener locationListener = new LocationListener() {
            public void onLocationChanged(Location location) {
              // Called when a new location is found by the network location provider.
             // makeUseOfNewLocation(location);
            	 location.getLatitude();
            }

            public void onStatusChanged(String provider, int status, Bundle extras) {}

            public void onProviderEnabled(String provider) {}

            public void onProviderDisabled(String provider) {}
          };

        // Register the listener with the Location Manager to receive location updates
        locationManager.requestLocationUpdates(LocationManager.NETWORK_PROVIDER, 0, 0, locationListener);
        */
    }
	
	   		protected void onPause() {
				if (sensorMgr != null) {
				    sensorMgr.unregisterListener(this,
			                SensorManager.SENSOR_ACCELEROMETER);
				    sensorMgr = null;
			        }
				super.onPause();
		    }
		 
		    public void onAccuracyChanged(int arg0, int arg1) {
			// TODO Auto-generated method stub
		    }
		 
		    public void onSensorChanged(int sensor, float[] values) {
			if (sensor == SensorManager.SENSOR_ACCELEROMETER) {
			    long curTime = System.currentTimeMillis();
			    // only allow one update every 100ms.
			    if ((curTime - lastUpdate) > 100) {
				long diffTime = (curTime - lastUpdate);
				lastUpdate = curTime;
		 
				x = values[SensorManager.DATA_X];
				y = values[SensorManager.DATA_Y];
				z = values[SensorManager.DATA_Z];
		 
				float speed = Math.abs(x+y+z - last_x - last_y - last_z)
		                              / diffTime * 10000;
				if (speed > SHAKE_THRESHOLD) {
				    // yes, this is a shake action! Do something about it!

			     //   setContentView(R.layout.main);
			     //   webview = (WebView) findViewById(R.id.webview);
			       // webview.getSettings().setJavaScriptEnabled(true);
			        webview.loadUrl("javascript:autoGen(2);alert('1');");
					//webview.loadUrl("http://google.com");
				}
				last_x = x;
				last_y = y;
				last_z = z;
			    }
			}
		    }
		    
}