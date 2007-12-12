//
//  ActionSettingMailServer.m
//  MarcoPolo
//
//  Created by David Symonds on 11/12/07.
//

#import "ActionSettingMailServer.h"


@implementation ActionSettingMailServer

- (id)init
{
	if (!(self = [super initWithNibNamed:@"MailServerAction"]))
		return nil;

	return self;
}

- (NSMutableDictionary *)readFromPanel
{
	NSMutableDictionary *dict = [super readFromPanel];

	NSDictionary *selAccount = [[accountController arrangedObjects] objectAtIndex:[accountController selectionIndex]];
	NSString *selServer = [[serverController arrangedObjects] objectAtIndex:[serverController selectionIndex]];
	NSDictionary *parameter = [NSDictionary dictionaryWithObjectsAndKeys:
		[selAccount valueForKey:@"parameter"], @"account", selServer, @"server", nil];

	[dict setValue:parameter forKey:@"parameter"];
	if (![dict objectForKey:@"description"])
		[dict setValue:[self descriptionOf:dict] forKey:@"description"];

	return dict;
}

- (void)writeToPanel:(NSDictionary *)dict
{
	[super writeToPanel:dict];

	[leadTextField setStringValue:[self leadText]];
	[leadTextField flexToFit];

	// Build account set
	[accountController removeObjects:[accountController arrangedObjects]];
	[accountController addObject:
		[NSDictionary dictionaryWithObjectsAndKeys:
			kAllMailAccounts, @"parameter",
			NSLocalizedString(@"All accounts", @"In account list for Mail server actions"), @"description", nil]];
	NSEnumerator *en = [[self accountOptions] objectEnumerator];
	NSString *acc;
	while ((acc = [en nextObject]))
		[accountController addObject:[NSDictionary dictionaryWithObjectsAndKeys:
			acc, @"parameter", acc, @"description", nil]];

	// Build server set
	[serverController removeObjects:[serverController arrangedObjects]];
	[serverController addObjects:[self serverOptions]];

	NSDictionary *currentParam = [dict valueForKey:@"parameter"];
	if (currentParam) {
		// Check the existence of expected keys
		if (![currentParam objectForKey:@"account"] ||
		    ![currentParam objectForKey:@"server"]) {
			NSLog(@"Ignoring broken Mail server action parameter: %@", currentParam);
			currentParam = nil;
		}
	}

	if (!currentParam) {
		[accountController selectNext:self];
		[serverController selectNext:self];
	} else {
		// Pick the current parameters from the lists

		// First, the account
		acc = [currentParam valueForKey:@"account"];
		NSEnumerator *en = [[accountController arrangedObjects] objectEnumerator];
		unsigned int index = 0;
		NSDictionary *elt;
		while ((elt = [en nextObject])) {
			if ([[elt valueForKey:@"parameter"] isEqualToString:acc])
				break;
			++index;
		}
		if (elt) {
			// Found!
			[accountController setSelectionIndex:index];
		} else {
			// Push existing one in, since it isn't there
			[accountController setSelectsInsertedObjects:YES];
			[accountController addObject:[NSDictionary dictionaryWithObjectsAndKeys:
				acc, @"parameter", acc, @"description", nil]];
		}

		// Next, the server
		NSString *srv = [currentParam valueForKey:@"server"];
		index = [[serverController arrangedObjects] indexOfObject:srv];
		if (index != NSNotFound) {
			// Found!
			[serverController setSelectionIndex:index];
		} else {
			// Push existing one in, since it isn't there
			[serverController setSelectsInsertedObjects:YES];
			[serverController addObject:srv];
		}
	}
}

- (NSString *)leadText
{
	[self doesNotRecognizeSelector:_cmd];
	return nil;
}

- (NSArray *)accountOptions
{
	NSString *script =
		@"tell application \"Mail\"\n"
		"  get name of every account\n"
		"end tell";

	NSArray *list = [self executeAppleScriptReturningListOfStrings:script];
	if (!list)		// failure
		return [NSArray array];
	return list;
}

- (NSArray *)serverOptions
{
	[self doesNotRecognizeSelector:_cmd];
	return nil;
}

@end
