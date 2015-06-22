//
//  RealtimeAudioController.m
//  DiracRealtimeExample
//
//  Created by Stephan on 20.03.11.
//  Copyright 2011 The DSP Dimension. All rights reserved.
//
//	Version 1.2 (22-03-2011): Added varispeed option. Moved worker thread creation code to -commitChanges. Improved EAFRead class.
//	Version 1.1 (22-03-2011): Fixed crash/hang when changing pitch and speed
//

#import "RealtimeAudioController.h"
#import <AudioToolbox/AudioToolbox.h>
#include "Dirac.h"
#include "Utilities.h"

#define kOutputBus 0
#define kInputBus 1

#define kNumChannels			1			/* number of channels, LE supports only one */
#define kAudioBufferNumFrames	8192		/* number of frames in our cache */


#pragma mark Callbacks


// ---------------------------------------------------------------------------------------------------------------------------
/*
 This is the callback function that supplies data from the input stream/file to Dirac when needed.
 The read requests are *always* consecutive, ie. the routine will never have to supply data out
 of order.
 */
long DiracDataProviderCallback(float **chdata, long numFrames, void *userData)
{	
	// The userData parameter can be used to pass information about the caller (for example, "self") to
	// the callback so it can manage its audio streams.
	if (!chdata)	return 0;
	
	RealtimeAudioController *Self = (RealtimeAudioController*)userData;
	if (!Self)	return 0;
	
    long ret = 0;
	
    // the following makes sure that we can't make any ExtAudioFile calls from another thread (like 
    // when pressing start or changing parameters). Apple's EAF API is not thread-safe. Note that
    // this is only relevant when using DiracLE, as we don't have to restart processing in PRO.
    @synchronized(Self.mReader) {
		// read numFrames frames from our audio file
        ret = [Self.mReader readFloatsConsecutive:numFrames intoArray:chdata];
		if (ret == 0) {	// if we're hitting EOF we loop over
			[Self.mReader seekToStart];
			ret = [Self.mReader readFloatsConsecutive:numFrames intoArray:chdata];
		}
    }
	
	// return value < 0 on error, 0 when reaching EOF, numFrames read otherwise
	return ret;
	
}


// ---------------------------------------------------------------------------------------------------------------------------
/*
 This is the playback callback that our AudioUnit calls in order to get new data. In an iOS callback
 we're not allowed to use calls that can block, so we're using the callback to copy data from our internal
 cache (which is filled on a separate worker thread, see explanation at processAudioThread for more detail). 
 */
static OSStatus PlaybackCallback(void *inRefCon, 
								 AudioUnitRenderActionFlags *ioActionFlags, 
								 const AudioTimeStamp *inTimeStamp, 
								 UInt32 inBusNumber, 
								 UInt32 inNumberFrames, 
								 AudioBufferList *ioData) 
{    
	// this points to our class instance
	RealtimeAudioController *Self = (RealtimeAudioController *)inRefCon;
	
	// get the actual audio buffer from the ABL	
	AudioBuffer buffer = ioData->mBuffers[0];
	
	// this points to the buffer that is going to be filled with our data
	SInt16 *ioBuffer = (SInt16*)buffer.mData;
	
	// this is how much data will be in our buffer once we're done
	buffer.mDataByteSize = kNumChannels * inNumberFrames * sizeof(SInt16);

	// loop through all frames and channels to copy the data into our AudioBuffer
	long audioBufferReadPos = Self.mAudioBufferReadPos;		// store this in a temporary to avoid ObjC call overhead
	SInt16 **audioBuffer = Self.mAudioBuffer;
	for (long s = 0; s < inNumberFrames; s++) {
		for (long c = 0; c < kNumChannels; c++) {
			ioBuffer[kNumChannels*s+c] = audioBuffer[c][audioBufferReadPos];
		}
		
		// advance our read position and make sure we stay within limits
		audioBufferReadPos++;
		if (audioBufferReadPos > kAudioBufferNumFrames-1)
			audioBufferReadPos = 0;
	}
	Self.mAudioBufferReadPos = audioBufferReadPos;	// write back
	
    return noErr;
}


#pragma mark RealtimeAudioController Class


@implementation RealtimeAudioController


@synthesize mAudioUnit, mReader, mAudioBufferReadPos, mAudioBuffer, mDirac, mAudioBufferWritePos;


// ---------------------------------------------------------------------------------------------------------------------------
/* 
 This is where the actual processing happens. We create a background thread that constantly reads from the file,
 processes audio data and writes it into a cache (mAudioBuffer). If there is enough data in the cache already we don't call
 Dirac on this pass and simply wait until we see that our PlaybackCallback has consumed enough frames.
 
 Note that you might need to change thread priority (via [NSthread setThreadPriority:XX]), cache size (via kAudioBufferNumFrames)
 and hi water mark (by changing the line "if (wd > 2*kAudioBufferNumFrames/3)" below) depending on what else is going on
 in your app. 
 */
