//
//  RealtimeAudioController.h
//  DiracRealtimeExample
//
//  Created by Stephan on 20.03.11.
//  Copyright 2011 The DSP Dimension. All rights reserved.
//
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

#import "EAFRead.h"



@interface RealtimeAudioController : NSObject 
{
	AudioComponentInstance mAudioUnit;

	EAFRead *mReader;
	void *mDirac;
	float mSampleRate;
	volatile BOOL mExitThread;
	volatile BOOL mThreadHasExited;
	
	float mPitch, mTime;
	
	SInt16 **mAudioBuffer;
	long mAudioBufferReadPos;
	long mAudioBufferWritePos;
    
    NSURL *inUrl;
	
}

@property (readonly) AudioComponentInstance mAudioUnit;
@property (readonly) EAFRead *mReader;
@property (readonly) SInt16 **mAudioBuffer;
@property (readonly) void *mDirac;
@property (readwrite) long mAudioBufferReadPos;
@property (readonly) long mAudioBufferWritePos;

- (void) start;
- (void) stop;
-(void)changePitch:(float)pitch;
-(void)changeDuration:(float)duration;
-(void)commitChanges;

@end
