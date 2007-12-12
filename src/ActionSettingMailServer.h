//
//  ActionSettingMailServer.h
//  MarcoPolo
//
//  Created by David Symonds on 11/12/07.
//

#import <Cocoa/Cocoa.h>
#import "Action.h"
#import "FlexControls.h"


#define kAllMailAccounts	@"*"

@interface ActionSettingMailServer : Action {
	IBOutlet FlexTextField *leadTextField;
	IBOutlet NSArrayController *accountController, *serverController;
}

- (id)init;

// Need to be implemented by descendant classes
- (NSString *)leadText;
- (NSArray *)accountOptions;	// optional; will default to all Mail's accounts
- (NSArray *)serverOptions;

@end
