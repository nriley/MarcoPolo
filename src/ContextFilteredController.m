//
//  ContextFilteredController.m
//  MarcoPolo
//
//  Created by David Symonds on 8/10/07.
//

#import "ContextFilteredController.h"
#import "ContextTree.h"


@implementation ContextFilteredController

- (void)awakeFromNib
{
	[outlineView setDataSource:[ContextTree sharedInstance]];
	[outlineView bind:@"selectionIndexPaths"
		 toObject:self
	      withKeyPath:@"selectionIndexPaths"
		  options:nil];

	[self rearrangeObjects];
}

#pragma mark Selection

- (NSString *)selectedContext
{
	return selectedContext;
}

- (void)setSelectedContext:(NSString *)newSelectedContext
{
	if (selectedContext != newSelectedContext) {
		[selectedContext autorelease];
		selectedContext = [newSelectedContext copy];
		[self rearrangeObjects];
	}
}

- (NSArray *)selectionIndexPaths
{
	ContextTree *tree = [ContextTree sharedInstance];
	Context *ctxt = [tree contextByUUID:selectedContext];
	if (!ctxt)
		return [NSArray array];
	return [NSArray arrayWithObject:[ctxt valueForKey:@"indexPath"]];
}

- (void)setSelectionIndexPaths:(NSArray *)indexPaths
{
	if ([indexPaths count] > 0)
		[self setSelectedContext:[[[ContextTree sharedInstance] contextByIndexPath:[indexPaths objectAtIndex:0]] uuid]];
	else
		[self setSelectedContext:nil];
}

#pragma mark NSArrayController overrides

- (NSArray *)arrangeObjects:(NSArray *)objectsToArrange
{
	ContextTree *tree = [ContextTree sharedInstance];
	Context *ctxt = [tree contextByUUID:selectedContext];
	if (!ctxt)
		return [super arrangeObjects:objectsToArrange];

	NSMutableArray *subset = [NSMutableArray arrayWithCapacity:[objectsToArrange count]];

	NSEnumerator *en = [objectsToArrange objectEnumerator];
	id object;
	while ((object = [en nextObject])) {
		NSString *uuid = [object valueForKey:@"context"];
		// TODO: handle context hierarchy properly?
		if (!uuid || ![selectedContext isEqualToString:uuid])
			continue;
		[subset addObject:object];
	}

	return [super arrangeObjects:subset];
}

@end
