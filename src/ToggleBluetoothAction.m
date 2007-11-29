//
//  ToggleBluetoothAction.m
//  MarcoPolo
//
//  Created by David Symonds on 1/05/07.
//

#import "ToggleBluetoothAction.h"


@implementation ToggleBluetoothAction

- (NSString *)suggestionLeadText
{
	return NSLocalizedString(@"Set Bluetooth state:", @"");
}

- (NSString *)descriptionOfState:(BOOL)state
{
	if (state)
		return NSLocalizedString(@"Turn Bluetooth on", @"Future tense");
	else
		return NSLocalizedString(@"Turn Bluetooth off", @"Future tense");
}

- (NSString *)descriptionOfTransitionToState:(BOOL)state
{
	if (state)
		return NSLocalizedString(@"Turning Bluetooth on.", @"Present continuous tense");
	else
		return NSLocalizedString(@"Turning Bluetooth off.", @"Present continuous tense");
}

// IOBluetooth.framework is not thread-safe, so all IOBluetooth calls need to be done in the main thread.
- (void)setPowerState
{
	IOBluetoothPreferenceSetControllerPowerState(destState_ ? 1 : 0);
	destState_ = IOBluetoothPreferenceGetControllerPowerState();
}

- (BOOL)executeTransition:(BOOL)state error:(NSString **)errorString
{
	int aim = (state ? 1 : 0);
	destState_ = aim;

	[self performSelectorOnMainThread:@selector(setPowerState) withObject:nil waitUntilDone:YES];
	if (aim != destState_) {
		if (state)
			*errorString = NSLocalizedString(@"Failed turning Bluetooth on.", @"");
		else
			*errorString = NSLocalizedString(@"Failed turning Bluetooth off.", @"");
		return NO;
	}

	return YES;
}

@end
