//
//  DiracRealtimeExampleViewController.h
//  DiracRealtimeExample
//
//  Created by Stephan on 20.03.11.
//  Copyright 2011 The DSP Dimension. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RealtimeAudioController.h"

@interface DiracRealtimeExampleViewController : UIViewController {

	IBOutlet UIButton *uiStartButton;
	IBOutlet UIButton *uiStopButton;
	
	IBOutlet UISlider *uiDurationSlider;
	IBOutlet UISlider *uiPitchSlider;
	
	IBOutlet UILabel *uiDurationLabel;
	IBOutlet UILabel *uiPitchLabel;

	IBOutlet UISwitch *uiVarispeedSwitch;
	BOOL mUseVarispeed;

	RealtimeAudioController *mRealtimeController;
	
}


-(IBAction)uiDurationSliderMoved:(UISlider *)sender;
-(IBAction)uiPitchSliderMoved:(UISlider *)sender;

-(IBAction)uiStartButtonTapped:(UIButton *)sender;
-(IBAction)uiStopButtonTapped:(UIButton *)sender;

-(IBAction)uiVarispeedSwitchTapped:(UISwitch *)sender;

@end

