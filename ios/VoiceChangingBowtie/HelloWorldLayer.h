#import "cocos2d.h"

#import <AVFoundation/AVFoundation.h>
#import <CoreAudio/CoreAudioTypes.h>

#import "EAFRead.h"
#import "EAFWrite.h"
#import "PigViewController.h"

@interface HelloWorldLayer : CCLayer <AVAudioPlayerDelegate, AVAudioRecorderDelegate>
{   NSURL *monitorTmpFile;
    
    AVAudioRecorder *recorder;
    AVAudioRecorder *audioMonitor;
    
    NSError *error;
    
    BOOL isRecording;
    BOOL isPlaying;
    
    float silenceTime;
    
    AVAudioPlayer *player;
	
	float percent;
	
	NSURL *inUrl;
	NSURL *outUrl;
	EAFRead *reader;
	EAFWrite *writer;
    
    float time;
	float pitch;
	float formant;
    
    PigViewController       *pigViewController;
    NSMutableData *webData;
}

@property (readonly) EAFRead *reader;
@property (nonatomic, assign) PigViewController *pigViewController;

+(CCScene *) scene;
+(CCScene *) sceneWithPigViewController:(PigViewController *)pigViewController;
-(id) init;
-(void) initAudioMonitor;
-(void) initAudioRecorder;
-(void) monitorAudioController: (ccTime) dt;
-(void) startRecording;
-(void) stopRecordingAndPlay;
-(void) playAudio;
-(void) monitorAudioPlayer: (ccTime) dt;
-(void) stopPlaying;
-(void) initDiracPlayer;
-(void)playOnMainThread:(id)param;
-(void)processThread:(id)param;
-(void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag;
-(void) dealloc;

@end
