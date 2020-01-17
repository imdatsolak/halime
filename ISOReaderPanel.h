//
//  ISOReaderPanel.h
//  Halime
//
//  Created by Imdat Solak on Sun Feb 17 2002.
//  Copyright (c) 2001 Imdat Solak. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ISOReaderPanel : NSPanel
{
	int				lastKey;
	NSCharacterSet	*registeredChars;
}

- (void)keyDown:(NSEvent *)theEvent;
- (void)mouseDown:(NSEvent *)theEvent;
- (int)lastKey;
- (void)registerCharacterSetAsKeys:(NSCharacterSet *)aSet;
@end

@interface NSObject(ISOReaderPanelDelegate)
- (void)window:(id)sender spaceBarPressed:(NSEvent *)theEvent;
- (void)window:(id)sender plusKeyPressed:(NSEvent *)theEvent;
- (void)window:(id)sender minusKeyPressed:(NSEvent *)theEvent;
- (void)window:(id)sender modPlusKeyPressed:(NSEvent *)theEvent;
- (void)window:(id)sender modMinusKeyPressed:(NSEvent *)theEvent;
- (void)window:(id)sender otherKeyPressed:(NSString *)aKey;
@end
