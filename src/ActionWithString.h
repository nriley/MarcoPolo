//
//  ActionWithString.h
//  MarcoPolo
//
//  Created by David Symonds on 30/11/07.
//

#import <Cocoa/Cocoa.h>
#import "Action.h"
#import "FlexControls.h"


@interface ActionWithString : Action {
	IBOutlet FlexTextField *leadTextField;
	IBOutlet NSTextField *parameterTextField;
}

- (id)init;

// Need to be implemented by descendant classes
- (NSString *)leadText;
- (NSString *)descriptionOf:(NSDictionary *)actionDict;
- (BOOL)execute:(NSDictionary *)actionDict error:(NSString **)errorString;

@end
