//
//  ISOJobViewMgr.m
//  Halime
//
//  Created by Imdat Solak on Sat Jan 19 2002.
//  Copyright (c) 2001 Imdat Solak. All rights reserved.
//

#import "ISOSubscriptionMgr.h"
#import "ISOJobMgr.h"
#import "ISOJob.h"
#import "ISOJobViewMgr.h"
#import "ISOJobViewCell.h"
#import "ISOLogger.h"


@implementation ISOJobViewMgr
static id	sharedJobViewMgr = nil;
+ sharedJobViewMgr
{
	if (!sharedJobViewMgr) {	
		sharedJobViewMgr = [[ISOJobMgr sharedJobMgr] newJobViewMgr];
	}
	return sharedJobViewMgr;
}

- init
{
	if (sharedJobViewMgr) {
		[self dealloc];
		return sharedJobViewMgr;
	} else {
		[super init];
		sharedJobViewMgr = self;
		showingWindow = NO;
	}
	return self;
}

- (void)reloadJobTable
{
	int				i, count;
	int				j;
	int 			existingRows;
	ISOJobViewCell	*aCell;
	
	if ([[ISOJobMgr sharedJobMgr] tryLock]) {
		existingRows = [jobTable numberOfRows];
		count = [[ISOJobMgr sharedJobMgr] numberOfJobs];
		for (j=existingRows-1;j>=0;j--) {
			BOOL	found = NO;
			aCell = [jobTable cellAtRow:j column:0];
			for (i=0;i<count;i++) {
				if ([[ISOJobMgr sharedJobMgr] jobAtIndex:i] == [aCell job]) {
					found = YES;
					break;
				}
			}
			if (!found) {
				[((ISOJobViewCell *)[jobTable cellAtRow:j column:0]) cleanUp];
				[jobTable removeRow:j];
			}
		}
	
		count = [[ISOJobMgr sharedJobMgr] numberOfJobs];
		existingRows = [jobTable numberOfRows];
		for (i=0;i<count;i++) {
			BOOL 	jobFound = NO;
			ISOJob	*theJob = [[ISOJobMgr sharedJobMgr] jobAtIndex:i];
			for (j=0;j<existingRows;j++) {
				aCell = [jobTable cellAtRow:j column:0];
				if ([aCell job] == theJob) {
					jobFound = YES;
					break;
				}
			}
			if (!jobFound) {
				[jobTable addRow];
				aCell = [jobTable cellAtRow:[jobTable numberOfRows]-1 column:0];
				[aCell setJob:theJob];
			}
		}
		[jobTable sizeToCells];
		[jobTable setNeedsDisplay:YES];
		[[ISOJobMgr sharedJobMgr] unlock];
	}
}

- (void)showWithOrdering:(BOOL)orderRelatively
{
	int	rowIndex;
	if (!jobTable) {
        if (![NSBundle loadNibNamed:@"ISOJobsView" owner:self])  {
            [ISOActiveLogger logWithDebuglevel:1 :@"Failed to load ISOJobsView.nib"];
            NSBeep();
            return;
        }
		[[jobTable window] setLevel:NSNormalWindowLevel];
	}
	showingWindow = YES;
	if (orderRelatively) {
		[[jobTable window] orderWindow:NSWindowBelow relativeTo:[[[NSApplication sharedApplication] keyWindow] windowNumber]];
	} else {
		[[jobTable window] orderFront:self];
	}
	[jobTable setCellClass:[ISOJobViewCell class]];
	[jobTable setCellSize:NSMakeSize(405, 32)];
	[((NSMatrix *)jobTable) setMode:NSListModeMatrix];
	[jobTable setAllowsEmptySelection:YES];
	[jobTable setAutosizesCells:YES];
	[jobTable setDrawsBackground:YES];
	[jobTable setDrawsCellBackground:YES];
	[self reloadJobTable];
	rowIndex = [jobTable selectedRow];
	
	[killButton setEnabled:rowIndex >= 0];
	[startButton setEnabled:rowIndex >= 0];
	[upButton setEnabled:rowIndex >= 0];
	[downButton setEnabled:rowIndex >= 0];
}


