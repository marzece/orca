//
//  TUBiiTest.m
//  Orca
//
//  Created by Eric Marzec on 2/24/16.
//
//

#import <XCTest/XCTest.h>
#import "TUBiiModel.h"

@interface TUBiiTest : XCTestCase {
    TUBiiModel* tubii;
    float epsilon;
}

@end

@implementation TUBiiTest

- (void)setUp {
    tubii = [[TUBiiModel alloc] init];
    epsilon = 0.000001;
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testConvertBitsToValue {
    float val = [tubii ConvertBitsToValue:0 NBits:12 MinVal:0 MaxVal:100];
    XCTAssertEqualWithAccuracy(val,0.0,epsilon,@"Min value not correctly returned");
    val = [tubii ConvertBitsToValue:0xFFF NBits:12 MinVal:0 MaxVal:100];
    XCTAssertEqualWithAccuracy(val,100.0,epsilon,@"Max value not correctly returned");
    val = [tubii ConvertBitsToValue:127 NBits:8 MinVal:-5.0 MaxVal:5.0];
    val += [tubii ConvertBitsToValue:128 NBits:8 MinVal:-5.0 MaxVal:5.0];
    XCTAssertEqualWithAccuracy(val, 0, epsilon, @"Negative value handled incorrectly");
    val = [tubii ConvertBitsToValue:0 NBits:1 MinVal:3.0 MaxVal:5.0];
    XCTAssertEqualWithAccuracy(val, 3, epsilon, @"Single bit convert failed");
    val = [tubii ConvertBitsToValue:1 NBits:1 MinVal:3.0 MaxVal:5.0];
    XCTAssertEqualWithAccuracy(val, 5, epsilon, @"Single bit convert failed");
}
- (void)testConvertValueToBits {
    NSUInteger bits = [tubii ConvertValueToBits:0 NBits:8 MinVal:0.0 MaxVal:5.0];
    XCTAssertEqual(bits, (UInt)0x0, @"Failed to convert min value");
    bits = [tubii ConvertValueToBits:5.0 NBits:8 MinVal:0.0 MaxVal:5.0];
    XCTAssertEqual(bits, (UInt)0XFF, @"Failed to convert max value");
    bits = [tubii ConvertValueToBits:-5.0 NBits:12 MinVal:-5.0 MaxVal:11.32];
    XCTAssertEqual(bits, (UInt)0, @"Failed to properly handle negative value");
    bits = [tubii ConvertValueToBits:0.0 NBits:8 MinVal:0.0 MaxVal:10.0];
    NSUInteger bits2 = [tubii ConvertValueToBits:epsilon NBits:8 MinVal:0.0 MaxVal:10.0];
    XCTAssertEqual(bits, bits2, @"Bits incremented despite small change in value");
    
}

@end
