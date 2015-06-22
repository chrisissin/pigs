//
//  DiracRealtimeExampleViewController.m
//  DiracRealtimeExample
//
//  Created by Stephan on 20.03.11.
//  Copyright 2011 The DSP Dimension. All rights reserved.
//

#import "DiracRealtimeExampleViewController.h"


@implementation DiracRealtimeExampleViewController

// ---------------------------------------------------------------------------------------------------------------------------------------------

/*
// The designated initializer. Override to perform setup that is required before the view is loaded.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}
*/
// ---------------------------------------------------------------------------------------------------------------------------------------------

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
}
*/

// ---------------------------------------------------------------------------------------------------------------------------------------------

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad 
{
    [super viewDidLoad];
	mRealtimeController = [[RealtimeAudioController alloc] init];
	mUseVarispeed = NO;
}

// ---------------------------------------------------------------------------------------------------------------------------------------------

-(IBAction)uiDurationSliderMoved:(UISlider *)sender;
{
	[mRealtimeController changeDuration:sender.value];
	uiDurationLabel.text = [NSString stringWithFormat:@"%3.2f", sender.value];

	if (mUseVarispeed) {
		float val = 1.f/sender.value;
		uiPitchSlider.value = (int)12.f*log2f(val);
		uiPitchLabel.text = [NSString stringWithFormat:@"%d", (int)uiPitchSlider.value];
		[mRealtimeController changePitch:val];
	}
	
	[mRealtimeController commitChanges];
}
// ---------------------------------------------------------------------------------------------------------------------------------------------

-(IBAction)uiPitchSliderMoved:(UISlider *)sender;
{
	[mRealtimeController changePitch:powf(2.f, (int)sender.value / 12.f)];
	uiPitchLabel.text = [NSString stringWithFormat:@"%d", (int)sender.value];
	[mRealtimeController commitChanges];
}
// ---------------------------------------------------------------------------------------------------------------------------------------------

-(IBAction)uiStartButtonTapped:(UIButton *)sender;
{
	[mRealtimeController start];
}
// ---------------------------------------------------------------------------------------------------------------------------------------------

-(IBAction)uiStopButtonTapped:(UIButton *)sender;
{
	[mRealtimeController stop];
}
// ---------------------------------------------------------------------------------------------------------------------------------------------

-(IBAction)uiVarispeedSwitchTapped:(UISwitch *)sender;
{
	if (sender.on) {
		mUseVarispeed = YES;

		uiPitchSlider.enabled=NO;

		float val = 1.f/uiDurationSlider.value;
		uiPitchSlider.value = (int)12.f*log2f(val);
		uiPitchLabel.text = [NSString stringWithFormat:@"%d", (int)uiPitchSlider.value];
		[mRealtimeController changePitch:val];		
		
	} else {
		mUseVarispeed = NO;
		uiPitchSlider.enabled=YES;
	}
	[mRealtimeController commitChanges];
}
// ---------------------------------------------------------------------------------------------------------------------------------------------

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/
// ---------------------------------------------------------------------------------------------------------------------------------------------

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}
// ---------------------------------------------------------------------------------------------------------------------------------------------

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}

// ---------------------------------------------------------------------------------------------------------------------------------------------

- (void)dealloc {
	[mRealtimeController release];
    [super dealloc];
}

// ---------------------------------------------------------------------------------------------------------------------------------------------
// ---------------------------------------------------------------------------------------------------------------------------------------------
// ---------------------------------------------------------------------------------------------------------------------------------------------
// ---------------------------------------------------------------------------------------------------------------------------------------------




@end