-(void)processAudioThread:(id)param
{
	// Each thread needs its own AutoreleasePool
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	// if we have a valid Dirac instance at this point something has gone terribly wrong!
	// In this case we don't touch anything here and just exit the thread
	if (mDirac) {
		NSLog(@" !!! Found a valid Dirac instance when attempting to create the background worker thread! This should never occur.");
		goto end;
	}
	{
	
	// LE requires a bit of additional work, since we need to reinstantiate Dirac in order to make changes to its
	// parameters (this is a restriction in LE)
	mExitThread = NO;		// indicate that we want this thread to exit
	mThreadHasExited = NO;	// indicate that we have successfully exited this thread
	
	// Before starting processing we set up our Dirac instance
	mDirac = DiracCreate(kDiracLambdaPreview, kDiracQualityPreview, kNumChannels, mSampleRate, DiracDataProviderCallback, (void*)self);
	if (!mDirac) {
		printf("!! ERROR !!\n\n\tCould not create Dirac instance\n\tCheck sample rate and number of channels!\n");
		exit(-1);
	}
	
	DiracSetProperty(kDiracPropertyTimeFactor, mTime, mDirac);
	DiracSetProperty(kDiracPropertyPitchFactor, mPitch, mDirac);

	
	// This is the number of frames each call to Dirac will add to the cache.
	long numFrames = 512;
	
	// Allocate buffer for Dirac output
	float **audio = AllocateAudioBuffer(kNumChannels, numFrames);

	
	// MAIN PROCESSING LOOP STARTS HERE
	for(;;) {
		
		if (mExitThread)
			break;
		
		// first we determine if we actually need to add new data to the cache. If the distance
		// between read and write position in the cache is still larger than 2/3 the cache size 
		// we assume there is still enough data so we simply skip processing this time
		long wd = wrappedDiff(mAudioBufferReadPos, mAudioBufferWritePos, kAudioBufferNumFrames);
		if (wd > 2*kAudioBufferNumFrames/3)
			continue;

		// call DiracProcess to produce new frames
		long ret = DiracProcess(audio, numFrames, mDirac);

		// add them to the cache
		for (long v = 0; v < numFrames; v++) {
			for (long c = 0; c < kNumChannels; c++) {
				
				float value = audio[c][v];
				
				// some settings might cause a slight increase in amplitude, make sure we don't cause nasty digital wrapping!
				if (value > 0.999f) value = 0.999f;
				else if (value < -1.f) value = -1.f;
				
				mAudioBuffer[c][mAudioBufferWritePos] = (SInt16)(value * 32768.f);
			}
			mAudioBufferWritePos++;
			if (mAudioBufferWritePos > kAudioBufferNumFrames-1)
				mAudioBufferWritePos = 0;
		}

		// we exit only if we hit EOF (see DiracDataProviderCallback for more details) or an error
		if (ret <= 0) break;
	}
		
	// Free buffer for output
	DeallocateAudioBuffer(audio, kNumChannels);

	// get rid of Dirac
	DiracDestroy(mDirac);
	mDirac = NULL;

	// ok we're done deallocating
	mThreadHasExited = YES;
	}
end:
	// release the pool
	[pool release];
}

// ---------------------------------------------------------------------------------------------------------------------------

-(void)changeDuration:(float)duration
{
	mTime = duration;								// store new value
}
// ---------------------------------------------------------------------------------------------------------------------------

-(void)changePitch:(float)pitch
{
	mPitch = pitch;								// store new value
}
// ---------------------------------------------------------------------------------------------------------------------------
/*
 This triggers creation of a new DiracLE instance that uses the new parameters. We need to do this separately from
 the actual parameter change so we don't shoot ourselves in the foot by calling this code twice
 */
-(void)commitChanges
{
	[self stop];								// stop our AudioUnit

	// LE requires a bit of additional work, since we need to reinstantiate Dirac in order to make changes to its
	// parameters (this is a restriction in LE)
	mExitThread = YES;							// we want our worker thread to exit
	for (;;) if (mThreadHasExited) break;		// wait until it has actually exited
	
	[self start];								// begin playback
	
	// kick off processing
	[NSThread detachNewThreadSelector:@selector(processAudioThread:) toTarget:self withObject:nil];
	
}
// ---------------------------------------------------------------------------------------------------------------------------

