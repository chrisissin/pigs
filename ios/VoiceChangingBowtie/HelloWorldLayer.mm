
#include "Dirac.h"
#include <stdio.h>
#include <sys/time.h>

#import <AVFoundation/AVAudioPlayer.h>
#import <AVFoundation/AVFoundation.h>

#import "HelloWorldLayer.h"


double gExecTimeTotal = 0.;

//-----------------------------------------------------------------------------------------------------------------------------------------------------------

void DeallocateAudioBuffer(float **audio, int numChannels)
{
	if (!audio) return;
	for (long v = 0; v < numChannels; v++) {
		if (audio[v]) {
			free(audio[v]);
			audio[v] = NULL;
		}
	}
	free(audio);
	audio = NULL;
}


//-----------------------------------------------------------------------------------------------------------------------------------------------------------

float **AllocateAudioBuffer(int numChannels, int numFrames)
{
	// Allocate buffer for output
	float **audio = (float**)malloc(numChannels*sizeof(float*));
	if (!audio) return NULL;
	memset(audio, 0, numChannels*sizeof(float*));
	for (long v = 0; v < numChannels; v++) {
		audio[v] = (float*)malloc(numFrames*sizeof(float));
		if (!audio[v]) {
			DeallocateAudioBuffer(audio, numChannels);
			return NULL;
		}
		else memset(audio[v], 0, numFrames*sizeof(float));
	}
	return audio;
}	


//---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/*
 This is the callback function that supplies data from the input stream/file whenever needed.
 It should be implemented in your software by a routine that gets data from the input/buffers.
 The read requests are *always* consecutive, ie. the routine will never have to supply data out
 of order.
 */
long myReadData(float **chdata, long numFrames, void *userData)
{	
	// The userData parameter can be used to pass information about the caller (for example, "self") to
	// the callback so it can manage its audio streams.
	if (!chdata)	return 0;
	
	HelloWorldLayer *Self = (HelloWorldLayer*)userData;
	if (!Self)	return 0;
	
	// we want to exclude the time it takes to read in the data from disk or memory, so we stop the clock until 
	// we've read in the requested amount of data
	gExecTimeTotal += DiracClockTimeSeconds(); 		// ............................. stop timer ..........................................
    
	OSStatus err = [Self.reader readFloatsConsecutive:numFrames intoArray:chdata];
	
	DiracStartClock();								// ............................. start timer ..........................................
    
	return err;
}

#define AUDIOMONITOR_THRESHOLD 0.005
#define MAX_SILENCETIME 1

@implementation HelloWorldLayer

@synthesize reader;
@synthesize pigViewController;

+(CCScene *) sceneWithPigViewController:(PigViewController *)pigViewController
{
	CCScene *scene = [CCScene node];
	
	HelloWorldLayer *layer = [HelloWorldLayer node];
    layer.pigViewController = pigViewController;
	
	[scene addChild: layer];
	
	return scene;
}

-(id) init
{
	if( (self=[super init])) 
    {	
        CGSize size = [[CCDirector sharedDirector] winSize];
        
		CCLabelTTF *label = [CCLabelTTF labelWithString:@"Hello World" fontName:@"Marker Felt" fontSize:64];
        label.position =  ccp( size.width /2 , size.height/2 );
		[self addChild: label];
        
        CCSprite *bowtie = [CCSprite spriteWithFile: @"bowtie.jpg"];
        bowtie.position =  ccp( size.width /2 , size.height/2 );
		[self addChild: bowtie];
        
        [self initAudioMonitor];
        [self initAudioRecorder];
        
        // DIRAC parameters
        time      = 1;  
        pitch     = 0.75;
        formant   = pow(2., 0./12.);
        
        [self schedule:@selector(monitorAudioController:)];
	}
	return self;
}

