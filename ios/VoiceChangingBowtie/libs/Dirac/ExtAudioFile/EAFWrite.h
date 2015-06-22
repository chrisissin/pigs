

/*--------------------------------------------------------------------------------
 
 EAFWrite.h
 
 Copyright (C) 2009-2011 The DSP Dimension,
 Stephan M. Bernsee (SMB)
 All rights reserved
 
 --------------------------------------------------------------------------------*/

#include <AudioToolbox/AudioToolbox.h>


@interface EAFWrite : NSObject 
{
	ExtAudioFileRef mOutputAudioFile;
	
	UInt32	mAudioChannels;
	AudioStreamBasicDescription	mOutputFormat;
	
	AudioStreamBasicDescription	mStreamFormat;
	AudioFileTypeID mType;
	AudioFileID mAfid;
}

-(void)SetupStreamAndFileFormatForType:(AudioFileTypeID)aftid withSR:(float) sampleRate channels:(long) numChannels wordlength:(long)numBits;
- (OSStatus) openFileForWrite:(NSURL*)inPath sr:(Float64)sampleRate channels:(int)numChannels wordLength:(int)numBits type:(AudioFileTypeID)aftid;
- (void) closeFile;
-(OSStatus) writeFloats:(long)numFrames fromArray:(float **)data;
-(OSStatus) writeShorts:(long)numFrames fromArray:(short **)data;


@end
