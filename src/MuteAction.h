//
//  MuteAction.h
//  MarcoPolo
//
//  Created by David Symonds on 7/06/07.
//

#import <Cocoa/Cocoa.h>
#import "Action.h"


@interface MuteAction : Action {
}

- (NSString *)description;
- (BOOL)execute:(NSString **)errorString;

@end