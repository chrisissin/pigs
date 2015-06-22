/*--------------------------------------------------------------------------------
 
 Dirac.h
 Version 3.2.5 [1103211600]
 
 Copyright (C) 2005-2011 The DSP Dimension,
 Stephan M. Bernsee (SMB)
 All rights reserved
 
 CONFIDENTIAL: This document contains confidential information. 
 Do not disclose any information contained in this document to any
 third-party without the prior written consent of Stephan M. Bernsee/
 The DSP Dimension.
 
 --------------------------------------------------------------------------------*/

// This file contains all the constants and prototypes for the "real" DIRAC calls
// that you will need in your project.


#ifndef __DIRAC__
#define __DIRAC__



// Windows DLL definitions
// ----------------------------------------------------------------------------

#ifndef TARGET_API_MAC_CARBON

#ifdef DIRAC_AS_DLL
#define DLL_DEF_TYPE __declspec(dllexport)
#else
#define DLL_DEF_TYPE
#endif

#else
#define DLL_DEF_TYPE __attribute__((visibility("default")))
#endif

// Function prototypes
// ----------------------------------------------------------------------------
#ifdef __cplusplus
extern "C" {
#endif
	
	DLL_DEF_TYPE const char *DiracVersion(void);
	DLL_DEF_TYPE void DiracPrintSettings(void *dirac);
	DLL_DEF_TYPE const char *DiracErrorToString(long error);
	DLL_DEF_TYPE void *DiracCreate(long lambda, long quality, long numChannels, float sampleRate, long (*readFromChannelsCallback)(float **data, long numFrames, void *userData), void *userData);
	DLL_DEF_TYPE void *DiracCreateInterleaved(long lambda, long quality, long numChannels, float sampleRate, long (*readFromInterleavedChannelsCallback)(float *data, long numFrames, void *userData), void *userData);
	DLL_DEF_TYPE long DiracSetProperty(long selector, long double value, void *dirac);
	DLL_DEF_TYPE long double DiracGetProperty(long selector, void *dirac);
	DLL_DEF_TYPE void DiracReset(bool clear, void *dirac);
	DLL_DEF_TYPE long DiracProcess(float **audioOut, long numFrames, void *dirac);
	DLL_DEF_TYPE long DiracProcessInterleaved(float *audioOut, long numFrames, void *dirac);
	DLL_DEF_TYPE void DiracDestroy(void *dirac);
	DLL_DEF_TYPE long double DiracValidateStretchFactor(long double factor);
	DLL_DEF_TYPE void DiracStartClock(void);
	DLL_DEF_TYPE long double DiracClockTimeSeconds(void);
	DLL_DEF_TYPE float DiracPeakCpuUsagePercent(void *dirac);
	
	// available in PRO only	
	DLL_DEF_TYPE long DiracSetTuningTable(float *frequencyTable, long numFrequencies, void *dirac);
	
	/* This is the interface for DIRAC3's Retune algorithm. Not available in DiracLE */
	DLL_DEF_TYPE void *DiracRetuneCreate(long quality, float sampleRateHz, bool effectMode);
	DLL_DEF_TYPE void DiracRetuneDestroy(void *instance);
	DLL_DEF_TYPE void DiracRetuneProcess(short *indata, short *outdata, long numSampsToProcess, void *instance);
	DLL_DEF_TYPE void DiracRetuneProcessFloat(float *indata, float *outdata, long numSampsToProcess, void *instance);
	DLL_DEF_TYPE void DiracRetuneSetTuningTable(float *frequencyTable, long numFrequencies, void *instance);
	DLL_DEF_TYPE void DiracRetuneSetTuningReferenceHz(float referenceTuningHz, void *instance);
	DLL_DEF_TYPE void DiracRetuneSetPitchHz(float pitchHz, void *instance);
	DLL_DEF_TYPE float DiracRetuneGetPitchHz(void *instance);
	DLL_DEF_TYPE void DiracRetuneSetProperties(float correctionAmountPercent, 
											   float correctionThresholdCent, 
											   float correctionSlurTime, 
											   float correctionSibilanceBypassThreshold, 
											   float correctionEffectModeMinimumNoteLength, 
											   float correctionEffectModeStableNoteTolerance, 
											   float correctionEffectModeOnsetFrequencySensitivity, 
											   float correctionEffectModeOnsetEnergySensitivity, 
											   void *instance);
	
	
	
#ifdef __cplusplus
}
#endif




// Property enums
// ----------------------------------------------------------------------------

enum
{
	kDiracPropertyPitchFactor = 100,
	kDiracPropertyTimeFactor,
	kDiracPropertyFormantFactor,
	kDiracPropertyCompactSupport,
	kDiracPropertyCacheGranularity,
	kDiracPropertyCacheMaxSizeFrames,
	kDiracPropertyCacheNumFramesLeftInCache,
	kDiracPropertyUseConstantCpuPitchShift,
	kDiracPropertyDoPitchCorrection,
	kDiracPropertyPitchCorrectionBasicTuningHz = 400,
	kDiracPropertyPitchCorrectionSlurTime,
	kDiracPropertyPitchCorrectionDoFormantCorrection = 500,
	kDiracPropertyPitchCorrectionFundamentalFrequency,
	
	kDiracPropertyNumProperties
};

enum
{
	kDiracRetunePropertyCorrectionBasicTuningHz = 400,
	kDiracRetunePropertyCorrectionSlurTime,
	kDiracRetunePropertyCorrectionAmountPercent,
	kDiracRetunePropertyCorrectionThresholdCent,
	kDiracRetunePropertyCorrectionSibilanceBypassThreshold,
	kDiracRetunePropertyCorrectionEffectMode,
	kDiracRetunePropertyCorrectionEffectModeMinimumNoteLength,
	kDiracRetunePropertyCorrectionEffectModeStableNoteTolerance,
	kDiracRetunePropertyCorrectionEffectModeOnsetFrequencySensitivity,
	kDiracRetunePropertyCorrectionEffectModeOnsetEnergySensitivity,
	kDiracRetunePropertyCorrectionFundamentalFrequency = 501,
	
	kDiracRetunePropertyNumProperties
};


// Lambda enums
// ----------------------------------------------------------------------------

enum
{
	kDiracLambdaPreview = 200,
	kDiracLambda1,
	kDiracLambda2,
	kDiracLambda3,
	kDiracLambda4,
	kDiracLambda5,
	kDiracLambdaTranscribe,
	kDiracLambdaRetune,
	
	kDiracPropertyNumLambdas
};




// Quality enums
// ----------------------------------------------------------------------------

enum
{
	kDiracQualityPreview = 300,	
	kDiracQualityGood,
	kDiracQualityBetter,
	kDiracQualityBest,
	
	kDiracPropertyNumQualities
};



// Error enums
// ----------------------------------------------------------------------------
enum
{
	kDiracErrorNoErr		= 0,	
	kDiracErrorParamErr		= -1,
	kDiracErrorUnknownErr	= -2,
	kDiracErrorInvalidCb	= -3,
	kDiracErrorCacheErr		= -4,
	kDiracErrorNotInited	= -5,
	kDiracErrorMultipleInits	= -6,
	kDiracErrorFeatureNotSupported	= -7,
	kDiracErrorMemErr		= -108,
	kDiracErrorDemoTimeoutReached = -10001,
	
	kDiracErrorNumErrs
};





#endif /* __DIRAC__ */


