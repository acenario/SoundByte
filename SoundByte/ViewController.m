//
//  ViewController.m
//  SoundByte
//
//  Created by Arjun Bhatnagar on 1/17/14.
//  Copyright (c) 2014 Productions. All rights reserved.
//

#import "ViewController.h"
#import "Sounds.h"
#import "Reachability.h"
#import "SoundManager.h"

@interface ViewController ()

@end

@implementation ViewController {
    Reachability *reachability;
    AVAudioRecorder *recorder;
}

#pragma mark - Loading Methods

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:YES];
    
    
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:YES];
    
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupReachability];
    if (reachability.currentReachabilityStatus == NotReachable) {
        NSLog(@"Cannot get sounds!");
    } else {
        [self getSounds];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(soundFinished:)
                                                 name:SoundDidFinishPlayingNotification
                                               object:nil];
    
    [self.stopButton setEnabled:NO];
    [self.playButton setEnabled:NO];
    
    // Set the audio file
    NSArray *pathComponents = [NSArray arrayWithObjects:
                               [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject],
                               @"MyAudioMemo.m4a",
                               nil];
    NSURL *outputFileURL = [NSURL fileURLWithPathComponents:pathComponents];
    
    // Setup audio session
    AVAudioSession *session = [AVAudioSession sharedInstance];
    BOOL sessionGood = [session setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    
    if (sessionGood) {
        NSLog(@"Session is ready to go boss");
    } else {
        NSLog(@"It's a no go!");
    }
    
    // Define the recorder setting
    NSMutableDictionary *recordSetting = [[NSMutableDictionary alloc] init];
    
    [recordSetting setValue:[NSNumber numberWithInt:kAudioFormatMPEG4AAC] forKey:AVFormatIDKey];
    [recordSetting setValue:[NSNumber numberWithFloat:44100.0] forKey:AVSampleRateKey];
    [recordSetting setValue:[NSNumber numberWithInt: 2] forKey:AVNumberOfChannelsKey];
    
    // Initiate and prepare the recorder
    recorder = [[AVAudioRecorder alloc] initWithURL:outputFileURL settings:recordSetting error:NULL];
    recorder.delegate = self;
    recorder.meteringEnabled = YES;
    
   BOOL ableToRecord = [recorder prepareToRecord];
    if (ableToRecord) {
        NSLog(@"All Good to go mate");
    } else {
        NSLog(@"ERROR!");
    }
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Sound Methods

- (void)getSounds {
    NSLog(@"Getting sounds...");
}

- (IBAction)recordPause {
    if ([[SoundManager sharedManager] isPlayingMusic]) {
        [[SoundManager sharedManager] stopMusic];
    }
    
    if (!recorder.recording) {
        AVAudioSession *session = [AVAudioSession sharedInstance];
        [session setActive:YES error:nil];
        
        // Start recording
        [recorder record];
        [self.recordPauseBtn setTitle:@"Pause" forState:UIControlStateNormal];
        
    } else {
        
        // Pause recording
        [recorder pause];
        [self.recordPauseBtn setTitle:@"Record" forState:UIControlStateNormal];
    }
    //
    [self.stopButton setEnabled:YES];
    [self.playButton setEnabled:NO];
    
}

- (IBAction)playTapped {
    if (!recorder.recording) {
        Sound *sound = [Sound soundWithContentsOfURL:recorder.url];
        [[SoundManager sharedManager] playMusic:sound looping:NO];
    }
    
    
    
}

- (IBAction)stopTapped {
    [recorder stop];
    
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setActive:NO error:nil];
}

- (void) audioRecorderDidFinishRecording:(AVAudioRecorder *)avrecorder successfully:(BOOL)flag{
    [self.recordPauseBtn setTitle:@"Record" forState:UIControlStateNormal];
    
    [self.stopButton setEnabled:NO];
    [self.playButton setEnabled:YES];
}

- (void)soundFinished:(Sound *)sound {
    NSLog(@"Success! Song was: %@", sound.name);
}


#pragma mark - Reachability Methods

- (void)reachabilityChanged:(NSNotification*)notification
{
    if (reachability.currentReachabilityStatus == NotReachable) {
        NSLog(@"No internet connection!");
    } else {
        //Enable things
        NSLog(@"Yay internet connection!");
    }
    
}

- (void)setupReachability {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];
    
    reachability = [Reachability reachabilityForInternetConnection];
    [reachability startNotifier];
}

@end
