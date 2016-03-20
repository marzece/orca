//
//  PeddlerController.m
//  Orca
//
//  Created by Eric Marzec on 3/16/16.
//
//

#import "PeddlerController.h"

@interface PeddlerController ()

@end

@implementation PeddlerController

- (id) init {
    
    self = [super initWithWindowNibName:@"Peddler"];
    return self;
}
- (void) awakeFromNib {
    NSArray *arr = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORMTCModel")];
    mtc = arr[0];
}
- (void)windowDidLoad {
    [super windowDidLoad];
}
-(IBAction)FirePeds:(id)sender{
    [mtc fireMTCPedestalsFixedRate];
}

@end
