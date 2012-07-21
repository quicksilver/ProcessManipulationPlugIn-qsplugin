//
//  QSProcessManipulationPlugInAction.h
//  QSProcessManipulationPlugIn
//
//  Created by Nicholas Jitkoff on 9/23/05.
//  Copyright __MyCompanyName__ 2005. All rights reserved.
//

//#import <QSCore/QSObject_Numeric.h>
#import "QSProcessManipulationPlugInAction.h"
#define QSProcessManipulationPlugInType @"QSProcessManipulationPlugIn_Type"

@interface QSObject (Numeric) {
    
}
+(QSObject *)numericObjectWithName:(NSString *)name intValue:(int)value;
@end
  
@interface QSAdvancedProcessActionProvider : QSActionProvider{
}
- (int)pidOfProcess:(QSObject *)dObject;
- (BOOL)setPriority:(int)priority ofPID:(int)pid;
- (void)setPriority:(int)priority ofProcess:(QSObject *)dObject;
- (void)sendSignal:(int)signal toProcess:(QSObject *)dObject;
@end
