//
//  ToggleBluetoothAction.h
//  MarcoPolo
//
//  Created by David Symonds on 3/04/07.
//

#import <Cocoa/Cocoa.h>
#import "ToggleableAction.h"


@interface ToggleBluetoothAction : ToggleableAction {
	int destState_;
}

- (NSString *)suggestionLeadText;
- (NSString *)descriptionOfState:(BOOL)state;
- (NSString *)descriptionOfTransitionToState:(BOOL)state;
- (BOOL)executeTransition:(BOOL)state error:(NSString **)errorString;

@end
