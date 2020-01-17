//
//  ISOProgressController.m
//  Halime
//
//  Created by iso on Fri Aug 17 2001.
//  Copyright (c) 2001 Imdat Solak. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ISOProgressController.h"
#import "ISOLogger.h"


@implementation ISOProgressController

- initWithDelegate:anObject title:(NSString *)aTitle andMessage:(NSString *)aMessage
{
    [super init];
    if (![NSBundle loadNibNamed:@"ISOProgress" owner:self])  {
        [ISOActiveLogger logWithDebuglevel:1 :@"Failed to load ISOProgress.nib"];
        NSBeep();
        [self dealloc];
        return nil;
    } else {
        delegate = anObject;
        minValue = 0;
        maxValue = 100;
        isIndefinite = YES;
        message = aMessage;
        title = aTitle;
        [message retain];
        [title retain];
        theTimer = nil;
        return self;
    }
}

- (void)dealloc
{
    [message release];
    [title release];
    [theTimer invalidate];
    [theTimer dealloc];
    [super dealloc];
}

- setIndefinite:(BOOL)flag
{
    isIndefinite = flag;
    [progressView setIndeterminate:flag];
    return self;
}

- start:sender
{
    [window makeKeyAndOrderFront:self];
	[window setLevel:NSNormalWindowLevel];
    [titleField setStringValue:title];
    [messageField setStringValue:message];
    [titleField display];
    [messageField display];
    [progressView setUsesThreadedAnimation:YES];
    if (isIndefinite) {
        [progressView startAnimation:self];
    }
	// theTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(checkForCommandDot:) userInfo:nil repeats:YES];
    return self;
}

- stepForwardBy:(int)step
{
    if (!isIndefinite) {
        [progressView incrementBy:step];
    }
    [progressView displayIfNeeded];
    return self;
}

- stepBackwardBy:(int)step
{
    if (!isIndefinite) {
        [progressView setDoubleValue:[progressView doubleValue]-step];
    }
    [progressView displayIfNeeded];
    return self;
}


- justStep:sender
{
    if (!isIndefinite) {
        [progressView incrementBy:1];
    }
    [progressView displayIfNeeded];
    return self;
}

- (void)setMinValue:(double)aValue
{
    minValue = aValue;
    [progressView setMinValue:aValue];
}

- (void)setMaxValue:(double)aValue
{
    maxValue = aValue;
    [progressView setMaxValue:maxValue];
}


- setDisplayString:(NSString *)aString
{
    [displayStringField setStringValue:aString];
    [displayStringField display];
    return self;
}


- reset:sender
{
    if (!isIndefinite) {
        [progressView setDoubleValue:minValue];
    }
    [progressView displayIfNeeded];
    return self;
}


- stop:sender
{
    if (isIndefinite) {
        [progressView stopAnimation:self];
    }
    [theTimer invalidate];
    [theTimer dealloc];
    theTimer = nil;
    [window orderOut:self];
    return self;
}

- (void)checkForCommandDot:sender
{
    NSEvent	*anEvent = [NSApp currentEvent];
    NSRange	aRange;
    
    if ([anEvent type] == NSKeyDown) {
        aRange = [[anEvent charactersIgnoringModifiers] rangeOfString:@"."];
        if (aRange.length == 1) {
            if ([anEvent modifierFlags] & NSCommandKeyMask) {
                if (delegate && [delegate respondsToSelector:@selector(userWantsToCancelProgress:)]) {
                    [delegate userWantsToCancelProgress:self];
                }
            }
        }
    }
    //
}

@end
