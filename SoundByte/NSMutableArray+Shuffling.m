//
//  NSMutableArray+Shuffling.m
//  SoundByte
//
//  Created by Arjun Bhatnagar on 3/3/14.
//  Copyright (c) 2014 Productions. All rights reserved.
//

#import "NSMutableArray+Shuffling.h"

@implementation NSMutableArray (Shuffling)

- (void)shuffle
{
    NSUInteger count = [self count];
    for (NSUInteger i = 0; i < count; ++i) {
        // Select a random element between i and end of array to swap with.
        NSInteger nElements = count - i;
        //Suppressed Warning by signing the number of elements into a 32-bit architecture, not good really, but when will we have an array bigger than 2^31?
        NSInteger n = arc4random_uniform((uint32_t)nElements) + i;
        [self exchangeObjectAtIndex:i withObjectAtIndex:n];
    }
}


@end
