//
//  ScreenSaverPasswordAction.m
//  MarcoPolo
//
//  Created by David Symonds on 7/06/07.
//

#import <CoreFoundation/CFPreferences.h>
#import "Common.h"
#import "ScreenSaverPasswordAction.h"


@implementation ScreenSaverPasswordAction

- (NSString *)descriptionOfState:(BOOL)state
{
	if (state)
		return NSLocalizedString(@"Enable screen saver password", @"Future tense");
	else
		return NSLocalizedString(@"Disable screen saver password", @"Future tense");
}

- (NSString *)descriptionOfTransitionToState:(BOOL)state
{
	if (state)
		return NSLocalizedString(@"Enabling screen saver password.", @"Present continuous tense");
	else
		return NSLocalizedString(@"Disabling screen saver password.", @"Present continuous tense");
}

- (BOOL)executeTransition:(BOOL)state error:(NSString **)errorString
{
	BOOL success;

	if (!isLeopardOrLater()) {
		// Mac OS X 10.4 (Tiger) and earlier
		NSNumber *val = [NSNumber numberWithBool:state];
		CFPreferencesSetValue(CFSTR("askForPassword"), (CFPropertyListRef) val,
				      CFSTR("com.apple.screensaver"),
				      kCFPreferencesCurrentUser, kCFPreferencesCurrentHost);
		success = CFPreferencesSynchronize(CFSTR("com.apple.screensaver"),
					 kCFPreferencesCurrentUser, kCFPreferencesCurrentHost);

		// Notify login process
		if (success) {
			CFMessagePortRef port = CFMessagePortCreateRemote(NULL, CFSTR("com.apple.loginwindow.notify"));
			success = (CFMessagePortSendRequest(port, 500, 0, 0, 0, 0, 0) == kCFMessagePortSuccess);
			CFRelease(port);
		}
	} else {
		// Mac OS X 10.5 (Leopard) and later
		NSString *script = [NSString stringWithFormat:
			@"tell application \"System Events\"\n"
			"  tell security preferences\n"
			"    set require password to wake to %@\n"
			"  end tell\n"
			"end tell\n", (state ? @"true" : @"false")];
		success = [self executeAppleScript:script];
	}

	if (!success) {
		*errorString = NSLocalizedString(@"Failed toggling screen saver password!", @"");
		return NO;
	}
	return YES;
}

@end
