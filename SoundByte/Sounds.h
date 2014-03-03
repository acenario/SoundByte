//
//  Sounds.h
//  SoundByte
//
//  Created by Arjun Bhatnagar on 1/17/14.
//  Copyright (c) 2014 Productions. All rights reserved.
//

#import <Parse/Parse.h>

@interface Sounds : PFObject <PFSubclassing>
+ (NSString *)parseClassName;

@property (retain) PFFile *byte;
@property BOOL expired;



@end
