//
//  ToggleWiFiAction.m
//  MarcoPolo
//
//  Created by David Symonds on 2/05/07.
//

#import "Apple80211.h"
#import "ToggleWiFiAction.h"


@implementation ToggleWiFiAction

- (NSString *)suggestionLeadText
{
	return NSLocalizedString(@"Set WiFi power:", @"");
}

- (NSString *)descriptionOfTransitionToState:(BOOL)state
{
	if (state)
		return NSLocalizedString(@"Turning WiFi on.", @"");
	else
		return NSLocalizedString(@"Turning WiFi off.", @"");
}

- (BOOL)executeTransition:(BOOL)state error:(NSString **)errorString
{
	WirelessContextPtr wctxt;

	if (!WirelessIsAvailable())
		goto failure;
	if (WirelessAttach(&wctxt, 0) != noErr)
		goto failure;
	if (WirelessSetPower(wctxt, state ? 1 : 0) != noErr) {
		WirelessDetach(wctxt);
		goto failure;
	}
	WirelessDetach(wctxt);

	// Success
	return YES;

failure:
	if (state)
		*errorString = NSLocalizedString(@"Failed turning WiFi on.", @"");
	else
		*errorString = NSLocalizedString(@"Failed turning WiFi off.", @"");
	return NO;
}

@end
