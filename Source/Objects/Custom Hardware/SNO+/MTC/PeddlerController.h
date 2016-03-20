//
//  PeddlerController.h
//  Orca
//
//  Created by Eric Marzec on 3/16/16.
//
//

#import "OrcaObjectController.h"
#import "ORMTCModel.h"

@interface PeddlerController : OrcaObjectController {
    ORMTCModel *mtc;
}
-(IBAction)FirePeds:(id)sender;
@end