-(void) initAudioMonitor
{    NSMutableDictionary* recordSetting = [[NSMutableDictionary alloc] init];
    [recordSetting setValue :[NSNumber numberWithInt:kAudioFormatAppleIMA4] forKey:AVFormatIDKey];
    [recordSetting setValue:[NSNumber numberWithFloat:44100.0] forKey:AVSampleRateKey]; 
    [recordSetting setValue:[NSNumber numberWithInt: 1] forKey:AVNumberOfChannelsKey];
    
    NSArray* documentPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* fullFilePath = [[documentPaths objectAtIndex:0] stringByAppendingPathComponent: @"monitor.caf"];
    monitorTmpFile = [NSURL fileURLWithPath:fullFilePath];
    
    audioMonitor = [[ AVAudioRecorder alloc] initWithURL: monitorTmpFile settings:recordSetting error:&error];
    
    [audioMonitor setMeteringEnabled:YES];
    
    [audioMonitor setDelegate: self];
    
    [audioMonitor record];
}

-(void) initAudioRecorder
{    NSMutableDictionary* recordSetting = [[NSMutableDictionary alloc] init];
    [recordSetting setValue :[NSNumber numberWithInt:kAudioFormatAppleIMA4] forKey:AVFormatIDKey];
    [recordSetting setValue:[NSNumber numberWithFloat:44100.0] forKey:AVSampleRateKey]; 
    [recordSetting setValue:[NSNumber numberWithInt: 1] forKey:AVNumberOfChannelsKey];
    
    NSArray* documentPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* fullFilePath = [[documentPaths objectAtIndex:0] stringByAppendingPathComponent: @"in.caf"];
    inUrl = [NSURL fileURLWithPath:fullFilePath];
    
    recorder = [[ AVAudioRecorder alloc] initWithURL: inUrl settings:recordSetting error:&error];
    
    
    [recorder setMeteringEnabled:YES];
    
    [recorder setDelegate: self];
    
    [recorder prepareToRecord];
}

-(void) monitorAudioController: (ccTime) dt
{   
    if(!isPlaying)
    {   [audioMonitor updateMeters];
        
        // a convenience, it’s converted to a 0-1 scale, where zero is complete quiet and one is full volume
        const double ALPHA = 0.05;
        double peakPowerForChannel = pow(10, (0.05 * [audioMonitor peakPowerForChannel:0]));
        double audioMonitorResults = ALPHA * peakPowerForChannel + (1.0 - ALPHA) * audioMonitorResults;
        
        //NSLog(@"audioMonitorResults: %f", audioMonitorResults);
        
        if (audioMonitorResults > AUDIOMONITOR_THRESHOLD)
        {   //NSLog(@"Sound detected");
            
            if(!isRecording)
            {   [audioMonitor stop];
                [self startRecording];
            }
        }   else
        {   //NSLog(@"Silence detected");
            if(isRecording)
            {   if(silenceTime > MAX_SILENCETIME)
                {   
                    NSLog(@"Next silence detected");
                    [audioMonitor stop];
                    [self stopRecordingAndPlay];
                    silenceTime = 0;
                }   else
                {   silenceTime += dt;
                }
            }
        }
    }
}

-(void) startRecording
{   NSLog(@"startRecording");
    
    isRecording = YES;
    [recorder record];
}

-(void) stopRecordingAndPlay
{   NSLog(@"stopRecording Record time: %f", [recorder currentTime]);
    
    isRecording = NO;
    [recorder stop];
        
    isPlaying = YES;
    //[self playAudio];
    [self initDiracPlayer];

}

-(void) playAudio
{   NSLog(@"playAudio");
    
    player = [[AVAudioPlayer alloc] initWithContentsOfURL: inUrl error:&error];
    [player prepareToPlay];
    [player play];
    
    [self schedule:@selector(monitorAudioPlayer:)];
}

-(void) monitorAudioPlayer: (ccTime) dt
{   if(![player isPlaying])
    {   NSLog(@"finishedPlayingAudio");
        isPlaying = NO;
        [audioMonitor record];
        [self unschedule:@selector(monitorAudioPlayer:)];
    }
}

-(void) stopPlaying
{   isPlaying = NO;
    [audioMonitor record];
}

