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

static const int RECORD_TICK_MAX = 11;

@interface ViewController ()

@end

@implementation ViewController {
    Reachability *reachability;
    AVAudioRecorder *recorder;
    int currentTick;
    NSTimer *timer;
    NSTimer *playback;
    NSTimer *recordTime;
    Sound *currentSound;
    int currentIndex;
    NSMutableArray *sounds;
    NSArray *tempSounds;
    BOOL soundsLoaded;
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
    sounds = [[NSMutableArray alloc] init];
    tempSounds = [[NSArray alloc] init];
    soundsLoaded = NO;
    
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
                               @"ByteRecord.m4a",
                               nil];
    NSURL *outputFileURL = [NSURL fileURLWithPathComponents:pathComponents];
    
    // Setup audio session
    AVAudioSession *session = [AVAudioSession sharedInstance];
    BOOL sessionGood = [session setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    
    if (!sessionGood) {
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
    if (!ableToRecord) {
       NSLog(@"ERROR! CANNOT RECORD!");
    }
    
    currentTick = 0;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Sound Methods

- (void)getSounds {
    
    if (tempSounds.count < 1) {
        NSLog(@"Getting sounds...");
        //NSDate *currentDate = [NSDate date];
        PFQuery *query = [Sounds query];
        [query whereKey:@"expired" equalTo:[NSNumber numberWithBool:false]];
        //[query whereKey:@"createdAt" greaterThanOrEqualTo:currentDate];
        query.cachePolicy = kPFCachePolicyNetworkOnly;
        query.limit = 20;
        [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            //sounds = [NSMutableArray arrayWithArray:objects];
            [sounds addObjectsFromArray:objects];
            if (error) {
                NSLog(@"ERROR: %@",error);
            } else {
                NSLog(@"Sounds Retrieved!");
                [sounds shuffle];
            }
        }];
    } else {
        sounds = [NSMutableArray arrayWithArray:tempSounds];
        [sounds shuffle];
        tempSounds = [[NSArray alloc] init];
        soundsLoaded = NO;
        NSLog(@"Loaded Next Set of Sounds!");
    }
    
}

- (void)loadNextSongs {
    NSLog(@"Getting Next Sounds...");
    //NSDate *currentDate = [NSDate date];
    PFQuery *query = [Sounds query];
    [query whereKey:@"expired" equalTo:[NSNumber numberWithBool:false]];
    //[query whereKey:@"createdAt" greaterThanOrEqualTo:currentDate];
    query.cachePolicy = kPFCachePolicyNetworkOnly;
    query.limit = 20;
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        tempSounds = [NSMutableArray arrayWithArray:objects];
        if (error) {
            NSLog(@"ERROR: %@",error);
        } else {
            soundsLoaded = YES;
            NSLog(@"Next Sounds Retrieved!");
        }
    }];

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
        [self startTimer];
        [self startRecordProgressBar];
        
    } else {
        
        // Pause recording
        [recorder pause];
        [self stopTimer:NO];
        [self stopRecordProgressTick];
        [self.recordPauseBtn setTitle:@"Record" forState:UIControlStateNormal];
    }
    
    [self.stopButton setEnabled:YES];
    [self.playButton setEnabled:NO];
    
}

- (IBAction)playTapped {
    if (!recorder.recording) {
        Sound *sound = [Sound soundWithContentsOfURL:recorder.url];
        [[SoundManager sharedManager] playMusic:sound looping:NO];
        currentSound = sound;
        [self startPlayback];
    }
}

- (IBAction)stopTapped {
    [recorder stop];
    
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setActive:NO error:nil];
    [self stopTimer:YES];
    [self saveSoundToCloud];
}

- (void)saveSoundToCloud {
    PFFile *saveSound = [PFFile fileWithName:@"sb" contentsAtPath:recorder.url.path];
//    [saveSound saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
//        if (!succeeded) {
//           NSLog(@"ERROR: %@", error);
//        }
//    }];
    
    Sounds *sound = [Sounds object];
    sound.byte = saveSound;
    sound.expired = false;
    [sound saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            NSLog(@"Sound Saved Successfully!");
        } else {
            NSLog(@"ERROR: %@", error);
        }
    }];
    
}

