//
//  ActionWithTwoLimitedOptions.m
//  MarcoPolo
//
//  Created by David Symonds on 28/12/07.
//

#import "ActionWithTwoLimitedOptions.h"


@implementation ActionWithTwoLimitedOptions

- (id)init
{
	if (!(self = [super initWithNibNamed:@"ActionWithTwoLimitedOptions"]))
		return nil;

	[[NSNotificationCenter defaultCenter] addObserver:self
						 selector:@selector(popUpButtonActivated:)
						     name:NSPopUpButtonWillPopUpNotification
						   object:secondPopUpButton];

	return self;
}

- (NSMutableDictionary *)readFromPanel
{
	NSMutableDictionary *dict = [super readFromPanel];

	id sel1 = [[firstParameterController arrangedObjects] objectAtIndex:[firstParameterController selectionIndex]];
	id sel2 = [[secondParameterController arrangedObjects] objectAtIndex:[secondParameterController selectionIndex]];
	NSArray *param = [NSArray arrayWithObjects:
		[sel1 valueForKey:@"parameter"], [sel2 valueForKey:@"parameter"], nil];

	[dict setValue:param forKey:@"parameter"];
	if (![dict objectForKey:@"description"])
		[dict setValue:[self descriptionOf:dict] forKey:@"description"];

	return dict;
}

- (void)selectOrInsert:(NSDictionary *)dict inController:(NSArrayController *)controller
{
	NSEnumerator *en = [[controller arrangedObjects] objectEnumerator];
	unsigned int index = 0;
	NSObject *thisParam = [dict valueForKey:@"parameter"];
	NSDictionary *elt;
	while ((elt = [en nextObject])) {
		if ([[elt valueForKey:@"parameter"] isEqualTo:thisParam])
			break;
		++index;
	}
	if (elt) {
		// Found!
		[controller setSelectionIndex:index];
	} else {
		// Push existing one in, since it isn't there
		[controller setSelectsInsertedObjects:YES];
		[controller addObject:dict];
	}
}

- (void)writeToPanel:(NSDictionary *)dict
{
	[super writeToPanel:dict];

	[leadTextField setStringValue:[self leadText]];
	[leadTextField flexToFit];

	[firstParameterController removeObjects:[firstParameterController arrangedObjects]];
	[firstParameterController addObjects:[self firstSuggestions]];
	[secondParameterController removeObjects:[secondParameterController arrangedObjects]];
	[secondParameterController addObjects:[self secondSuggestions]];

	NSObject *param = [dict objectForKey:@"parameter"];
	if (param && ![param isKindOfClass:[NSArray class]])
		param = nil;
	if (param && ([(NSArray *) param count] != 2))
		param = nil;

	if (!param) {
		[firstParameterController selectNext:self];
		[secondParameterController selectNext:self];
	} else {
		NSArray *paramArray = (NSArray *) param;
		NSObject *one = [paramArray objectAtIndex:0], *two = [paramArray objectAtIndex:1];
		[self selectOrInsert:[NSDictionary dictionaryWithObjectsAndKeys:
			@"?", @"description", one, @"parameter", nil]
			inController:firstParameterController];
		[self selectOrInsert:[NSDictionary dictionaryWithObjectsAndKeys:
			@"?", @"description", two, @"parameter", nil]
			inController:secondParameterController];
	}
}

- (NSString *)leadText
{
	[self doesNotRecognizeSelector:_cmd];
	return nil;
}

- (NSArray *)firstSuggestions
{
	[self doesNotRecognizeSelector:_cmd];
	return nil;
}

- (NSArray *)secondSuggestions
{
	[self doesNotRecognizeSelector:_cmd];
	return nil;
}

#pragma mark -

- (void)popUpButtonActivated:(NSNotification *)notification
{
	// If the dictionary corresponding to a menu item is empty (i.e. no key-value pairs),
	// then we will replace it will a separator item.
	NSPopUpButton *button = [notification object];
	NSMenu *menu = [button menu];
	int i;
	for (i = 0; i < [menu numberOfItems]; ++i) {
		NSDictionary *dict = [[secondParameterController arrangedObjects] objectAtIndex:i];
		if ([dict count] == 0) {
			// This menu item should be a separator
			[menu removeItemAtIndex:i];
			[menu insertItem:[NSMenuItem separatorItem] atIndex:i];
		}
	}
}

@end