- (id) init 
{
	self = [super init];
	
	// set initial values
	mTime = mPitch = 1.;
	mExitThread = NO;
	mThreadHasExited = NO;
	
	OSStatus status = noErr;
	
	// This is boilerplate code to set up CoreAudio on iOS in order to play audio via its default output
	
	// Desired audio component
	AudioComponentDescription desc;
	desc.componentType = kAudioUnitType_Output;
	desc.componentSubType = kAudioUnitSubType_RemoteIO;
	desc.componentManufacturer = kAudioUnitManufacturer_Apple;
	desc.componentFlags = 0;
	desc.componentFlagsMask = 0;
	
	// Get ref to component
	AudioComponent defaultOutput = AudioComponentFindNext(NULL, &desc);
	
	// Get matching audio unit
	status = AudioComponentInstanceNew(defaultOutput, &mAudioUnit);
	checkStatus(status);
		
	// this is the format we want
	AudioStreamBasicDescription audioFormat;
	mSampleRate=audioFormat.mSampleRate			= 44100.00;
	audioFormat.mFormatID			= kAudioFormatLinearPCM;
	audioFormat.mFormatFlags		= kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
	audioFormat.mFramesPerPacket	= 1;
	audioFormat.mChannelsPerFrame	= kNumChannels;
	audioFormat.mBitsPerChannel		= 16;
	audioFormat.mBytesPerPacket		= sizeof(short)*kNumChannels;
	audioFormat.mBytesPerFrame		= sizeof(short)*kNumChannels;
	
	status = AudioUnitSetProperty(mAudioUnit, 
								  kAudioUnitProperty_StreamFormat, 
								  kAudioUnitScope_Input, 
								  kOutputBus, 
								  &audioFormat, 
								  sizeof(audioFormat));
	checkStatus(status);

	// here we set up CoreAudio in order to call our PlaybackCallback
	AURenderCallbackStruct callbackStruct;
	callbackStruct.inputProc = PlaybackCallback;
	callbackStruct.inputProcRefCon = self;
	status = AudioUnitSetProperty(mAudioUnit, 
								  kAudioUnitProperty_SetRenderCallback, 
								  kAudioUnitScope_Input, 
								  kOutputBus,
								  &callbackStruct, 
								  sizeof(callbackStruct));
	checkStatus(status);
	
	
	// Initialize unit
	status = AudioUnitInitialize(mAudioUnit);
	checkStatus(status);
	
	
	// This creates our reader instance that we use to read from our audio file
	NSString *inputSound  = [[NSBundle mainBundle] pathForResource:  @"voice" ofType: @"aif"];
	NSURL *inUrl = [NSURL fileURLWithPath:inputSound];
	
    mReader = [[EAFRead alloc] init];
	[mReader openFileForRead:inUrl sr:mSampleRate channels:kNumChannels];

	// here we allocate our audio cache
	mAudioBuffer = AllocateAudioBufferSInt16(kNumChannels, kAudioBufferNumFrames);
	mAudioBufferReadPos = mAudioBufferWritePos = 0;
	
	// this kicks off our background worker thread that does the actual Dirac processing
	[NSThread detachNewThreadSelector:@selector(processAudioThread:) toTarget:self withObject:nil];
	
	return self;
}
// ---------------------------------------------------------------------------------------------------------------------------
/*
 This call starts processing. We also reset Dirac in case we hit start when processing is already underway
 */
- (void) start 
{
	NSLog(@"Starting");
	DiracReset(true, mDirac);
	ClearAudioBuffer(mAudioBuffer, kNumChannels, kAudioBufferNumFrames);
	mAudioBufferReadPos = mAudioBufferWritePos = 0;
	[mReader seekToStart];

	OSStatus status = AudioOutputUnitStart(mAudioUnit);
	checkStatus(status);
}

- (void) startWithAudio: (NSURL*) url  
{
	NSLog(@"Starting");
	
    inUrl = url;
    
    DiracReset(true, mDirac);
	ClearAudioBuffer(mAudioBuffer, kNumChannels, kAudioBufferNumFrames);
	mAudioBufferReadPos = mAudioBufferWritePos = 0;
	[mReader seekToStart];
    
	OSStatus status = AudioOutputUnitStart(mAudioUnit);
	checkStatus(status);
}

// ---------------------------------------------------------------------------------------------------------------------------

- (void) stop 
{
	NSLog(@"Stopping");
	OSStatus status = AudioOutputUnitStop(mAudioUnit);
	checkStatus(status);
}
// ---------------------------------------------------------------------------------------------------------------------------

- (void) dealloc 
{
	AudioUnitUninitialize(mAudioUnit);
	[mReader release];
	DeallocateAudioBuffer(mAudioBuffer, kNumChannels);
	[super dealloc];
}

// ---------------------------------------------------------------------------------------------------------------------------
// ---------------------------------------------------------------------------------------------------------------------------
// ---------------------------------------------------------------------------------------------------------------------------
// ---------------------------------------------------------------------------------------------------------------------------
// ---------------------------------------------------------------------------------------------------------------------------
// ---------------------------------------------------------------------------------------------------------------------------
// ---------------------------------------------------------------------------------------------------------------------------
// ---------------------------------------------------------------------------------------------------------------------------
// ---------------------------------------------------------------------------------------------------------------------------
// ---------------------------------------------------------------------------------------------------------------------------
// ---------------------------------------------------------------------------------------------------------------------------

@end

