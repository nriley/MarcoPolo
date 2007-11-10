//
//  ContextSelectionButton.m
//  MarcoPolo
//
//  Created by David Symonds on 6/07/07.
//

#import "ContextSelectionButton.h"
#import "ContextTree.h"


@implementation ContextSelectionButton

- (void)awakeFromNib
{
	[self reloadData];
}

// Should be passed a UUID
- (void)setSelectedObject:(id)arg
{
	if (!arg) {
		[self selectItem:nil];
		return;
	}

	NSEnumerator *en = [[self itemArray] objectEnumerator];
	NSMenuItem *item;
	while ((item = [en nextObject])) {
		NSString *uuid = [item representedObject];
		if ([uuid isEqualToString:arg]) {
			[self selectItem:item];
			break;
		}
	}
}

- (void)contextsChanged:(NSNotification *)notification
{
	NSString *previousSelection = nil;

	// Update menu
	if ([self menu]) {
		previousSelection = [[self selectedItem] representedObject];
		[[NSNotificationCenter defaultCenter] removeObserver:self
								name:nil
							      object:[self menu]];
	}
	[self setMenu:[[ContextTree sharedInstance] hierarchicalMenu]];
	[[NSNotificationCenter defaultCenter] addObserver:self
						 selector:@selector(selectionChanged:)
						     name:NSMenuDidSendActionNotification
						   object:[self menu]];
	if (previousSelection)
		[self setValue:previousSelection forKey:@"selectedObject"];
}

- (void)reloadData
{
	// Watch for notifications of context changes
	[[NSNotificationCenter defaultCenter] addObserver:self
						 selector:@selector(contextsChanged:)
						     name:@"ContextsChangedNotification"
						   object:[ContextTree sharedInstance]];
	[self contextsChanged:nil];
}

- (void)selectionChanged:(NSNotification *)notification
{
	NSMenuItem *item = [[notification userInfo] objectForKey:@"MenuItem"];
	[self setValue:[item representedObject] forKey:@"selectedObject"];
}

@end
