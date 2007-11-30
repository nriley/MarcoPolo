//
//  ActionWithBool.h
//  MarcoPolo
//
//  Created by David Symonds on 7/06/07.
//

#import <Cocoa/Cocoa.h>
#import "Action.h"


@interface ActionWithBool : Action {
	IBOutlet NSButtonCell *radio1, *radio2;
}

- (id)init;

- (NSString *)descriptionOf:(NSDictionary *)actionDict;
- (BOOL)execute:(NSDictionary *)actionDict error:(NSString **)errorString;

// To be implemented by descendant classes
- (NSString *)descriptionOfState:(BOOL)state;	// defaults to "on"/"off"
- (NSString *)descriptionOfTransitionToState:(BOOL)state;
- (BOOL)executeTransition:(BOOL)state error:(NSString **)errorString;

@end