-(void) initDiracPlayer
{   NSString *outputSound = [[[NSHomeDirectory() stringByAppendingString:@"/Documents/"] stringByAppendingString:@"out.aif"] retain];
	outUrl = [[NSURL fileURLWithPath:outputSound] retain];
	reader = [[EAFRead alloc] init];
	writer = [[EAFWrite alloc] init];
    /*
    [pigViewController.webView stringByEvaluatingJavaScriptFromString:@"var script = document.createElement('script');"  
     "script.type = 'text/javascript';"  
     "script.text = \"function myFunction() { "  
     "alert(11111);"  
     "}\";"  
     "document.getElementsByTagName('head')[0].appendChild(script);"];  
    
    [pigViewController.webView stringByEvaluatingJavaScriptFromString:@"myFunction();"];         

    */    
    NSString *soapMessage = @"<?xml version='1.0' encoding='utf-8'?>n"
    "<soap:Envelope xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance' xmlns:xsd='http://www.w3.org/2001/XMLSchema' xmlns:soap='http://schemas.xmlsoap.org/soap/envelope/'>n"
    "<soap:Body>n"
    "<CelsiusToFahrenheit xmlns='http://tempuri.org/'>n"
    "<Celsius>50</Celsius>n"
    "</CelsiusToFahrenheit>n"
    "</soap:Body>n"
    "</soap:Envelope>n";    
    
    NSURL *url = [NSURL URLWithString:@"http://catchmachine.tpcity.corp.yahoo.com:3838/audio"];
    NSMutableURLRequest *theRequest = [NSMutableURLRequest requestWithURL:url];
    NSString *msgLength = [NSString stringWithFormat:@"%d", [soapMessage length]];
    
    [theRequest addValue: @"text/xml; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    [theRequest addValue: @"http://tempuri.org/CelsiusToFahrenheit" forHTTPHeaderField:@"SOAPAction"];
    [theRequest addValue: msgLength forHTTPHeaderField:@"Content-Length"];
    [theRequest setHTTPMethod:@"POST"];
    [theRequest setHTTPBody: [soapMessage dataUsingEncoding:NSUTF8StringEncoding]];
    
    NSURLConnection *theConnection = [[NSURLConnection alloc] initWithRequest:theRequest delegate:self];
    
    if( theConnection )
    {
        webData = [[NSMutableData data] retain];
    }
    else
    {
        NSLog(@"theConnection is NULL");
    }    
    
	// this thread does the processing
	[NSThread detachNewThreadSelector:@selector(processThread:) toTarget:self withObject:nil];
}


-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    [webData setLength: 0];
}
-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [webData appendData:data];
}
-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    NSLog(@"ERROR with theConenction");
    [connection release];
    [webData release];
}
-(void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSLog(@"DONE. Received Bytes: %d", [webData length]);
    NSString *theXML = [[NSString alloc] initWithBytes: [webData mutableBytes] length:[webData length] encoding:NSUTF8StringEncoding];
    NSLog(@"%@",theXML);
    
    NSString *str = [NSString stringWithFormat:@"var script = document.createElement('script');"  
                     "script.type = 'text/javascript';"  
                     "script.text = \"function myFunction() { "  
                     "alert(%@);"  
                     "}\";"  
                     "document.getElementsByTagName('head')[0].appendChild(script);", theXML];
    
    [pigViewController.webView stringByEvaluatingJavaScriptFromString:str];  
    
    [pigViewController.webView stringByEvaluatingJavaScriptFromString:@"myFunction();"];         
    
    
    
    
    [theXML release];
}
 

-(void)playOnMainThread:(id)param
{
	player = [[AVAudioPlayer alloc] initWithContentsOfURL:outUrl error:&error];
	if (error)
		NSLog(@"AVAudioPlayer error %@, %@", error, [error userInfo]);
    
	player.delegate = self;
	[player play];
}

