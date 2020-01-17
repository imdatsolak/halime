//
//  ISOJobViewCell.h
//  Halime
//
//  Created by Imdat Solak on Sun Mar 10 2002.
//  Copyright (c) 2001 Imdat Solak. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ISOJob.h"

@interface ISOJobViewCell : NSActionCell
{
	NSImage	*piImage;
	BOOL	cleanedUp;
	ISOJob	*job;
	NSLock	*mutex;
	float	minValue;
	float	maxValue;
	float	doubleValue;
	BOOL	isIndeterminate;
	int		indeterminateImageNo;
}

- (id)initTextCell:(NSString *)aString;
- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView;
- (void)setMinValue:(double)minValue;
- (double)minValue;
- (void)setMaxValue:(double)maxValue;
- (double)maxValue;
- (void)animate:sender;
- (void)incrementBy:(double)delta;
- (void)setIndeterminate:(BOOL)flag;
- (void)setDoubleValue:(double)value;
- (void)cleanUp;
- (void)setJob:(ISOJob *)aJob;
- (ISOJob *)job;
@end
