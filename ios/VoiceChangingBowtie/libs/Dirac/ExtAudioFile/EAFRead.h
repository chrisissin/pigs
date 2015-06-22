
/*--------------------------------------------------------------------------------
 
 EAFRead.h
 
 Copyright (C) 2009-2011 The DSP Dimension,
 Stephan M. Bernsee (SMB)
 All rights reserved
 
 --------------------------------------------------------------------------------*/


#include <AudioToolbox/AudioToolbox.h>


@interface EAFRead : NSObject {
 	ExtAudioFileRef mExtAFRef;
   int mExtAFNumChannels;
	double mExtAFRateRatio;
	BOOL mExtAFReachedEOF;
}

- (OSStatus) openFileForRead:(NSURL*)fileURL sr:(Float64)sampleRate channels:(int)numChannels;
- (OSStatus) readFloatsConsecutive:(SInt64)numFrames intoArray:(float**)audio;
- (OSStatus) readShortsConsecutive:(SInt64)numFrames intoArray:(short**)audio;
- (OSStatus) closeFile;
- (SInt64) fileNumFrames;
- (void) seekToStart;
- (void) seekToPercent:(Float64)percent;

@end
