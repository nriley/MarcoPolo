//
//  AdiumAction.m
//  MarcoPolo
//
//  Created by David Symonds on 28/12/07.
//

#import "AdiumAction.h"


@implementation AdiumAction

- (NSString *)descriptionOf:(NSDictionary *)actionDict
{
	NSString *account = [[actionDict valueForKey:@"parameter"] objectAtIndex:0];
	NSString *status = [[[actionDict valueForKey:@"parameter"] objectAtIndex:1] objectAtIndex:1];

	if ([account isEqualToString:kAllAdiumAccounts])
		return [NSString stringWithFormat:NSLocalizedString(@"Setting status of all Adium accounts to '%@'.", @""),
			status];
	return [NSString stringWithFormat:NSLocalizedString(@"Setting status of Adium account '%@' to '%@'.", @""),
		account, status];
}

- (BOOL)execute:(NSDictionary *)actionDict error:(NSString **)errorString
{
	NSString *account = [[actionDict valueForKey:@"parameter"] objectAtIndex:0];
	NSArray *status = [[actionDict valueForKey:@"parameter"] objectAtIndex:1];
	NSString *statusID = [status objectAtIndex:2];

	NSString *script;
	// TODO: escape parameters?
	if ([account isEqualToString:kAllAdiumAccounts]) {
		script = [NSString stringWithFormat:
			@"tell application \"Adium\"\n"
			"  set the status of every account to status id %@\n"
			"end tell", statusID];
	} else {
		script = [NSString stringWithFormat:
			@"tell application \"Adium\"\n"
			"  set acc to the first account whose title is \"%@\"\n"
			"  set the status of acc to status id %@\n"
			"end tell", account, statusID];
	}

	if (![self executeAppleScript:script]) {
		*errorString = NSLocalizedString(@"Couldn't set Adium status!", @"In AdiumAction");
		return NO;
	}

	return YES;
}

- (NSString *)leadText
{
	return NSLocalizedString(@"Set Adium status:", @"");
}

- (NSArray *)firstSuggestions
{
	// Get all accounts, along with their respective service names
	NSString *script =
		@"tell application \"Adium\"\n"
		"  set accList to {}\n"
		"  repeat with acc in every account\n"
		"    copy {title of service of acc, title of acc} to end of accList\n"
		"  end repeat\n"
		"  get accList\n"
		"end tell";

	NSArray *list = [self executeAppleScriptReturningListOfListOfStrings:script];
	if (!list)		// failure
		return [NSArray array];

	NSMutableArray *arr = [NSMutableArray arrayWithCapacity:[list count] + 1];
	[arr addObject:
		[NSDictionary dictionaryWithObjectsAndKeys:
			kAllAdiumAccounts, @"parameter",
			NSLocalizedString(@"All accounts", @"In account list for actions"), @"description", nil]];

	NSEnumerator *en = [list objectEnumerator];
	NSArray *acc;
	while ((acc = [en nextObject])) {
		// acc is something like ["GTalk", "dsymonds@gmail.com"]
		NSString *service = [acc objectAtIndex:0], *account = [acc objectAtIndex:1];
		NSString *desc = [NSString stringWithFormat:@"%@ (%@)", account, service];
		NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
			desc, @"description", account, @"parameter", nil];
		[arr addObject:dict];
	}

	return arr;	
}

int compareStatus(id dict1, id dict2, void *context)
{
	NSArray *status1 = [dict1 valueForKey:@"parameter"], *status2 = [dict2 valueForKey:@"parameter"];
	NSString *type1 = [status1 objectAtIndex:0], *type2 = [status2 objectAtIndex:0];

	// First, sort statuses to group them like Adium does:
	//	- available
	//	- invisible
	//	- away
	//	- offline
	NSArray *typeRank = [NSArray arrayWithObjects:@"available", @"invisible", @"away", @"offline", nil];
	int rank1 = [typeRank indexOfObject:type1], rank2 = [typeRank indexOfObject:type2];

	if ((rank1 == NSNotFound) || (rank2 == NSNotFound))
		return NSOrderedSame;
	else if (rank1 < rank2)
		return NSOrderedAscending;
	else if (rank1 > rank2)
		return NSOrderedDescending;

	// TODO: sort further somehow?

	return NSOrderedSame;
}

- (NSArray *)secondSuggestions
{
	// Get all statuses, including type (available, away, etc.), title and ID
	NSString *script =
		@"tell application \"Adium\"\n"
		"  set statusList to {}\n"
		"  repeat with stat in every status\n"
		"    copy {type of stat as text, title of stat, id of stat} to end of statusList\n"
		"  end repeat\n"
		"  get statusList\n"
		"end tell";

	NSArray *list = [self executeAppleScriptReturningListOfListOfStrings:script];
	if (!list)		// failure
		return [NSArray array];

	NSMutableArray *arr = [NSMutableArray arrayWithCapacity:[list count]];
	NSEnumerator *en = [list objectEnumerator];
	NSArray *status;
	while ((status = [en nextObject])) {
		// status is something like ["away", "Lunch", "27"]
		// TODO: do a nicer description? Use colours?
		NSString *type = [status objectAtIndex:0], *title = [status objectAtIndex:1];
		NSString *desc = [NSString stringWithFormat:@"%@ (%@)", title, type];
		NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
			desc, @"description", status, @"parameter", nil];
		[arr addObject:dict];
	}

	[arr sortUsingFunction:compareStatus context:nil];

	// Add separator markers between status types
	int i;
	for (i = 0; i < ([arr count] - 1); ++i) {
		NSDictionary *curr = [arr objectAtIndex:i], *next = [arr objectAtIndex:i + 1];
		NSString *currStatus = [[curr valueForKey:@"parameter"] objectAtIndex:0];
		if ([[[next valueForKey:@"parameter"] objectAtIndex:0] isEqualToString:currStatus])
			continue;	// both have the same status
		[arr insertObject:[NSDictionary dictionary] atIndex:i + 1];
		++i;
	}

	return arr;	
}

@end
