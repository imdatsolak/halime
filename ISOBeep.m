//
//  ISOBeep.m
//  Halime
//
//  Created by iso on Thu Aug 16 2001.
//  Copyright (c) 2001 Imdat Solak. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ISOBeep.h"


@implementation ISOBeep
static NSString *reason = nil;
static NSString *description = nil;
static NSString *helpI = nil;
static int callCount = 1;
+ beep:(NSString *)beepReason withDescription:(NSString *)descString andHelp:(NSString *)helpIndex
{
    if ([reason isEqual:beepReason]) {
        callCount++;
    } else {
        callCount = 1;
    }
    reason = beepReason;
    description = descString;
    helpI = helpIndex;
    if (callCount == 3) {
        [self whyTheBeep:self];
        callCount = 0;
    } else {
        NSBeep();
    }
    return self;
}

+ beep:(NSString *)beepReason withDescription:(NSString *)descString
{
    return [self beep:beepReason withDescription:descString andHelp:nil];
}
    
+ beep:(NSString *)beepReason
{
    return [self beep:beepReason withDescription:nil andHelp:nil];
}

+ whyTheBeep:sender
{
    NSRunAlertPanel (NSLocalizedString(@"Why The Beep?", @""), NSLocalizedString(reason, @""), NSLocalizedString(@"Ah, I see, thanks!", @""),nil,nil);
    return self;
}

@end
