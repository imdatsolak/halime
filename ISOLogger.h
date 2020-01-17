//
//  ISOLogger.h
//  Halime
//
//  Created by Imdat Solak on Fri Feb 15 2002.
//  Copyright (c) 2001 Imdat Solak. All rights reserved.
//

#import <Foundation/Foundation.h>

extern id ISOActiveLogger;

@interface ISOLogger : NSObject
{
	int	curLoglevel;
	int	curDebuglevel;
}

+ sharedLogger;
- init;
- (void)setDebuglevel:(int)aLevel;
- (void)incrementLoglevel;
- (void)decrementLoglevel;
- (void)logWithDebuglevel:(int)dl :(NSString *)fmt, ...;

@end
