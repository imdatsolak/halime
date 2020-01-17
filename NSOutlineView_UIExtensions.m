// $Id: NSOutlineView_UIExtensions.m,v 1.1 2001/07/05 17:48:48 cwolf Exp $

/*********************************************************************
 *
 * Copyright (c) 2001, Christopher Wolf
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions 
 * are met:
 *
 *  * Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer. 
 *
 *  * Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in
 *    the documentation and/or other materials provided with the
 *    distribution. 
 * 
 *  * Neither the name of the author nor the names of its contributors
 *    may be used to endorse or promote products derived from this
 *    software without specific prior written permission. 
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
 * REGENTS OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
 * ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 *
 ********************************************************************/

/*********************************************************************
 *
 * This file contains source code written by:
 * Christopher Wolf - cwolf@wolfware.com
 *
 *********************************************************************
 *
 * This file contains portions of source code from:
 *
 ********************************************************************/


#import "NSOutlineView_UIExtensions.h"

@implementation NSOutlineView(UIExtensions)


/*****
 * Item selection
 *****/


- (void) selectItem: (id)anItem
/*"
    Select the specified item. 
"*/
{

    [self selectRow: [self rowForItem: anItem] byExtendingSelection: NO];
    
}


- (id) selectedItem
/*
    Returns the selected item.
*/
{

    int row = [self selectedRow];

    if (row == -1)
    {
        return nil;
    }
    return [self itemAtRow: row];

}


- (NSArray *) selectedItems
/*
    Returns an array of the selected items.
*/
{

    NSEnumerator *selectedRowEnumerator = [self selectedRowEnumerator];
    NSMutableArray *selectedItems = [NSMutableArray arrayWithCapacity: [self numberOfSelectedRows]];
    NSNumber *rowNumber;

    while ((rowNumber = [selectedRowEnumerator nextObject]))
    {
        [selectedItems addObject: [self itemAtRow: [rowNumber intValue]]];
    }
    return selectedItems;

}


- (NSArray *) expandedItems
/*
    Returns an array of the expanded items.
*/
{

    NSMutableArray *expandedItems = [NSArray array];
    unsigned int row;
    
    for (row = 0; row < [self numberOfRows]; row++)
    {
        id item = [self itemAtRow: row];
        if ([self isItemExpanded: item])
        {
            [expandedItems addObject: item];
        }
    }
    
    return expandedItems;
    
}


- (void) reloadDataPreservingSelection
/*
    Reload the outline-view but, if possible, do not trash the selection.
*/
{
    NSObject *selection = [self selectedItem];
    [self reloadData];
    if (selection) {
		if ([self lockFocusIfCanDraw]) {
			[self selectItem: selection];
			[self scrollRowToVisible: [self rowForItem: selection]];
			[self unlockFocus];
		}
    }
}

- (void)selectItems:(NSArray*)items byExtendingSelection:(BOOL)extend
{
    int i;
    if (extend==NO) [self deselectAll:nil];
    for (i=0;i<[items count];i++) {
        int row = [self rowForItem:[items objectAtIndex:i]];
        if(row>=0) [self selectRow: row byExtendingSelection:extend];
    }
}

@end


