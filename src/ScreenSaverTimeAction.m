//
//  ScreenSaverTimeAction.m
//  MarcoPolo
//
//  Created by David Symonds on 7/16/07.
//

#import <CoreFoundation/CFPreferences.h>
#import "ScreenSaverTimeAction.h"


@implementation ScreenSaverTimeAction

- (NSString *)descriptionOf:(NSDictionary *)actionDict
{
	int t = [[actionDict valueForKey:@"parameter"] intValue];

	if (t == 0)
		return NSLocalizedString(@"Disabling screen saver.", @"");
	else if (t == 1)
		return NSLocalizedString(@"Setting screen saver idle time to 1 minute.", @"");
	else
		return [NSString stringWithFormat:NSLocalizedString(@"Setting screen saver idle time to %d minutes.", @""), t];
}

- (BOOL)execute:(NSDictionary *)actionDict error:(NSString **)errorString
{
	NSNumber *n = [NSNumber numberWithInt:[[actionDict valueForKey:@"parameter"] intValue] * 60];	// minutes -> seconds

	CFPreferencesSetValue(CFSTR("idleTime"), (CFPropertyListRef) n,
			      CFSTR("com.apple.screensaver"),
			      kCFPreferencesCurrentUser, kCFPreferencesCurrentHost);
	BOOL success = CFPreferencesSynchronize(CFSTR("com.apple.screensaver"),
				 kCFPreferencesCurrentUser, kCFPreferencesCurrentHost);

	// Notify login process
	if (success) {
		CFMessagePortRef port = CFMessagePortCreateRemote(NULL, CFSTR("com.apple.loginwindow.notify"));
		success = (CFMessagePortSendRequest(port, 500, 0, 0, 0, 0, 0) == kCFMessagePortSuccess);
		CFRelease(port);
	}

	if (!success) {
		*errorString = NSLocalizedString(@"Failed setting screen saver idle time!", @"");
		return NO;
	}

	return YES;
}

- (NSString *)suggestionLeadText
{
	return NSLocalizedString(@"Set screen saver idle time to", @"");
}

- (NSArray *)suggestions
{
	int opts[] = { 3, 5, 15, 30, 60, 120, 0 };
	int num_opts = sizeof(opts) / sizeof(opts[0]);
	NSMutableArray *arr = [NSMutableArray arrayWithCapacity:num_opts];

	int i;
	for (i = 0; i < num_opts; ++i) {
		NSNumber *option = [NSNumber numberWithInt:opts[i]];
		NSString *description;

		if (opts[i] == 0)
			description = NSLocalizedString(@"never", @"Screen saver idle time");
		else if (opts[i] == 1)
			description = NSLocalizedString(@"1 minute", @"Screen saver idle time");
		else
			description = [NSString stringWithFormat:NSLocalizedString(@"%d minutes", @"Screen saver idle time"), opts[i]];

		[arr addObject:[NSDictionary dictionaryWithObjectsAndKeys:
			option, @"parameter",
			description, @"description", nil]];
	}

	return arr;
}

@end
