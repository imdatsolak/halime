//
//  ISOLogger.m
//  Halime
//
//  Created by Imdat Solak on Fri Feb 15 2002.
//  Copyright (c) 2001 Imdat Solak. All rights reserved.
//

#import "ISOLogger.h"
#import "version.h"

id ISOActiveLogger;

@implementation ISOLogger
static ISOLogger *sharedLogger = nil;

+ sharedLogger
{
	if (sharedLogger == nil) {
		sharedLogger = [[self alloc] init];
	}
	ISOActiveLogger = sharedLogger;
	return sharedLogger;
}

- init
{
	if (!sharedLogger) {
		sharedLogger = [super init];
	} else {
		[self dealloc];
	}
	curLoglevel = 0;
	curDebuglevel = 0;
	return sharedLogger;
}

- (void)setDebuglevel:(int)aLevel
{
	curDebuglevel = aLevel;
}

- (void)incrementLoglevel
{
	curLoglevel++;
}

- (void)decrementLoglevel
{
	curLoglevel--;
}

- (void)logWithDebuglevel:(int)dl :(NSString *)fmt, ...
{
    va_list			argList;

	if (curDebuglevel >= dl) {
		int				i;
		NSString 		*formattedString;
		NSCalendarDate	*date = [NSCalendarDate calendarDate];
		NSString		*dateStr = [date descriptionWithCalendarFormat:@"%Y-%m-%d %H:%M:%S.%F"];

		va_start(argList, fmt);
		formattedString = [[NSString alloc] initWithFormat:fmt arguments:argList];
		va_end(argList);
		fprintf(stdout, "%s Halime[%s]:+", [dateStr cString], [K_CURRENTVERSIONSTRING cString]);
		for (i=0;i<curLoglevel;i++) {
			fprintf(stdout, "-");
		}
		fprintf(stdout, "> %s\n", [formattedString cString]);
		[formattedString release];
	}
}


@end