- (void)cloudPlay {
    if (!recorder.recording) {
        
        PFObject *object = [sounds objectAtIndex:currentIndex];
        Sounds *cloudSound = (Sounds *)object;
        
        NSArray *pathComponents = [NSArray arrayWithObjects:
                                   [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject],
                                   @"BytePlay.m4a",
                                   nil];
        NSURL *outputFileURL = [NSURL fileURLWithPathComponents:pathComponents];
        
        
        PFFile *file = cloudSound.byte;
        [file getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
            
            [data writeToURL:outputFileURL atomically:true];
            
            Sound *s = [Sound soundWithContentsOfURL:outputFileURL];
            currentSound = s;
            
            [[SoundManager sharedManager] playMusic:s looping:NO];
            [self startPlayback];
            [self incrementIndex];
            self.cloudplay.enabled = NO;
            
        }];
        
        
        
    }
}

- (void) audioRecorderDidFinishRecording:(AVAudioRecorder *)avrecorder successfully:(BOOL)flag{
    [self.recordPauseBtn setTitle:@"Record" forState:UIControlStateNormal];
    
    [self.stopButton setEnabled:NO];
    [self.playButton setEnabled:YES];
}

- (void)soundFinished:(Sound *)sound {
    NSLog(@"Success! Sound completed!");
    [self stopPlayTick];
    self.cloudplay.enabled = YES;
}

- (void)incrementIndex {
    int size = sounds.count - 1;
    if (currentIndex + 1 > size) {
        currentIndex = 0;
        //FOR NOW I WILL SIMPLY SHUFFLE AGAIN
        [self getSounds];
        //[sounds shuffle];
    } else {
        currentIndex++;
        if (!soundsLoaded) {
            if (currentIndex > sounds.count/2) {
                [self loadNextSongs];
            }
        }
    }
}


#pragma mark - Timer Methods

- (void)startTimer {
    timer = [NSTimer scheduledTimerWithTimeInterval:1
                                     target:self
                                   selector:@selector(tick:)
                                   userInfo:nil
                                    repeats:YES];
    [timer fire];
}

- (void)tick:(NSTimer *) timer {
    currentTick++;
    if (currentTick > RECORD_TICK_MAX) {
        [self stopTimer:YES];
        [self stopTapped];
    }
    //self.progressBar.progress = (float)currentTick/RECORD_TICK_MAX;
    //NSLog(@"Tick: %d", currentTick);
}

- (void)stopTimer:(BOOL)reset {
    [timer invalidate];
    if (reset) {
        currentTick = 0;
        self.progressBar.progress = 0.0;
    }
}

- (void)startRecordProgressBar {
    recordTime = [NSTimer scheduledTimerWithTimeInterval:0.01
                                                target:self
                                              selector:@selector(recordProgressTick:)
                                              userInfo:nil
                                               repeats:YES];
}

- (void)recordProgressTick:(NSTimer *)timer {
    self.progressBar.progress = (float)recorder.currentTime/RECORD_TICK_MAX;
    if (self.progressBar.progress == 0.0) {
        [self stopRecordProgressTick];
    }
    //NSLog(@"Tick: %d", currentTick);
}

- (void)stopRecordProgressTick {
    [recordTime invalidate];
}

- (void)startPlayback {
    playback = [NSTimer scheduledTimerWithTimeInterval:0.01
                                             target:self
                                           selector:@selector(playtick:)
                                           userInfo:nil
                                            repeats:YES];
}

- (void)playtick:(NSTimer *)timer {
    self.progressBar.progress = (float)currentSound.currentTime/RECORD_TICK_MAX;
    //NSLog(@"Tick: %d", currentTick);
}

- (void)stopPlayTick {
    [playback invalidate];
    self.progressBar.progress = 0.0;
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