-(void)processThread:(id)param
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
	long numChannels = 1;		// DIRAC LE allows mono only
	float sampleRate = 44100;
    
	// open input file
	[reader openFileForRead:inUrl sr:sampleRate channels:numChannels];
	
	// create output file (overwrite if exists)
	[writer openFileForWrite:outUrl sr:sampleRate channels:numChannels wordLength:16 type:kAudioFileAIFFType];	
	
	// First we set up DIRAC to process numChannels of audio at 44.1kHz
	// N.b.: The fastest option is kDiracLambdaPreview / kDiracQualityPreview, best is kDiracLambda3, kDiracQualityBest
	// The probably best *default* option for general purpose signals is kDiracLambda3 / kDiracQualityGood
	void *dirac = DiracCreate(kDiracLambdaPreview, kDiracQualityPreview, numChannels, sampleRate, &myReadData, (void*)self);
	//	void *dirac = DiracCreate(kDiracLambda3, kDiracQualityBest, numChannels, sampleRate, &myReadData);
	if (!dirac) {
		printf("!! ERROR !!\n\n\tCould not create DIRAC instance\n\tCheck number of channels and sample rate!\n");
		printf("\n\tNote that the free DIRAC LE library supports only\n\tone channel per instance\n\n\n");
		exit(-1);
	}
	
	// Pass the values to our DIRAC instance 	
	DiracSetProperty(kDiracPropertyTimeFactor, time, dirac);
	DiracSetProperty(kDiracPropertyPitchFactor, pitch, dirac);
	DiracSetProperty(kDiracPropertyFormantFactor, formant, dirac);
    
	// upshifting pitch will be slower, so in this case we'll enable constant CPU pitch shifting
	if (pitch > 1.0)
		DiracSetProperty(kDiracPropertyUseConstantCpuPitchShift, 1, dirac);
    
	// Print our settings to the console
	//DiracPrintSettings(dirac);
	
	NSLog(@"Running DIRAC version %s\nStarting processing", DiracVersion());
	
	// Get the number of frames from the file to display our simplistic progress bar
	SInt64 numf = [reader fileNumFrames];
	SInt64 outframes = 0;
	SInt64 newOutframe = numf*time;
	long lastPercent = -1;
	percent = 0;
	
	// This is an arbitrary number of frames per call. Change as you see fit
	long numFrames = 8192;
	
	// Allocate buffer for output
	float **audio = AllocateAudioBuffer(numChannels, numFrames);
    
	double bavg = 0;
	
	// MAIN PROCESSING LOOP STARTS HERE
	for(;;) {
		
		// Display ASCII style "progress bar"
		percent = 100.f*(double)outframes / (double)newOutframe;
		long ipercent = percent;
		if (lastPercent != percent) {
			/**
            printf("\rProgress: %3i%% [%-40s] ", ipercent, &"||||||||||||||||||||||||||||||||||||||||"[40 - ((ipercent>100)?40:(2*ipercent/5))] );
			**/
            lastPercent = ipercent;
			fflush(stdout);
		}
		
		DiracStartClock();								// ............................. start timer ..........................................
		
		// Call the DIRAC process function with current time and pitch settings
		// Returns: the number of frames in audio
		long ret = DiracProcess(audio, numFrames, dirac);
		bavg += (numFrames/sampleRate);
		gExecTimeTotal += DiracClockTimeSeconds();		// ............................. stop timer ..........................................
		
        /**
		printf("x realtime = %3.3f : 1 (DSP only), CPU load (peak, DSP+disk): %3.2f%%\n", bavg/gExecTimeTotal, DiracPeakCpuUsagePercent(dirac));
		**/
        
		// Process only as many frames as needed
		long framesToWrite = numFrames;
		unsigned long nextWrite = outframes + numFrames;
		if (nextWrite > newOutframe) framesToWrite = numFrames - nextWrite + newOutframe;
		if (framesToWrite < 0) framesToWrite = 0;
		
		// Write the data to the output file
		[writer writeFloats:framesToWrite fromArray:audio];
		
		// Increase our counter for the progress bar
		outframes += numFrames;
		
		// As soon as we've written enough frames we exit the main loop
		if (ret <= 0) break;
	}
	
	percent = 100;
	
	// Free buffer for output
	DeallocateAudioBuffer(audio, numChannels);
	
	// destroy DIRAC instance
	DiracDestroy( dirac );
	
	// Done!
	NSLog(@"\nDone!");
	
	[reader release];
	[writer release]; // important - flushes data to file
	
	// start playback on main thread
	[self performSelectorOnMainThread:@selector(playOnMainThread:) withObject:self waitUntilDone:NO];
	
	[pool release];
}

// done playing
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{   isPlaying = NO;
    [audioMonitor record];
}

- (void) dealloc
{
    [monitorTmpFile release];
    [recorder release];
    [audioMonitor release];
    [player release];
	[inUrl release];
	[outUrl release];
	[reader release];
	[writer release];
    
	[super dealloc];
}
@end