- (void)manualShow
{
	[self showWithOrdering:NO];
}

- (void)automaticShow
{
	[self showWithOrdering:YES];
}

- (void)show
{
	[self showWithOrdering:NO];
}

- (void)jobSelected:sender
{
	int	rowIndex = [jobTable selectedRow];
	
	[killButton setEnabled:(rowIndex >=0)];
	[startButton setEnabled:(rowIndex >=0)];
	[upButton setEnabled:(rowIndex >=0)];
	[downButton setEnabled:(rowIndex >=0)];
}

- (void)kill:sender
{
	id	jobMgr = [ISOJobMgr sharedJobMgr];
	int	rowIndex = [jobTable selectedRow];
	[jobMgr cancelJobWithIdent:[jobMgr identOfJobAtIndex:rowIndex]];
}

- (void)start:sender
{
	id	jobMgr = [ISOJobMgr sharedJobMgr];
	int	rowIndex = [jobTable selectedRow];
	[jobMgr startJobWithIdent:[jobMgr identOfJobAtIndex:rowIndex]];
}

- (void)down:sender
{
}

- (void)up:sender
{
}

- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [[ISOJobMgr sharedJobMgr] numberOfJobs];
}


- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	if (rowIndex >= 0 && (rowIndex < [[ISOJobMgr sharedJobMgr] numberOfJobs])) {
		if ([(NSString *)[aTableColumn identifier] compare:@"JOB"] == NSOrderedSame) {
			NSString *aString = [NSString stringWithFormat:@"%@\n%@", [[[ISOJobMgr sharedJobMgr] jobAtIndex:rowIndex] jobname],
			[[[[[ISOJobMgr sharedJobMgr] jobAtIndex:rowIndex] subscriptionMgr] theSubscription] subscriptionName]];

			[[aTableColumn dataCellForRow:rowIndex] setJob:[[ISOJobMgr sharedJobMgr] jobAtIndex:rowIndex]];
			return aString;
		}
	}
	return @"";
}

- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	[[aTableColumn dataCellForRow:rowIndex] setJob:[[ISOJobMgr sharedJobMgr] jobAtIndex:rowIndex]];
}

- cleanUp
{
	[jobTable setDataSource:nil];
	[killButton setTarget:nil];
	[startButton setTarget:nil];
	[upButton setTarget:nil];
	[downButton setTarget:nil];
	jobTable = nil;
	killButton = nil;
	startButton = nil;
	upButton = nil;
	downButton = nil;
	return self;
}

- (void)reflectJobChanges
{
	int	rowIndex = [jobTable selectedRow];
	
	if (showingWindow) {
		[self reloadJobTable];
		[[jobTable window] update];
		[[jobTable window] flushWindow];
		if ([[ISOJobMgr sharedJobMgr] numberOfJobs] == 0) {
			[[jobTable window] orderOut:self];
			showingWindow = NO;
		}
	}
	[killButton setEnabled:rowIndex >= 0];
	[startButton setEnabled:rowIndex >= 0];
	[upButton setEnabled:rowIndex >= 0];
	[downButton setEnabled:rowIndex >= 0];
}

- (id)progressIndicatorForJob:(ISOJob *)aJob
{
	int	index = [[ISOJobMgr sharedJobMgr] indexOfJob:aJob];
	if (index >= 0) {
		return [jobTable cellAtRow:index column:0];
	}
	return nil;
}

- (void)cleanUpJobAtIndex:(int)index
{
	if (index >= 0) {
		[((ISOJobViewCell *)[jobTable cellAtRow:index column:0]) cleanUp];
	}
	if ([[ISOJobMgr sharedJobMgr] numberOfJobs] == 0) {
		[[jobTable window] orderOut:self];
		showingWindow = NO;
	}
}

- (void)toggleDisplay
{
	if (showingWindow) {
		[[jobTable window] orderOut:self];
		showingWindow = NO;
	} else {
		[self manualShow];
	}
}

- (void)windowWillClose:(NSNotification *)aNotification
{
	showingWindow = NO;
}
@end
