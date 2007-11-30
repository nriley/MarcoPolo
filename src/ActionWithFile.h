//
//  ActionWithFile.h
//  MarcoPolo
//
//  Created by David Symonds on 30/11/07.
//

#import <Cocoa/Cocoa.h>
#import "Action.h"


@interface ActionWithFile : Action {
//	IBOutlet NSTextField *leadTextField;
}

- (void)runPanelAsSheetOfWindow:(NSWindow *)window withParameter:(NSDictionary *)parameter
		 callbackObject:(NSObject *)callbackObject selector:(SEL)selector;

// Need to be implemented by descendant classes
//- (NSString *)leadText;
- (NSString *)descriptionOf:(NSDictionary *)actionDict;
- (BOOL)execute:(NSDictionary *)actionDict error:(NSString **)errorString;

@end
