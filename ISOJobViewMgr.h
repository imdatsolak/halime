//
//  ISOJobViewMgr.h
//  Halime
//
//  Created by Imdat Solak on Sat Jan 19 2002.
//  Copyright (c) 2001 Imdat Solak. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ISOJob.h"

@interface ISOJobViewMgr : NSObject
{
	id	jobTable;
	id	killButton;
	id	startButton;
	id	upButton;
	id	downButton;
	BOOL	showingWindow;
}

+ sharedJobViewMgr;
- init;
- (void)manualShow;
- (void)automaticShow;
- (void)show;

- (void)jobSelected:sender;
- (void)kill:sender;
- (void)start:sender;
- (void)down:sender;
- (void)up:sender;
- (int)numberOfRowsInTableView:(NSTableView *)aTableView;
- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex;
- cleanUp;
- (void)reflectJobChanges;
- (id)progressIndicatorForJob:(ISOJob *)aJob;
- (void)cleanUpJobAtIndex:(int)index;
- (void)toggleDisplay;
@end
