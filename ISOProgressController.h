//
//  ISOProgressController.h
//  Halime
//
//  Created by iso on Fri Aug 17 2001.
//  Copyright (c) 2001 Imdat Solak. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface ISOProgressController : NSObject 
{
    id			progressView;
    id			window;
    double		minValue;
    double		maxValue;
    NSString	*title;
    NSString	*message;
    BOOL		isIndefinite;
    id			delegate;
    id			titleField;
    id			messageField;
    id			displayStringField;
    NSTimer		*theTimer;
}

- initWithDelegate:anObject title:(NSString *)aTitle andMessage:(NSString *)aMessage;
- setIndefinite:(BOOL)flag;
- start:sender;
- stepForwardBy:(int)step;
- stepBackwardBy:(int)step;
- justStep:sender;
- (void)setMinValue:(double)aValue;
- (void)setMaxValue:(double)aValue;
- setDisplayString:(NSString *)aString;
- reset:sender;
- stop:sender;
- (void)checkForCommandDot:sender;

@end

@interface NSObject(ISOProgressControllerDelegate)
- (BOOL)userWantsToCancelProgress:sender;
@end
