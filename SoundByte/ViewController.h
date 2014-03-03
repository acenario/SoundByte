//
//  ViewController.h
//  SoundByte
//
//  Created by Arjun Bhatnagar on 1/17/14.
//  Copyright (c) 2014 Productions. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "NSMutableArray+Shuffling.h"

@interface ViewController : UIViewController <AVAudioRecorderDelegate, AVAudioPlayerDelegate>

@property (strong, nonatomic) IBOutlet UIButton *recordPauseBtn;
@property (strong, nonatomic) IBOutlet UIButton *playButton;
@property (strong, nonatomic) IBOutlet UIButton *stopButton;
@property (strong, nonatomic) IBOutlet UIProgressView *progressBar;
@property (strong, nonatomic) IBOutlet UIButton *cloudplay;

- (IBAction)recordPause;
- (IBAction)playTapped;
- (IBAction)stopTapped;
- (IBAction)cloudPlay;

@end
