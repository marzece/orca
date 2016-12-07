//
//  RunStatusIcon.h
//  Orca
//
//  Created by Eric Marzec on 12/6/16.
//
//

#import <Foundation/Foundation.h>

@interface RunStatusIcon : NSObject {
    // Doggy
    NSStatusItem *statusIcon;
    NSTimer* animate_timer;
    int current_dog_frame;
    int n_frames;
    BOOL isRunning;
    
}
- (void) start_animation;
- (void) stop_animation;
- (void) animate_icon;

@end
