//
//  IChatAction.m
//  MarcoPolo
//
//  Created by David Symonds on 8/06/07.
//

#import "IChatAction.h"


@implementation IChatAction

- (NSString *)leadText
{
	return NSLocalizedString(@"Set iChat status message:", @"");
}

- (NSString *)descriptionOf:(NSDictionary *)actionDict
{
	return [NSString stringWithFormat:NSLocalizedString(@"Setting iChat status to '%@'.", @""),
		[actionDict valueForKey:@"parameter"]];
}

- (BOOL)execute:(NSDictionary *)actionDict error:(NSString **)errorString
{
	// TODO: properly escape status message!
	NSString *script = [NSString stringWithFormat:
		@"tell application \"iChat\"\n"
		"  set status message to \"%@\"\n"
		"end tell\n", [actionDict valueForKey:@"parameter"]];

	if (![self executeAppleScript:script]) {
		*errorString = NSLocalizedString(@"Couldn't set iChat status!", @"In IChatAction");
		return NO;
	}

	return YES;
}

@end
